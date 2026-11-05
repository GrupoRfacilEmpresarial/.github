# ADR-0001: Despliegue automático a IIS sin contenedores

| Campo | Valor |
|---|---|
| Estado | Propuesto |
| Fecha | 2026-11-05 |
| Autor | `rodrigozalpich`; revisión solicitada al equipo `identidad-plataforma` |
| Ticket | PES-831 (historia bajo PES-766) |
| Norma | ENG-STD-001 §12.6.2, §12.6.5 y §13.1 (un cambio R3 lleva ADR) |
| Excepciones relacionadas | EXC-2026-013 (despliegue manual a IIS) y EXC-2026-014 (cubre solo los primeros PR del pipeline) |
| Implementación | [`docs/ci/iis.md`](../ci/iis.md), `deploy-iis.yml`, `scripts/deploy-iis.ps1` y las plantillas `templates/Dockerfile.iis-*` de este repositorio |

## Resumen

Los sistemas que corren en Windows Server con IIS, sin contenedores, se despliegan a mano. Este ADR fija cómo se
automatiza: una imagen `FROM scratch` en GHCR como artefacto, un runner de GitHub Actions por servidor que solo
despliega, releases inmutables con una junction, y el lado de GitHub (grupos de runners, Environments y variables)
como código en `rfacil-platform`. Aplica a los 8 repositorios del alcance de PES-831. Hoy solo dev está en marcha.

## Contexto

- Cada despliegue manual repite el incumplimiento de ENG-STD-001 §12.6.2 y §12.6.5 que registró EXC-2026-013; la
  retro del 2026-12-01 pide fecha para el pipeline.
- Hay tres servidores (dev, qa y prod) con IIS. El de prod no tiene entrada pública, pero sale a internet.
- Ya existe `container-release.yml`, que calcula la versión (`-dev.*`, `-rc.N` y estable por re-tag), la publica
  como imagen inmutable y deja trazabilidad al commit. Falta el último tramo: llevar el contenido al sitio IIS.

## Decisiones

### D1. El artefacto es una imagen `FROM scratch` en GHCR que nunca se ejecuta

Un Dockerfile compila en Linux (`dotnet publish` o el build del front) y termina en `FROM scratch` con el resultado.
`container-release.yml` se reusa sin cambios. El runner del servidor baja el contenido con `crane export`, con el
`GITHUB_TOKEN` del job (`packages: read`).

**Por qué.** Reusa versionado, inmutabilidad y trazabilidad ya resueltos (§12.6.2: construir una vez y promover el
artefacto) en lugar de inventar un formato propio.

**Alternativa descartada:** *un zip por repositorio como artefacto de Actions.* Habría que reimplementar la
versión por canal, la inmutabilidad y el re-tag de `-rc` a estable.

### D2. Un runner self-hosted de Windows por servidor, solo para el job de deploy

Labels `[self-hosted, windows, x64, iis-<ambiente>]`, un grupo de runners por ambiente restringido a los repositorios
que despliegan (nunca `Default`). El runner no compila ni prueba: eso ocurre en los runners de CI. Como el runner
consulta a GitHub, el servidor de prod no necesita entrada.

**Por qué.** El deploy corre dentro del servidor: no hace falta SSH ni credenciales de despliegue, y el único
secreto en juego es el `GITHUB_TOKEN` del propio job.

**Alternativa descartada:** *runners de GitHub conectándose al servidor por SSH o WinRM.* Exige credenciales de
despliegue guardadas y una entrada al servidor, que prod no tiene.

### D3. Ambientes según ENG-STD-001 §12.1 y §12.6

`develop` despliega a dev (`-dev.*`), `release/X.Y.Z` a qa (`-rc.N`) y un tag `vX.Y.Z` sobre `main` a prod. Prod
lleva revisores obligatorios (`release-managers`) y *deployment tags* restringidos a `v*`. Solo dev, qa y prod
entran: los demás ambientes de los servidores quedan fuera.

### D4. Releases inmutables y una junction, con la configuración del servidor fuera del paquete

El sitio apunta a una junction (`<ruta>`) hacia una carpeta de release (`<ruta>_releases\<versión>_<fecha>`). Para una
API, el despliegue detiene el pool, deja `app_offline.htm`, cambia la junction y arranca el pool. Los
`appsettings*.json` y las carpetas persistentes (`Logs` y las que cada repo declare) viven fuera de la release: la
primera se copia de la release viva y las segundas son junctions hacia `<ruta>_data`. Se conservan las últimas 5
releases y la carpeta original del primer despliegue (`legacy_<fecha>`) no se poda.

**Por qué.** Es el patrón que ya usaba el despliegue manual mejor resuelto de la organización, y permite volver
atrás repuntando la junction.

### D5. Rollback automático y manual

Si falla el smoke test (`GET /version` debe devolver la versión desplegada), el script vuelve a la release anterior.
El manual es redesplegar una versión ya publicada con `workflow_dispatch` o, en el servidor, repuntar la junction a
la release anterior (el procedimiento está en el runbook de cada repositorio).

### D6. El lado de GitHub es código

Los grupos de runners, los Environments y sus variables salen de la sección `iis` de `sites.yml` y de Terraform en
`rfacil-platform`. Los repositorios cuyo grupo, Environment y variables se crearon a mano se importan con bloques
`import` en el mismo PR que los agrega a `sites.yml`; sin esa entrada, el siguiente `apply` los quita del grupo.
Todavía no se corrió ningún `apply` de estos recursos.

### D7. Fuera de esta decisión

Las migraciones de base de datos se corren a mano antes del código; configurar Windows por código (WinRM, Ansible)
y los front-ends con configuración incorporada al compilar (§12.6.9) se tratan aparte.

## Seguridad

El riesgo principal es el runner del servidor: su cuenta necesita permisos amplios sobre IIS y sobre la carpeta de
los sitios, y cualquier job que llegue a ese runner los hereda. Controles de esta decisión:

- grupo de runners por ambiente, restringido a repositorios privados concretos;
- el runner solo ejecuta el job de deploy y ningún workflow que use el runner debe tener disparador `pull_request`;
- el script que corre en el servidor se baja de este repositorio en un tag `workflows/vN` (nunca una rama) y esos
  tags están protegidos por el ruleset `workflows-tags-controlados`;
- sin secretos de despliegue: los Environments llevan solo variables;
- prod con revisores obligatorios y *deployment tags* `v*` (§12.6.2, regla 4): definidos en `sites.yml`, pero el
  Environment de prod todavía no se creó;
- cada despliegue deja una fila en `deployments.log` con la versión, el digest de la imagen y la URL de la corrida.

`GET /version` es anónimo y expone el nombre del servicio, la versión y el commit, como pide §12.6.5.

## Estado

| Repositorio | Dev | Qa | Prod |
|---|---|---|---|
| `BackMultivaGastosAMEX` (piloto) | desplegado | pendiente | pendiente |
| `SSOMultiva` | desplegado | pendiente | pendiente |
| `APIMaterialidadCorreo` | desplegado | pendiente | pendiente |
| `RfacilSSO_BC` | en revisión | pendiente | pendiente |
| Resto del alcance (fronts, servicio de Windows y los demás APIs) | pendiente | pendiente | pendiente |

El rollback automático y el manual todavía no se probaron en un servidor real.

## Consecuencias y riesgos conocidos

- Quien despliega un repositorio con base de datos tiene que correr las migraciones antes. El smoke test solo
  consulta `/version` y no detecta una columna que falte.
- *Run workflow* solo aparece cuando el workflow está en la rama por defecto: hasta la primera promoción a `main`,
  el rollback manual de un repositorio nuevo es el del servidor.
- `container-release.yml` re-etiqueta una imagen ya construida para un árbol que se repite (por ejemplo un revert);
  esa imagen responde la versión con la que se compiló y el smoke test falla. Limitación conocida, sin corregir.
- Los permisos amplios del runner son una decisión consciente (usuario estándar no alcanza a leer la configuración
  de IIS); se revisa al cerrar el piloto y antes de registrar el runner de prod.
- Los repositorios con secretos versionados no los resuelve este ADR: se rotan y se sacan del repositorio en tickets
  aparte.
