# .github — plantillas y workflows de la organización

Repositorio de gobernanza de **GrupoRfacilEmpresarial**. Contiene los archivos de salud
comunitaria que el resto de los repositorios hereda, las plantillas del estándar y los
workflows reutilizables.

La norma que gobierna todo esto es **ENG-STD-001 — Estándar de Versionado, Releases y
Revisiones**, v1.5.0. Su copia autoritativa vive en [`docs/ENG-STD-001.md`](docs/ENG-STD-001.md).

## Qué hay acá

| Ruta | Qué es | Se hereda |
|---|---|---|
| `.github/PULL_REQUEST_TEMPLATE.md` | Plantilla de PR (Anexo D) | Sí, a todos los repos privados del org |
| `.github/ISSUE_TEMPLATE/solicitud-suplente.yml` | Formulario «Solicitud de suplente» (sección 13.3) | Sí, en los repos sin formularios propios; la solicitud se abre en `.github` |
| `CONTRIBUTING.md` | Reglas de ramas, flujo de trabajo y aprobación (secciones 12.1 y 13.3) | Sí |
| `.github/workflows/conventional-commits.yml` | Workflow reutilizable que valida la sección 7 | No, se invoca |
| `.github/workflows/pr-checks.yml` | Gobierno del PR: título, `semver:*`, CHANGELOG, rama, tamaño, secretos | No, se invoca |
| `.github/workflows/ci-dotnet.yml`, `ci-node.yml`, `ci-python.yml` | Calidad por stack (sección 13.5) | No, se invoca |
| `.github/workflows/container-release.yml`, `deploy-vps.yml`, `deploy-iis.yml` | Build once / promote y despliegue por versión a una VPS o a IIS (sección 12.6) | No, se invoca |
| `scripts/deploy-iis.ps1` | Script que corre `deploy-iis.yml` en el servidor | No, lo baja el workflow |
| `workflow-templates/` | Plantillas listas para copiar por tipo de proyecto | Aparecen en *Actions → New workflow* |
| `docs/ci/` | Guía de adopción de CI/CD | — |
| `templates/CONTRACT.md` | Plantilla de contrato público (Anexo B) | No, se copia |
| `templates/CHANGELOG.md` | Plantilla de changelog (Anexo C) | No, se copia |
| `templates/CODEOWNERS` | Archivo de responsables único: `aprobadores` y `suplentes` (sección 13.3). GitHub no lo hereda: se copia a `.github/CODEOWNERS` de cada repo | No, se copia |
| `templates/commitlint.config.js` | Config opcional, solo para repos con Node | No, se copia |
| `templates/DESPLIEGUE-MANUAL.md` | Registro de despliegue manual, para el Release del tag (sección 12.6.8) | No, se copia |
| `templates/Dockerfile.iis-api`, `Dockerfile.iis-spa` | Artefacto `FROM scratch` para `deploy-iis.yml` | No, se copia |
| `docs/exceptions/` | Excepciones registradas según la sección 17.3 | — |

## Validar Conventional Commits en tu repo

Sin dependencias. La mayoría de los repos del org son .NET, así que el validador es
git + grep en CI y no necesita Node:

```yaml
name: commits
on: [push, pull_request]
jobs:
  conventional:
    uses: GrupoRfacilEmpresarial/.github/.github/workflows/conventional-commits.yml@main
```

## CI/CD estándar por tipo de proyecto

Ver [`docs/ci/README.md`](docs/ci/README.md): workflows reutilizables para .NET, React/Node y
Python, y plantillas en `workflow-templates/`.

## Nivel de cumplimiento

Este repositorio está clasificado `tipo=C`, `nivel=1`.

La escalera de niveles de la sección 0.4 asume que todo repositorio es un servicio: el
nivel 2 exige `CHANGELOG.md` y `GET /version`, y un repositorio de documentación y
plantillas no puede exponer `/version`. `nivel=1` es la única combinación existente que
no genera un incumplimiento el día uno.

**Es un vacío conocido del estándar, no una afirmación de que este repositorio esté
congelado.** Registrado como insumo para la revisión trimestral de la sección 14.3.
