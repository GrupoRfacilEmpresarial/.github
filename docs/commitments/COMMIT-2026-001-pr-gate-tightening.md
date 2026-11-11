# COMMIT-2026-001 - Apriete del gate de pull request a una aprobación obligatoria

| Campo | Valor |
|---|---|
| Fecha de registro | 2026-09-21 |
| Dueño | Equipo `GrupoRfacilEmpresarial/release-managers` |
| Fecha límite | 2026-12-01 |
| Estado | Vigente, cumplimiento parcial (2026-11-11) |

**1. Acción comprometida.** Subir `rules[pull_request].parameters.required_approving_review_count`
de `0` a `1` en el ruleset de organización `pr-obligatorio` (id 21948964).

**2. Por qué existe.** El gate se activó el 2026-09-21 con el contador en `0`, por decisión
explícita: la sección 0.2 regla 1 exige pull request pero no exige aprobación. El apriete a `1`
quedó comprometido en esa misma decisión. Este documento convierte esa intención en un artefacto
verificable, con dueño y fecha.

Dato a registrar: con el contador en `0`, el parámetro
`require_extra_approval_for_unattributed_changes: true` que el ruleset ya tiene no surte efecto
alguno (lo dice la documentación oficial de GitHub sobre esa regla). Recién despierta cuando el
contador sube a `1`. El apriete no solo agrega una aprobación: también enciende el control de
cambios no atribuidos, que hoy figura en el JSON pero no protege nada.

**3. Condiciones previas.** Las dos deben cumplirse antes del apriete:

1. El caso de `.github` resuelto, hoy cubierto por la excepción `EXC-2026-005`.
2. Atendidas las brechas de aprobador de los dominios con una sola persona que conoce el
   código.

**4. Cómo se verifica el cumplimiento.**

```
gh api orgs/GrupoRfacilEmpresarial/rulesets/21948964 --jq '[.rules[]|select(.type=="pull_request")][0].parameters.required_approving_review_count'
```

Debe devolver `1`.

**5. Qué pasa si la fecha llega sin cumplirse.** Se registra una excepción nueva de la sección
17.3 que documente la postergación, con motivo y nueva fecha. El compromiso no vence en
silencio.

**6. Actualización del 2026-11-09 (modelo de aprobadores oficiales).** El conteo de 1
aprobación se exige dentro del modelo de ENG-STD-001 v1.5.0 (sección 13.3): la aprobación de
un aprobador oficial o de un suplente, con revisión de code owner y aprobación del último push,
sobre `main` y `develop` de todos los repositorios, `.github` y `rfacil-platform` incluidos.
Ese conteo **rige cuando el ruleset de organización de aprobación esté activo**. Hasta
entonces el contador sigue en `0` y este compromiso sigue pendiente. Dos cambios sobre el
texto original:

1. La condición previa 2 (brechas de aprobador de los dominios con una sola persona que
   conoce el código) queda cubierta por el modelo cuando esté activo: tres aprobadores
   oficiales aprueban todos los dominios.
2. La verificación del punto 4 se hace sobre el ruleset que quede activo para esta regla. Si
   no es el `21948964`, se consulta el ruleset que lo reemplace.

La condición previa 1 (el caso de `.github`, `EXC-2026-005`) sigue en pie: se cierra cuando el
ruleset de aprobación incluya a `.github`. La fecha límite (2026-12-01) no cambia.

**7. Actualización del 2026-11-11 (S4 aplicado).** El ruleset de organización de aprobación
`aprobacion-obligatoria` (id 27044019) está activo desde el 2026-11-11 con
`required_approving_review_count` en `1`, revisión de code owner, aprobación del último push y
`require_extra_approval_for_unattributed_changes` en `true`, sobre `main` y `develop` de todos
los repositorios no archivados salvo `.github` y `rfacil-platform`, que siguen excluidos hasta
que se resuelva su caso (igual que en `pr-obligatorio`). Un ruleset separado,
`restringir-actualizaciones` (id 27044017), deja que solo el equipo `aprobadores` actualice esas
ramas, y solo por pull request. La verificación del punto 4 sobre el ruleset activo:

```
gh api orgs/GrupoRfacilEmpresarial/rulesets/27044019 --jq '[.rules[]|select(.type=="pull_request")][0].parameters.required_approving_review_count'
```

Devuelve `1`. El ruleset anterior, `pr-obligatorio` (id 21948964), sigue activo con el contador
en `0` hasta que se lo deshabilite. Estado: **cumplimiento parcial**. La condición previa 1 (el
caso de `.github`, `EXC-2026-005`) sigue en pie: el compromiso se da por cumplido cuando el
ruleset de aprobación incluya a `.github` y a `rfacil-platform`. La fecha límite (2026-12-01) no
cambia.

**8. Actualización del 2026-11-11 (los aprobadores solo aprueban).** Con el modelo de
ENG-STD-001 v1.6.0 el autor integra su PR y los aprobadores solo aprueban. El ruleset
`restringir-actualizaciones` (id 27044017) se deshabilita (`enforcement: disabled`,
`rfacil-platform#175`): una vez aplicado, ya no rige lo dicho sobre él en el punto 7 y ningún
equipo queda limitado a actualizar `main` y `develop`. Desde el 2026-11-11 los dos rulesets de
organización ya no excluyen ningún repositorio, `.github` y `rfacil-platform` incluidos: lo dicho
sobre las exclusiones en el punto 7 está superado. La aprobación la sigue exigiendo
`aprobacion-obligatoria` (id 27044019), sin cambios; la verificación del punto 4 es la del
punto 7. El ADR-0002 registra la decisión. Esta actualización no cambia el estado del
compromiso; su cierre se registra aparte.
