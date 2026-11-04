# Deploys a package published by container-release.yml to a Windows Server + IIS host (no containers).
#
# Called by .github/workflows/deploy-iis.yml on the self-hosted runner of the target server.
# Runs on Windows PowerShell 5.1: keep it ASCII only and free of PowerShell 7 syntax.
#
# Strategy: immutable release folders plus a junction. <DestPath> is the junction that IIS (or the
# service) points at; <DestPath>_releases\ holds one folder per deploy (<version>_<UTC stamp>);
# <DestPath>_data\ holds what survives releases (PersistDirs) and is linked into each one.
# A deploy builds the new release beside the live one, swaps the junction, starts the app and
# smoke-tests it; any failure after that points the junction back at the previous release.
# Server-owned config never travels in the package: ServerFiles are copied from the live release.
# Rolling back by hand = deploying an older version again. Pool settings are never changed.
#
# First deploy: an existing junction is accepted (its target becomes the previous release). A real
# folder is renamed to <DestPath>_releases\legacy_<stamp>, which becomes the rollback target and is
# never pruned; kind api and spa need -SiteName to stop the site and free the folder.

[CmdletBinding()]
param(
  [string]$Kind,                  # api | spa | service
  [string]$Source,                # folder with the extracted package
  [string]$DestPath,              # path IIS or the service uses; becomes a junction
  [string]$Version,
  [string]$SiteName,              # only for the first deploy over a real folder
  [string]$AppPool,               # api
  [string]$ServiceName,           # service
  [string]$HealthUrl,             # full URL that must answer 2xx (scheme, host and port as the site is bound)
  [string]$HealthAddress,         # optional IP to connect to; the host of HealthUrl is still sent as Host and TLS name
  [switch]$HealthSkipCert,        # accept any certificate for the checks (an internal CA, a mismatching name)
  [string]$VersionUrl,            # path or URL whose body must contain "<Version>"; empty = skipped
  [string]$ServerFiles = 'appsettings*.json',
  [string]$PersistDirs,           # empty = Logs for api and service, none for spa
  [int]$KeepReleases = 5,
  [int]$HealthTimeoutSec = 120,   # per smoke check (health, then version)
  [string]$RunUrl = '',
  [string]$Digest = '',
  [string]$AppCmd = (Join-Path $env:windir 'System32\inetsrv\appcmd.exe')
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) { Write-Host "[deploy] $Message" }

function Split-List([string]$Text) {
  $items = @($Text -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  foreach ($i in $items) { if ($i -match '[\\/:]' -or $i -eq '..') { throw "Invalid name '$i': plain file or folder names only." } }
  return $items
}

# ---- junctions ------------------------------------------------------------------------------
function Test-IsJunction([string]$Path) {
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  return [bool]($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))
}

function Get-LinkTarget([string]$Path) {
  if (-not (Test-IsJunction $Path)) { return $null }
  $target = @((Get-Item -LiteralPath $Path -Force).Target)[0]
  if (-not $target) { return $null }
  return ([IO.Path]::GetFullPath($target)).TrimEnd('\')
}

function New-Junction([string]$Link, [string]$Target) {
  & cmd.exe /c mklink /J "$Link" "$Target" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "mklink failed: $Link -> $Target (exit $LASTEXITCODE)" }
}

function Remove-Junction([string]$Link) {
  # rmdir on a junction removes only the link, never the content of its target.
  if (-not (Test-IsJunction $Link)) { throw "Refusing to unlink '$Link': it is not a junction." }
  & cmd.exe /c rmdir "$Link"
  if ($LASTEXITCODE -ne 0) { throw "Could not unlink $Link (exit $LASTEXITCODE)" }
}

# ---- releases -------------------------------------------------------------------------------
function Copy-Package([string]$From, [string]$To, [string[]]$SkipFiles, [string[]]$SkipDirs) {
  # robocopy rejects wildcards in full paths, so the root-level matches are listed one by one.
  # Only the root is excluded: a file with the same name in a subfolder belongs to the package.
  $files = @($SkipFiles | ForEach-Object { Get-ChildItem -LiteralPath $From -Filter $_ -File -Force } | ForEach-Object { $_.FullName })
  $dirs = @($SkipDirs | ForEach-Object { Join-Path $From $_ })
  $a = @($From, $To, '/E', '/R:2', '/W:2', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
  if ($files) { $a += '/XF'; $a += $files }
  if ($dirs) { $a += '/XD'; $a += $dirs }
  & robocopy.exe @a | Out-Host
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed (exit $LASTEXITCODE)" }
  $global:LASTEXITCODE = 0
}

function Remove-Release([string]$Path) {
  # A release can be a junction itself (made by hand), and PersistDirs are junctions inside it. Unlink
  # every junction without walking into it: the recursive delete below (in Windows PowerShell 5.1 it
  # can follow a junction) must never reach the data a junction points at.
  if (Test-IsJunction $Path) { Remove-Junction $Path; return }
  $pending = New-Object Collections.Generic.Queue[string]
  $pending.Enqueue($Path)
  while ($pending.Count) {
    foreach ($d in @(Get-ChildItem -LiteralPath $pending.Dequeue() -Directory -Force)) {
      if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-Junction $d.FullName } else { $pending.Enqueue($d.FullName) }
    }
  }
  Remove-Item -LiteralPath $Path -Recurse -Force
}

function Select-ReleasesToPrune([string[]]$Names, [string[]]$Protected, [int]$Keep) {
  # Only folders named <version>_<14 digits> are ours; anything else is never touched, including
  # legacy_<stamp>, the only copy of a folder as it was before the first deploy (removed by hand).
  # The newest $Keep and the protected ones (live and previous) stay.
  $ours = @($Names | Where-Object { $_ -match '^[0-9]+\.[0-9]+\.[0-9]+(-(dev|rc)\.[0-9A-Za-z.]+)?_\d{14}\z' } | Sort-Object { $_.Substring($_.Length - 14) } -Descending)
  $stay = @($Protected) + @($ours | Select-Object -First $Keep)
  return @($ours | Where-Object { $stay -notcontains $_ })
}

function Test-ApiPackage([string]$Dir) {
  $config = Join-Path $Dir 'web.config'
  if (-not (Test-Path -LiteralPath $config)) { throw 'The package has no web.config.' }
  $xml = New-Object Xml.XmlDocument; $xml.Load($config)
  $node = $xml.SelectSingleNode('//aspNetCore')
  if (-not $node) { throw 'web.config has no aspNetCore handler.' }
  # dotnet + ".\App.dll" (framework-dependent) or ".\App.exe" (self-contained).
  $entry = if ($node.processPath -match '^dotnet(\.exe)?$') { @($node.arguments -split '\s+')[0] } else { $node.processPath }
  if (-not $entry -or -not (Test-Path -LiteralPath (Join-Path $Dir $entry))) {
    throw "web.config starts '$entry', which is not in the package."
  }
}

function Add-DeployLog([string]$Root, [string]$Release, [string]$Result) {
  $time = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
  Add-Content -LiteralPath (Join-Path $Root 'deployments.log') -Encoding Ascii `
    -Value (($time, $Version, $Release, $Result, $Digest, $RunUrl) -join "`t")
}

# ---- app offline page, IIS, services ----------------------------------------------------------
function Set-AppOffline([string]$Dir) {
  Set-Content -LiteralPath (Join-Path $Dir 'app_offline.htm') -Encoding Ascii -Value '<html><body><h1>Actualizando el sistema</h1><p>Volvemos en unos minutos.</p></body></html>'
}

function Clear-AppOffline([string]$Dir) { $f = Join-Path $Dir 'app_offline.htm'; if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }

function Invoke-AppCmd([string[]]$ArgList) {
  if (-not (Test-Path -LiteralPath $AppCmd)) { throw "appcmd.exe not found at '$AppCmd': is IIS installed?" }
  # Windows PowerShell 5.1 turns native stderr into a terminating error under 'Stop'.
  $saved = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { $out = & $AppCmd @ArgList 2>&1; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $saved }
  if ($code -ne 0) { throw "appcmd $($ArgList -join ' ') failed (exit $code): $out" }
  return $out
}

function Get-IisState([string]$Type, [string]$Name) { return "$(@(Invoke-AppCmd @('list', $Type, $Name, '/text:state'))[0])".Trim() }

function Set-IisState([string]$Type, [string]$Name, [string]$Action) {
  $want = if ($Action -eq 'start') { 'Started' } else { 'Stopped' }
  if ((Get-IisState $Type $Name) -ne $want) { Invoke-AppCmd @($Action, $Type, "/$Type.name:$Name") | Out-Null }
  for ($i = 0; $i -lt 30; $i++) {
    if ((Get-IisState $Type $Name) -eq $want) { return }
    Start-Sleep -Seconds 1
  }
  throw "$Type '$Name' is not $want after 30 s."
}

function Set-ServiceState([string]$Name, [string]$Action) {
  $svc = Get-Service -Name $Name -ErrorAction Stop
  $want = if ($Action -eq 'start') { 'Running' } else { 'Stopped' }
  if ($svc.Status -ne $want) { if ($Action -eq 'start') { Start-Service -Name $Name } else { Stop-Service -Name $Name } }
  $svc.WaitForStatus($want, [TimeSpan]::FromSeconds(60))
}

function Invoke-BestEffort([scriptblock]$Do) {
  try { & $Do } catch { $script:RollbackOk = $false; Write-Step "rollback step failed: $($_.Exception.Message)" }
}

# ---- smoke test -------------------------------------------------------------------------------
function Resolve-VersionUrl([string]$Url, [string]$Health) {
  if (-not $Url) { return '' }
  if ($Url -match '^https?://') { return $Url }
  if (-not $Health) { throw 'A relative VersionUrl needs HealthUrl to take the host from.' }
  return ([Uri]$Health).GetLeftPart([UriPartial]::Authority) + '/' + $Url.TrimStart('/')
}

# One GET over a raw socket: Invoke-WebRequest cannot connect to one address while presenting another
# host name (IP and host-header bindings, SNI) and follows redirects by itself. Connects to $Address (or
# the URL host), sends the URL host as Host and TLS name, no proxy, no redirects. HTTP/1.0: no chunking.
function Invoke-Probe([string]$Url, [string]$Address) {
  $uri = [Uri]$Url
  $tcp = New-Object Net.Sockets.TcpClient
  try {
    $tcp.ReceiveTimeout = 20000
    $tcp.SendTimeout = 20000
    $connecting = $tcp.BeginConnect($(if ($Address) { $Address } else { $uri.Host }), $uri.Port, $null, $null)
    if (-not $connecting.AsyncWaitHandle.WaitOne(10000)) { throw 'connect timed out' }
    $tcp.EndConnect($connecting)
    $stream = $tcp.GetStream()
    if ($uri.Scheme -eq 'https') {
      $accept = if ($HealthSkipCert) { [Net.Security.RemoteCertificateValidationCallback]{ $true } } else { $null }
      $tls = New-Object Net.Security.SslStream($stream, $false, $accept)
      # TLS 1.2 pinned (the most Server 2019 offers, so a .NET default cannot leave an older one); no CRL lookup.
      $tls.AuthenticateAsClient($uri.Host, $null, [Security.Authentication.SslProtocols]::Tls12, $false)
      $stream = $tls
    }
    $request = [Text.Encoding]::ASCII.GetBytes("GET $($uri.PathAndQuery) HTTP/1.0`r`nHost: $($uri.Authority)`r`nUser-Agent: deploy-iis`r`nAccept: */*`r`nConnection: close`r`n`r`n")
    $stream.Write($request, 0, $request.Length)
    $text = (New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)).ReadToEnd()
  } finally { $tcp.Close() }
  $head, $body = $text -split "`r`n`r`n", 2
  $line = [regex]::Match($head, '^HTTP/\S+ (\d{3})')
  if (-not $line.Success) { throw "not an HTTP response: '$($text.Substring(0, [Math]::Min(60, $text.Length)))'" }
  $location = [regex]::Match($head, '(?im)^Location:[ \t]*(.+?)[ \t\r]*$').Groups[1].Value
  return [pscustomobject]@{ Status = [int]$line.Groups[1].Value; Location = $location; Body = "$body" }
}

function Test-Url([string]$Url, [string]$Pattern, [int]$TimeoutSec) {
  # The connect address only applies to the host of HealthUrl, not to an absolute VersionUrl elsewhere.
  $address = if ($HealthAddress -and ([Uri]$Url).Host -eq ([Uri]$HealthUrl).Host) { $HealthAddress } else { '' }
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  $last = ''
  do {
    try {
      $r = Invoke-Probe $Url $address
      if ($r.Status -ge 200 -and $r.Status -lt 300) {
        if (-not $Pattern -or $r.Body -match $Pattern) { return $true }
        $last = "HTTP $($r.Status) without a match for $Pattern"
      } elseif ($r.Status -ge 300 -and $r.Status -lt 400) {
        $last = "HTTP $($r.Status) redirect to '$($r.Location)': use the final URL"  # not followed on purpose
      } else { $last = "HTTP $($r.Status)" }
    } catch { $last = $_.Exception.Message }
    Start-Sleep -Seconds 5
  } while ((Get-Date) -lt $deadline)
  Write-Step "$Url did not pass: $last"
  return $false
}

# ---- deploy -----------------------------------------------------------------------------------
function Invoke-Deploy {
  # 1. Validate everything before touching the server.
  if ($Kind -cnotin 'api', 'spa', 'service') { throw "Kind must be api, spa or service (got '$Kind')." }
  if ($Version -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+(-(dev|rc)\.[0-9A-Za-z.]+)?\z') { throw "'$Version' is not a deployable version." }
  if (-not $DestPath -or -not [IO.Path]::IsPathRooted($DestPath)) { throw 'DestPath must be an absolute path.' }
  $dest = $DestPath.TrimEnd('\', '/')
  $parent = Split-Path -Parent $dest
  if (-not $parent -or -not (Test-Path -LiteralPath $parent)) { throw "The parent folder of '$dest' does not exist." }
  $Source = "$Source".TrimEnd('\', '/')  # robocopy mangles a quoted path that ends in a backslash
  if (-not (Test-Path -LiteralPath $Source) -or -not (Get-ChildItem -LiteralPath $Source -Force | Select-Object -First 1)) {
    throw "The package folder is missing or empty: $Source"
  }
  $skipFiles = @(Split-List $ServerFiles)
  # A Logs junction in the web root of a spa would shadow a client route /logs, so spa has none by default.
  $dirs = @(Split-List $(if ($PersistDirs) { $PersistDirs } elseif ($Kind -eq 'spa') { '' } else { 'Logs' }))
  switch ($Kind) {
    'api' {
      if (-not $AppPool -or -not $HealthUrl) { throw 'kind api needs AppPool and HealthUrl.' }
      Test-ApiPackage $Source
    }
    'spa' {
      if (-not $HealthUrl) { throw 'kind spa needs HealthUrl.' }
      if (-not (Test-Path -LiteralPath (Join-Path $Source 'index.html'))) { throw 'The package has no index.html.' }
      if (-not (Test-Path -LiteralPath (Join-Path $Source 'web.config'))) { Write-Step 'WARN the package has no web.config.' }
    }
    'service' { if (-not $ServiceName) { throw 'kind service needs ServiceName.' } }
  }
  # A mistyped variable must fail here, before the pool is stopped. IPv4 only: the probe socket is IPv4.
  $health = $null; $ip = $null
  if ($HealthUrl -and (-not [Uri]::TryCreate($HealthUrl, [UriKind]::Absolute, [ref]$health) -or $health.Scheme -notin 'http', 'https' -or $health.HostNameType -eq 'IPv6')) {
    throw "HealthUrl must be an absolute http or https URL with a name or an IPv4 address: '$HealthUrl'."
  }
  if ($HealthAddress -and (-not $HealthUrl -or -not [Net.IPAddress]::TryParse($HealthAddress, [ref]$ip) -or $ip.AddressFamily -ne 'InterNetwork')) {
    throw "HealthAddress must be an IPv4 address and needs HealthUrl: '$HealthAddress'."
  }
  $versionCheck = Resolve-VersionUrl $VersionUrl $HealthUrl
  if (-not $versionCheck) { Write-Step 'WARN no VersionUrl: the deployed version will not be verified.' }

  $releasesRoot = "${dest}_releases"
  $dataRoot = "${dest}_data"
  $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
  $release = Join-Path $releasesRoot "${Version}_$stamp"
  $live = if (Test-IsJunction $dest) { Get-LinkTarget $dest } else { $null }
  $migrating = (-not (Test-IsJunction $dest)) -and (Test-Path -LiteralPath $dest)
  if ($migrating -and $Kind -ne 'service' -and -not $SiteName) {
    throw "'$dest' is a real folder: the first deploy needs SiteName to stop the site and turn the folder into a junction."
  }
  if ($migrating -and $Kind -ne 'service') {  # a mistyped DestPath must not rename a folder the site does not serve
    $served = [Environment]::ExpandEnvironmentVariables("$(@(Invoke-AppCmd @('list', 'vdir', "$SiteName/", '/text:physicalPath'))[0])".Trim()).TrimEnd('\')
    if ($served -ne $dest) { throw "The root of site '$SiteName' is '$served', not '$dest': refusing to rename a folder the site does not serve." }
  }

  # 2. Build the release beside the live one. A failure here leaves the live release untouched.
  Write-Step "Building $release"
  try {
    New-Item -ItemType Directory -Force -Path $releasesRoot | Out-Null
    Copy-Package $Source $release $skipFiles $dirs
    $from = if ($live) { $live } elseif ($migrating) { $dest } else { $null }
    if ($from) {
      foreach ($p in $skipFiles) { Get-ChildItem -LiteralPath $from -Filter $p -File -Force | Copy-Item -Destination $release -Force }
    } else {
      Write-Step 'WARN no live release: the server-owned files must be placed by hand.'
    }
    foreach ($d in $dirs) {
      New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot $d) | Out-Null
      New-Junction (Join-Path $release $d) (Join-Path $dataRoot $d)
    }
  } catch {
    if (Test-Path -LiteralPath $release) { Remove-Release $release }
    throw
  }

  # 3. Stop, swap, start, smoke test. Any failure from here on rolls back.
  $previous = $live
  $legacy = $null
  $siteStopped = $false

  function Undo-Deploy {
    Write-Step 'Rolling back'
    $script:RollbackOk = $true
    if ($Kind -eq 'api') { Invoke-BestEffort { Set-IisState 'apppool' $AppPool 'stop' } }
    if ($Kind -eq 'service') { Invoke-BestEffort { Set-ServiceState $ServiceName 'stop' } }
    Invoke-BestEffort {
      if (Test-IsJunction $dest) {
        if ($previous -and (Get-LinkTarget $dest) -ne $previous) {
          Remove-Junction $dest
          New-Junction $dest $previous
          Write-Step "Junction back at $previous"
        }
      } elseif (-not (Test-Path -LiteralPath $dest)) {  # unlinked or renamed, and the new link never came up
        if ($legacy -and (Test-Path -LiteralPath $legacy)) { Move-Item -LiteralPath $legacy -Destination $dest; Write-Step 'Original folder restored' }
        elseif ($previous) { New-Junction $dest $previous; Write-Step "Junction back at $previous" }
      }
    }
    Invoke-BestEffort { Clear-AppOffline $dest }
    if ($siteStopped) { Invoke-BestEffort { Set-IisState 'site' $SiteName 'start' } }
    if ($Kind -eq 'api') { Invoke-BestEffort { Set-IisState 'apppool' $AppPool 'start' } }
    if ($Kind -eq 'service') { Invoke-BestEffort { Set-ServiceState $ServiceName 'start' } }
    if ($HealthUrl) {
      $healthy = Test-Url $HealthUrl '' 60
      if (-not $healthy) { $script:RollbackOk = $false }
      Write-Step "After the rollback the health check is $(if ($healthy) { 'OK' } else { 'FAILING' })"
    }
  }

  try {
    if ($Kind -eq 'api') {
      Set-IisState 'apppool' $AppPool 'stop'
      if (Test-Path -LiteralPath $dest) { Set-AppOffline $dest }
    }
    if ($Kind -eq 'service') { Set-ServiceState $ServiceName 'stop' }
    if ($migrating) {
      if ($SiteName) { Set-IisState 'site' $SiteName 'stop'; $siteStopped = $true }
      foreach ($d in $dirs) {  # keep the history of the real PersistDirs
        $old = Join-Path $dest $d
        if ((Test-Path -LiteralPath $old) -and -not (Test-IsJunction $old)) {
          Get-ChildItem -LiteralPath $old -Force | Move-Item -Destination (Join-Path $dataRoot $d)
        }
      }
      $legacy = Join-Path $releasesRoot "legacy_$stamp"
      Move-Item -LiteralPath $dest -Destination $legacy
      $previous = [IO.Path]::GetFullPath($legacy).TrimEnd('\')
    }
    if (Test-IsJunction $dest) { Remove-Junction $dest }
    New-Junction $dest $release
    Write-Step "$dest -> $release"
    if ($previous) { Clear-AppOffline $previous }
    if ($siteStopped) { Set-IisState 'site' $SiteName 'start' }
    if ($Kind -eq 'api') { Set-IisState 'apppool' $AppPool 'start' }
    if ($Kind -eq 'service') { Set-ServiceState $ServiceName 'start' }

    Write-Step 'Smoke test'
    if ($HealthUrl) { $ok = Test-Url $HealthUrl '' $HealthTimeoutSec }
    else { Start-Sleep -Seconds 10; $ok = ((Get-Service -Name $ServiceName).Status -eq 'Running') }
    # "<Version>" exactly, optionally followed by SemVer build metadata (+sha), which is not part of the version.
    if ($ok -and $versionCheck) { $ok = Test-Url $versionCheck ('"{0}(\+[0-9A-Za-z.-]+)?"' -f [regex]::Escape($Version)) $HealthTimeoutSec }
    if (-not $ok) { throw "The smoke test failed for $Version." }
  } catch {
    $failure = $_
    Write-Step "FAILED: $($failure.Exception.Message)"
    Undo-Deploy
    $result = if (-not $previous) { 'failed' } elseif ($script:RollbackOk) { 'rolled-back' } else { 'rollback-failed' }
    if ($result -eq 'rollback-failed') { Write-Host '::error::The rollback did not finish cleanly: it needs a human.' }
    Add-DeployLog $releasesRoot (Split-Path -Leaf $release) $result
    throw $failure
  }

  # 4. Done: record it and prune old releases. A pruning problem never fails a live deploy.
  Write-Step "Deployed $Version"
  Add-DeployLog $releasesRoot (Split-Path -Leaf $release) 'ok'
  try {
    $protected = @((Split-Path -Leaf $release))
    if ($previous) { $protected += (Split-Path -Leaf $previous) }
    $names = @(Get-ChildItem -LiteralPath $releasesRoot -Directory -Force | ForEach-Object { $_.Name })
    foreach ($n in (Select-ReleasesToPrune $names $protected ([Math]::Max(2, $KeepReleases)))) {
      Write-Step "Pruning $n"
      Remove-Release (Join-Path $releasesRoot $n)
    }
  } catch { Write-Step "WARN pruning failed: $($_.Exception.Message)" }
}

if ($MyInvocation.InvocationName -ne '.') {  # dot-sourcing (tests) only defines the functions
  try { Invoke-Deploy } catch { Write-Host "::error::$($_.Exception.Message)"; exit 1 }
  exit 0  # robocopy leaves 1-7 in $LASTEXITCODE on success
}
