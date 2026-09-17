# Cómo se trabaja en los repositorios de Rfacil

Este documento publica las reglas de ramas de **ENG-STD-001 v1.3.0, sección 12.1**. No inventa
nada: la norma completa está en [`docs/ENG-STD-001.md`](docs/ENG-STD-001.md). Acá está lo que
necesitás tener a mano todos los días.

## Las 5 reglas, y no hay una sexta

1. **`main` y `develop` no reciben push directo.** Todo entra por pull request. Ni un cambio de
   una línea, ni el más senior del equipo.
2. **Toda rama `feature/*` vive menos de 5 días laborales.** Si necesita más, se parte, o se
   integra progresivamente detrás de una bandera de funcionalidad.
3. **Las ramas se eliminan al mergear.**
4. **`main` está siempre desplegable**, y todo release estable existe en `main` como commit
   taggeado.
5. **`main` y `develop` son las únicas ramas permanentes.** Prohibido crear ramas por ambiente.

La regla 2 no es cosmética: es la que impide que una rama se convierta en un fork. Una rama de
tres semanas no es una rama, es un proyecto paralelo que alguien va a tener que rescatar.

## Ruta rápida: un cambio normal

```bash
git switch develop && git pull
git switch -c feature/PROJ-1234-descripcion-corta

# ... trabajás, commiteás en formato convencional ...
git commit -m "feat(pagos): agregar exportacion a XLSX"

git push -u origin feature/PROJ-1234-descripcion-corta
gh pr create --base develop
```

1. Salís de `develop`, nunca de otra feature.
2. Nombrás la rama `feature/<ticket>-<slug>`.
3. Commiteás en formato convencional (sección 7).
4. Abrís el PR contra `develop`, con la etiqueta `semver:*` que corresponda.
5. Al mergear, la rama se borra.

## Las ramas que existen

| Rama | Vida | Sale de | Vuelve a | Qué representa |
|---|---|---|---|---|
| `main` | permanente | — | — | exactamente lo que está en producción |
| `develop` | permanente | `main` | — | integración de lo que irá en el próximo release |
| `feature/<ticket>-<slug>` | días | `develop` | `develop` | una unidad de trabajo |
| `release/<X.Y.0>` | días | `develop` | `main` + `develop` | estabilización; acá nacen los `-rc` |
| `hotfix/<X.Y.Z>` | horas | tag de `main` | `main` + `develop` + `release/*` | corrección urgente de producción |
| `support/<X.Y>` | meses | tag de `main` | ella misma | línea antigua bajo soporte (sección 15) |

`support/*` está **inactiva** hoy (sección 0.5): se activa si un cliente exige por contrato una
línea antigua. Hasta entonces solo se soporta la línea vigente.

## El back-merge, ahora que el merge es squash

La tabla de arriba dice que `release/*` y `hotfix/*` vuelven a `main` **y** a `develop`. Eso sigue
siendo obligatorio (secciones 12.2 paso 7 y 9.5 paso 6). Lo que cambió es **cómo** se hace.

El ruleset de organización impone `squash` como único método de merge, más historia lineal, sobre
`main` y `develop`. El merge sin fast-forward dejó de existir como opción. Si aplastás la misma
rama por separado en las dos, te quedan dos commits distintos con el mismo contenido y las ramas
divergen para siempre.

**Qué hacer en su lugar.** Después de cada release o hotfix, abrí un PR de sincronía de `main`
hacia `develop`:

```bash
git fetch origin
git checkout -b feature/<ticket>-sync-main-develop origin/main
git push -u origin feature/<ticket>-sync-main-develop
gh pr create --base develop --head feature/<ticket>-sync-main-develop \
  --title "chore(sync): baja a develop lo liberado en vX.Y.Z"
```

Se mergea con squash, como todo. Si trae conflictos —es lo esperable— resolvelos en la rama de
sincronía mergeando `develop` adentro de ella: ese merge commit queda en la rama y el squash lo
aplasta al entrar.

**Cómo verificar que quedó.** No sirve `git log develop..main`: bajo squash nunca da vacío, porque
los dos commits tienen el mismo contenido y distinto SHA. Tampoco sirve `git diff develop main`,
que casi siempre trae trabajo de `develop` todavía sin liberar. Anclalo al tag y a los archivos que
ese release tocó:

```bash
git fetch origin --tags
git diff --stat origin/develop vX.Y.Z -- $(git diff --name-only vX.Y.Z~1 vX.Y.Z)
```

Vacío: lo que liberó el release ya está en `develop`. No vacío: esos archivos quedaron afuera,
repetí la sincronía.

Parece un trámite, pero es el paso que más se olvida, y la sección 9.5 lo llama **el error más
común del proceso**. Un back-merge omitido no falla en el momento: simplemente el próximo release
vuelve a empaquetar código que ya se había reemplazado.

## Prohibido

| Qué | Por qué |
|---|---|
| Ramas permanentes por ambiente: `qa`, `demo`, `staging`, `uat` | Los ambientes ejecutan **versiones, no ramas**. La relación se resuelve promoviendo artefactos (sección 12.6) |
| Push directo a `main` o `develop` | Regla 1 |
| Dejar la rama viva después del merge | Regla 3 |
| Escribir el número de versión a mano | Lo calcula la herramienta (sección 16.1) |
| Mover, borrar o reutilizar un tag publicado | Un tag publicado es inmutable (sección 12.4) |

## Validar tus commits en CI

Sin dependencias, sirve igual para .NET que para Node. Agregá esto a tu repo:

```yaml
# .github/workflows/commits.yml
name: commits
on: [push, pull_request]
jobs:
  conventional:
    uses: GrupoRfacilEmpresarial/.github/.github/workflows/conventional-commits.yml@main
```

Los tipos válidos son los 13 de la sección 7.2 — `feat fix perf security deprecate revert
refactor docs test build ci chore style` — más `merge`. El asunto va en 72 caracteres o menos.

Si tu repo ya tiene Node, podés usar además [`templates/commitlint.config.js`](templates/commitlint.config.js)
para que falle en tu máquina antes del push, no en CI.

## Checklist antes de abrir el PR

- [ ] La rama sale de `develop` y se llama `feature/<ticket>-<slug>`
- [ ] Tiene menos de 5 días de vida
- [ ] Un solo propósito, 400 líneas o menos (sección 0.2 regla 2)
- [ ] Todos los commits son convencionales, y el título del PR también
- [ ] El PR lleva su etiqueta `semver:major|minor|patch|none`
- [ ] El CHANGELOG está actualizado en este mismo PR, no después
- [ ] Si toca la superficie pública, el `CONTRACT.md` lo refleja

La plantilla de PR se completa sola al abrirlo. Si no aparece, avisá: significa que la herencia
desde este repositorio no está funcionando.

## Excepción: despliegue continuo

Si tu equipo despliega varias veces por día, podés pedir excepción (sección 17.3) para trabajar
en trunk-based, con estas condiciones: `main` siempre desplegable, ramas de menos de 24 horas,
banderas de funcionalidad obligatorias para trabajo incompleto, y versionado y tags automáticos
en cada merge a `main`.

**Lo que cambia es la topología de ramas, nunca las reglas de versionado.** Clasificación,
contrato, revisiones y CHANGELOG siguen igual.

## Dónde seguir

| Si te toca... | Leé |
|---|---|
| Decidir si un cambio es mayor, menor o parche | secciones 5 y 6 |
| Escribir el mensaje de commit | sección 7 |
| Retomar una rama que quedó muy atrás | sección 12.7 |
| Revisar el PR de alguien más | sección 13.4 |
| Pedir una excepción | sección 17.3 |

Para el 95 % de los casos diarios alcanza con la tarjeta de decisión rápida del **Anexo A**.
Está pensada para imprimirse.
