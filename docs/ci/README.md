# CI/CD estándar de la organización

Workflows reutilizables y plantillas que implementan las secciones 12.6, 13.5 y 16 de
[ENG-STD-001](../ENG-STD-001.md).

## Piezas

| Workflow reutilizable | Qué cubre | Sección |
|---|---|---|
| `conventional-commits.yml` | todo commit es convencional | 0.2 regla 3, 7 |
| `pr-checks.yml` | título de PR, etiqueta `semver:*` coherente con el título, CHANGELOG en el PR, nombre de rama, tamaño ≤ 400 líneas, secretos (gitleaks) | 0.2 reglas 2, 3, 4, 10; 12.1; 13.5 |
| `ci-dotnet.yml` | `dotnet format`, build Release, pruebas unitarias e integración, cobertura con umbral, paquetes vulnerables High/Critical | 13.5 |
| `ci-node.yml` | lint, typecheck, pruebas, build y `audit` con pnpm/npm/yarn (detecta por lockfile) | 13.5 |
| `ci-python.yml` | ruff, mypy, pytest con umbral, integración contra Postgres efímero, pip-audit | 13.5 |
| `container-release.yml` | versión SemVer desde la ref, imagen inmutable en GHCR, **build once / promote** | 12.2, 12.4, 12.6.2 |
| `deploy-vps.yml` | despliegue por versión con docker compose, sondeo de salud, verificación de `GET /version`, registro de despliegue | 12.6.5, 16.2 |

Plantillas (aparecen en *Actions → New workflow* de cualquier repo del org):

| Plantilla | Para |
|---|---|
| `gobierno-pr.yml` | **todos** los repos |
| `ci-dotnet-api.yml` | APIs .NET en contenedor |
| `ci-react-spa.yml` | fronts React/Vite servidos por nginx en contenedor |
| `ci-python-api.yml` | APIs Python en contenedor |

## De la ref de git a la versión y al ambiente

Los ambientes ejecutan versiones, no ramas (12.6.1). El ambiente sale del **canal** de la
versión:

| Evento | Versión | Qué pasa | Ambiente |
|---|---|---|---|
| PR a `develop`/`main` | — | solo calidad | — |
| push a `develop` | `X.Y.Z-dev.AAAAMMDD.sha7` | build (o re-tag si el árbol ya existía) | `dev` |
| push a `release/X.Y.Z` o `hotfix/X.Y.Z` | `X.Y.Z-rc.N` | build; N es el primer `-rc` libre | `qa` |
| push a `main` | — | nada: `main` solo recibe lo ya estabilizado | — |
| tag `vX.Y.Z` sobre `main` | `X.Y.Z` | **re-tag** del `X.Y.Z-rc.N` del mismo árbol, sin compilar | `prod` |

`X.Y.Z` del canal dev se propone desde los commits desde el último tag (breaking → mayor,
`feat` → menor, resto → parche): es el paso 2 de 12.2. En release y hotfix manda el nombre
de la rama.

**Por qué funciona el re-tag a estable con squash-only.** Al aplastar `release/X.Y.Z` en
`main` (con la rama al día respecto de `main`), el commit nuevo tiene el **mismo árbol** de
git que la punta de la release. La imagen se direcciona también por `tree-<hash>`, así que el
tag `vX.Y.Z` encuentra el `-rc.N` exacto que pasó QA y le agrega el tag `X.Y.Z`: mismo
digest, bit a bit. Si el árbol no coincide (la release no estaba al día con `main`), el
workflow falla en lugar de compilar algo que nadie probó.

Tags de imagen que se publican: `<versión>` (inmutable), `sha-<commit>` y `tree-<hash>`.
Ya **no** se publican tags móviles `develop`/`qa`/`prod`.

## Adoptar en un repo

1. Copiar `gobierno-pr.yml` y la plantilla del stack desde *Actions → New workflow* (o desde
   `workflow-templates/`). Completar las líneas marcadas con `<--`.
2. Borrar los workflows anteriores que dupliquen lo mismo (build, docker, deploy).
3. En el `docker-compose.deploy.yml` del servidor, la imagen se referencia como
   `ghcr.io/gruporfacilempresarial/<repo>[-<nombre>]:${IMAGE_TAG}`.
4. *Settings → Environments*: `dev`, `qa`, `prod` con los secrets `CONTABO_HOST`,
   `CONTABO_USER`, `CONTABO_SSH_KEY`, `GHCR_PULL_USER`, `GHCR_PULL_TOKEN` y la variable
   `DEPLOY_PATH`. **`prod` con revisores obligatorios** (`release-managers`): esa aprobación
   es el registro de quién autorizó la promoción (12.6.2 regla 4). En `prod` restringir
   *deployment branches and tags* a `v*`.
5. Crear las etiquetas `semver:major`, `semver:minor`, `semver:patch`, `semver:none`.
6. Si el repo es nivel 2+, tener `CHANGELOG.md` (plantilla en `templates/`).
7. Marcar como *required status checks* en el ruleset los jobs de los workflows `gobierno` y
   `ci`, copiando el nombre tal cual aparece en la pestaña *Checks* de un PR tras la primera
   corrida: el ruleset exige el nombre exacto y no admite comodines. Con los valores por
   defecto, la validación de nombre de rama y la de tamaño solo avisan; para que bloqueen,
   pasar `enforce-branch-names: true` y `enforce-size: true` en `gobierno-pr.yml`.
8. Dockerfile: declarar `ARG APP_VERSION` y `ARG GIT_SHA` y exponerlos en `GET /version`.

## Cambios de comportamiento que hay que acordar antes de migrar

- **`main` deja de desplegar a QA.** QA pasa a recibir `-rc.N` desde `release/*`. Es lo que
  pide 12.1 (`main` = producción) y 12.6; hoy 20 repos hacen lo contrario.
- **Producción solo con tag `vX.Y.Z`** creado por `release-managers` (ruleset
  `release-tags-controlados`) y con aprobación en el Environment `prod`.
- **Fronts con valores por ambiente horneados en el bundle** (`VITE_API_URL` distinto en dev
  y qa) no pueden promoverse sin recompilar. Opciones: rutas relativas iguales en todos los
  ambientes (lo que ya hace `NewAdminAutoFacFront`), o configuración en runtime servida por
  nginx. Mientras tanto, registrar excepción a 12.6.2 regla 1.
- Los repos con deploy a IIS en runner Windows (`AMEX_MULTIVA_FRONT`, `SHK_FRONT`,
  `SUITE_FRONT`, `NewCreacionPDFCrystal`) adoptan `gobierno-pr.yml` y `ci-node.yml`/
  `ci-dotnet.yml` para la calidad; su deploy queda fuera de estas plantillas hasta definir un
  `deploy-iis.yml` equivalente (artefacto versionado, no rama).

## Versionado de estos workflows

Los callers usan `@main`. Cuando haya un cambio incompatible en las entradas de un workflow
reutilizable, se publica un tag `workflows/vN` y los callers pasan a `@workflows/vN`.
