# .github — plantillas y workflows de la organización

Repositorio de gobernanza de **GrupoRfacilEmpresarial**. Contiene los archivos de salud
comunitaria que el resto de los repositorios hereda, las plantillas del estándar y los
workflows reutilizables.

La norma que gobierna todo esto es **ENG-STD-001 — Estándar de Versionado, Releases y
Revisiones**, v1.3.0. Su copia autoritativa vive en [`docs/ENG-STD-001.md`](docs/ENG-STD-001.md).

## Qué hay acá

| Ruta | Qué es | Se hereda |
|---|---|---|
| `.github/PULL_REQUEST_TEMPLATE.md` | Plantilla de PR (Anexo D) | Sí, a todos los repos privados del org |
| `CONTRIBUTING.md` | Reglas de ramas y flujo de trabajo (sección 12.1) | Sí |
| `.github/workflows/conventional-commits.yml` | Workflow reutilizable que valida la sección 7 | No, se invoca |
| `templates/CONTRACT.md` | Plantilla de contrato público (Anexo B) | No, se copia |
| `templates/CHANGELOG.md` | Plantilla de changelog (Anexo C) | No, se copia |
| `templates/commitlint.config.js` | Config opcional, solo para repos con Node | No, se copia |
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

## Nivel de cumplimiento

Este repositorio está clasificado `tipo=C`, `nivel=1`.

La escalera de niveles de la sección 0.4 asume que todo repositorio es un servicio: el
nivel 2 exige `CHANGELOG.md` y `GET /version`, y un repositorio de documentación y
plantillas no puede exponer `/version`. `nivel=1` es la única combinación existente que
no genera un incumplimiento el día uno.

**Es un vacío conocido del estándar, no una afirmación de que este repositorio esté
congelado.** Registrado como insumo para la revisión trimestral de la sección 14.3.
