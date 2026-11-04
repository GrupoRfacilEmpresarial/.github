# Despliegue a IIS (Windows Server, sin contenedores)

`deploy-iis.yml` despliega una **versión ya publicada** por `container-release.yml` en un servidor
Windows con IIS. Es el espejo de `deploy-vps.yml` (12.6.2, 12.6.5, 16.2) para los sistemas que no
corren en contenedores.

> **Estado.** El workflow y el script se validaron con `actionlint`, el parser de Windows
> PowerShell 5.1 y una corrida sobre carpetas temporales. Todavía no corrieron contra un servidor
> real: `crane` y `tar` en Windows Server 2019, `appcmd`, el swap de junction, el reciclado del
> pool y el comportamiento de IIS ante el cambio de una junction se prueban primero en dev. No lo
> uses en producción antes de eso.

## Cómo funciona

```
push -> container-release.yml -> imagen FROM scratch en GHCR (version inmutable)
                                        |
        runner del servidor <- deploy-iis.yml (environment + version)
                |
   crane export -> carpeta de release -> swap de junction -> smoke test -> (rollback automático)
```

El artefacto es una imagen que **no se ejecuta**: un Dockerfile compila en Linux y termina en
`FROM scratch` con el resultado. Así se reusa `container-release.yml` sin cambios (versiones
`-dev.*`, `-rc.N` y estable por re-tag, trazabilidad al commit). Plantillas:
[`templates/Dockerfile.iis-api`](../../templates/Dockerfile.iis-api) y
[`templates/Dockerfile.iis-spa`](../../templates/Dockerfile.iis-spa).

El job solo despliega: nunca compila ni prueba en el servidor. No usa SSH ni secretos de deploy,
porque corre en el propio servidor y baja la imagen con el `GITHUB_TOKEN` del job. El script es
Windows PowerShell 5.1, la versión que trae Windows Server.

| `kind` | Qué hace el despliegue |
|---|---|
| `api` | detiene el pool, deja `app_offline.htm`, cambia la junction y arranca el pool |
| `spa` | cambia la junction; no detiene el sitio ni el pool (el corte es el instante entre desvincular y crear la junction) |
| `service` | detiene el servicio, cambia la junction y lo arranca |

## Qué necesita el servidor

- Un runner self-hosted con los labels `self-hosted, windows, x64, iis-<ambiente>`: `iis-dev`,
  `iis-qa` o `iis-prod`, uno por servidor, en un grupo restringido a los repos que despliegan
  (nunca `Default`). Solo corre el job de deploy.
- `git`, `crane` en el `PATH`, `System32\tar.exe` e IIS con `appcmd.exe`. Para `api`, el Hosting
  Bundle de la versión de .NET que publica el repo.
- La cuenta del runner necesita Modify sobre la carpeta que contiene a `IIS_DEST_PATH`, y permiso
  para administrar sitios, pools y servicios.
- Las releases heredan los permisos de la carpeta `<IIS_DEST_PATH>_releases`, no los de la carpeta
  del sitio. Conviene **crearla de antemano** y darle ahí lectura a la identidad del pool (o a la
  cuenta del servicio): el script no cambia una carpeta que ya existe, y así esa identidad no
  recibe lectura sobre los demás sitios que viven en la carpeta padre. Lo mismo con
  `<IIS_DEST_PATH>_data\<carpeta>` para las `persist-dirs` (por defecto `Logs`), que la
  aplicación escribe: ahí va el permiso de escritura.
- Salida HTTPS a `github.com`, `api.github.com` (la lista de aprobadores del resumen), `ghcr.io`,
  `*.actions.githubusercontent.com` y `pkg-containers.githubusercontent.com`. En producción no
  hace falta entrada: el runner consulta.
- Para `service`: el servicio tiene que arrancar su ejecutable desde `IIS_DEST_PATH` (la junction),
  no desde una release. El
  nombre del servicio es una variable del Environment porque puede cambiar de un ambiente a otro.
- Las rutas y los nombres de sitio, pool y servicio pueden llevar espacios.

## Environment

El GitHub Environment (`dev`, `qa`, `prod`) lleva solo variables. **`prod` con revisores
obligatorios** y *deployment tags* restringidos a `v*`: esa aprobación es el registro de quién
autorizó la promoción (12.6.2 regla 4).

| Variable | Para qué | Obligatoria |
|---|---|---|
| `IIS_DEST_PATH` | Ruta que usa IIS o el servicio. Pasa a ser una junction | siempre |
| `HEALTH_URL` | URL completa que debe responder 2xx tras el cambio, con el esquema, el nombre y el puerto con que está enlazado el sitio | `api` y `spa` |
| `HEALTH_CONNECT_ADDRESS` | IP a la que conectar si el binding del sitio es por IP | no |
| `HEALTH_SKIP_CERT_CHECK` | `true` para aceptar cualquier certificado en el smoke test | no |
| `IIS_APP_POOL` | Pool que se detiene durante el cambio | `api` |
| `WIN_SERVICE_NAME` | Servicio de Windows | `service` |
| `IIS_SITE_NAME` | Sitio que se detiene en el primer despliegue sobre una carpeta real | solo ese caso |

## Invocación

```yaml
jobs:
  release:
    uses: GrupoRfacilEmpresarial/.github/.github/workflows/container-release.yml@main
    permissions: { contents: read, packages: write }
    with:
      images: '[{"name":"","dockerfile":"Dockerfile.iis","build-args":"PROJECT=src/Api/Api.csproj"}]'
    secrets: inherit

  deploy:
    needs: release
    if: needs.release.outputs.environment != ''
    uses: GrupoRfacilEmpresarial/.github/.github/workflows/deploy-iis.yml@workflows/v1
    permissions: { contents: read, packages: read, actions: read }
    with:
      environment: ${{ needs.release.outputs.environment }}
      version: ${{ needs.release.outputs.version }}
      kind: api
      version-url: /version
```

El caller debe conceder los tres permisos del ejemplo, o el workflow no arranca. Para volver a
una versión anterior, el caller también expone un `workflow_dispatch` con `environment` y
`version` que llama al mismo job `deploy`.

| Entrada | Default | Qué hace |
|---|---|---|
| `environment` | obligatoria | `dev`, `qa` o `prod`. Elige el runner `iis-<ambiente>` |
| `version` | obligatoria | `X.Y.Z`, `X.Y.Z-rc.N` o `X.Y.Z-dev.*`. Un `-dev` o un `-rc` nunca llega a `prod` |
| `kind` | obligatoria | `api`, `spa` o `service` |
| `image` | `ghcr.io/<org>/<repo>` | Imagen sin tag, si el repo publica más de una. Tiene que ser de `ghcr.io/<org>/` |
| `version-url` | vacío | Ruta (`/version`, `/version.json` en un front) o URL. Su respuesta debe contener `"<versión>"`, y se admite `+<metadatos>` después (`"1.2.3+abc1234"` pasa para `1.2.3`; `"1.2.3-rc.1"` no). Vacío: no verifica |
| `server-files` | `appsettings*.json` | Archivos del servidor que no viajan en el paquete |
| `persist-dirs` | vacío | Carpetas que sobreviven a las releases. Vacío: `Logs` en `api` y `service`, ninguna en `spa` (una junction `Logs` en la raíz de un front taparía una ruta `/logs` del cliente) |
| `org-ref` | `workflows/v1` | De dónde se baja el script. Un tag `workflows/vN` o un SHA, nunca una rama |

## Qué pasa en el servidor

```
<IIS_DEST_PATH>           junction: lo que sirve IIS
<IIS_DEST_PATH>_releases\ una carpeta por despliegue: <versión>_<fecha UTC>, y deployments.log
<IIS_DEST_PATH>_data\     lo que sobrevive a las releases (persist-dirs)
```

1. La release nueva se arma al lado de la viva. Si algo falla aquí, la viva no se toca.
2. Los `server-files` se copian de la release viva a la nueva y el paquete no los pisa. Las
   `persist-dirs` son junctions hacia `_data`. Los permisos de esos archivos se heredan de la
   release nueva; no se copian.
3. Cambio de la junction y arranque, según el `kind`.
4. Smoke test: `HEALTH_URL` responde 2xx y `version-url` devuelve la versión desplegada.
5. Se conservan las últimas 5 releases y nunca se borra la viva ni la anterior. Solo se podan las
   carpetas cuyo nombre es exactamente `<versión>_<fecha>` (con una versión que el script acepta);
   cualquier otra cosa en la carpeta de releases, como una copia que alguien dejó a mano, no se
   toca. Si una junction tiene ese nombre, se desvincula sin tocar su destino.
   `legacy_<fecha>` tampoco se poda: es la única copia de la carpeta tal como estaba antes
   del primer despliegue (puede tener subidas, certificados o un `web.config` editado a mano), y
   quien opera el servidor la borra a mano cuando ya no la necesite.

**Configuración del servidor.** `appsettings*.json` se edita en la release viva (a través de la
junction) y el siguiente despliegue la arrastra. Si una versión nueva exige una clave nueva, hay
que agregarla **antes** de desplegarla; si no, el smoke test falla y vuelve la versión anterior.
En el primer despliegue de un sitio sin release viva no hay de dónde copiar: hay que dejar la
configuración a mano.

**Primer despliegue.** `IIS_DEST_PATH` puede ser una junction ya existente (a cualquier carpeta,
incluido el esquema de otro despliegue) o una carpeta real. Con una junction, esa carpeta pasa a
ser la release anterior y no se toca. Con una carpeta real y `IIS_SITE_NAME` definido, el script
primero comprueba, con `appcmd list vdir`, que la raíz del sitio sea justamente `IIS_DEST_PATH`:
si apunta a otra carpeta (un error de tipeo, una carpeta padre) aborta sin cambiar nada. Luego
detiene el sitio, renombra la carpeta a `<ruta>_releases\legacy_<fecha>` (es el destino del
rollback) y crea la junction. Es una vez por sitio. El chequeo solo mira la raíz de la aplicación
raíz del sitio: para la carpeta de una subaplicación o de un directorio virtual hay que crear la
junction a mano la primera vez (una junction que ya existe no pasa por el chequeo).

Con `kind: service` no hace falta `IIS_SITE_NAME` y el script lo ignora: se detiene el servicio,
se renombra la carpeta, se crea la junction y se arranca el servicio; si no vuelve a arrancar, la
junction vuelve a apuntar a la carpeta original. Ese camino no tiene el chequeo de la ruta, porque
un servicio no tiene sitio al que preguntar: hay que revisar `IIS_DEST_PATH` a mano.

Dos detalles de esa primera vez. Si el rollback ocurre después de crear la junction,
`IIS_DEST_PATH` queda como una junction hacia `legacy_<fecha>` y no como la carpeta real, y las
`persist-dirs` ya movidas a `_data` quedan fuera de ella (la aplicación crea una nueva en la
carpeta original). Y si la migración falla y se repite, mover esas carpetas a `_data` falla sin
pisar nada cuando ya hay archivos con el mismo nombre: hay que resolverlo a mano.

## Smoke test

El script consulta `HEALTH_URL` desde el propio servidor, con un socket propio y no con
`Invoke-WebRequest`, para poder controlar a qué se conecta:

- **Binding por IP.** Con `HEALTH_CONNECT_ADDRESS` se conecta a esa IP, y la URL aporta el
  `Host` y el nombre TLS (SNI). Sin ella, se resuelve el nombre de la URL.
- **Redirecciones.** No se siguen. Un 3xx falla con un mensaje que muestra el destino: hay que
  poner en `HEALTH_URL` la URL final (por ejemplo la `https` y no la `http`).
- **Certificado.** Se valida el de la URL, con su cadena y su nombre. Si el sitio usa una CA
  interna que el servidor no conoce, o la URL no coincide con el certificado, se puede
  desactivar con `HEALTH_SKIP_CERT_CHECK=true`. Solo afecta al smoke test, que no envía nada
  sensible.
- No usa proxy. `version-url` relativa toma el esquema, el nombre y el puerto de `HEALTH_URL`.
- Sin `HEALTH_CONNECT_ADDRESS`, el nombre de la URL se resuelve por DNS y puede caer en otro nodo
  o en un CDN: la salud pasaría en el nodo viejo. En `prod`, definir la dirección y `version-url`.
- `HEALTH_URL` y `HEALTH_CONNECT_ADDRESS` se validan antes de tocar nada: una URL relativa, sin
  esquema o con una IP que no es IPv4 hace fallar el despliegue de entrada.

Límites: solo `GET` con TLS 1.2, sin autenticación ni cabeceras propias (manda
`User-Agent: deploy-iis`), la respuesta se lee entera, y solo IPv4. Un endpoint de salud que pida
autenticación no sirve para esto.

## Configuración del pool

El script **no cambia nada del pool**: solo lo detiene y lo arranca. La configuración es del
servidor. Para una API ASP.NET Core:

- `managedRuntimeVersion` vacío (en la consola, *No Managed Code*): ASP.NET Core corre con su
  propio runtime.
- `startMode="AlwaysRunning"` y, en el sitio, `preloadEnabled="true"`, si la aplicación ejecuta
  trabajos en proceso (colas, programadores) o si el primer arranque es lento.
- `processModel.idleTimeout="00:00:00"` en ese mismo caso; con el valor por defecto, IIS apaga el
  pool por inactividad y los trabajos se detienen.
- Un sitio estático (`spa`) no necesita ajustes especiales.

## Rollback

- **Automático:** si falla cualquier paso desde que se detiene la aplicación (el cambio de
  junction, el arranque o el smoke test), el script devuelve la junction a la release anterior,
  reinicia el pool o el servicio y vuelve a sondear. La release fallida queda en disco para
  investigar. La fila de `deployments.log` dice `rolled-back`; si el propio rollback falla o el
  sitio sigue sin responder, dice `rollback-failed` y el job termina con un error: hace falta una
  persona. Sin release anterior (primer despliegue) no hay a dónde volver: la release fallida
  sigue enlazada y el pool arrancado sobre ella, y la fila dice `failed`.
- **Cancelación o tiempo vencido:** si el job se corta a mitad del cambio, no hay quien deshaga
  nada: el pool puede quedar detenido y `app_offline.htm` en la release viva. Se arranca el pool y
  se borra ese archivo a mano.
- **Manual:** volver a desplegar una versión publicada (12.6.2, 9.7). Es otro despliegue completo,
  con su aprobación en `prod`. Si el Environment `prod` restringe los *deployment tags* a `v*`, el
  `workflow_dispatch` hay que lanzarlo sobre el tag de esa versión, no sobre una rama.

## Registro

Cada despliegue deja una fila en `deployments.log` (fecha UTC, versión, release, resultado,
digest de la imagen y URL de la corrida), y el resumen del job lista quién autorizó: los
aprobadores del Environment, y si no hay ninguno, quien disparó la corrida.

## Versionado y seguridad

El script corre con privilegios en el servidor. Por eso el workflow lo baja de este repositorio
en un tag `workflows/vN` y rechaza una rama.

**El primer tag.** El default de `org-ref` es `workflows/v1`, que se creó sobre el commit de `main`
que contiene `deploy-iis.yml` y `scripts/deploy-iis.ps1`. Un tag nuevo se crea del mismo modo,
sobre el commit de `main` que contiene los cambios: `git tag workflows/vN <sha>` y
`git push origin workflows/vN`. Sin el tag, ningún caller que use el default de `org-ref` puede
ejecutar el workflow (uno que fije un SHA completo en `uses:` y en `org-ref` sí).

Después de fusionar un cambio al script se crea un tag nuevo (o se mueve `vN` solo para
correcciones compatibles) y los callers apuntan a ese mismo tag en `uses:`. Los tags
`workflows/*` están protegidos por el ruleset `workflows-tags-controlados`: solo los
administradores del repositorio y el equipo `release-managers` pueden crearlos, moverlos o
borrarlos.

## Fuera de esta versión

- Migraciones de base de datos: se corren a mano antes del código. Un despliegue no las ejecuta.
- Fronts que hornean valores por ambiente en el bundle: no se pueden promover (12.6.9).
- Configurar Windows por código (WinRM, Ansible).
