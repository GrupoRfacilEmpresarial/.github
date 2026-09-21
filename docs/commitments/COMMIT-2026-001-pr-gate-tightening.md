# COMMIT-2026-001 - Apriete del gate de pull request a una aprobación obligatoria

| Campo | Valor |
|---|---|
| Fecha de registro | 2026-09-21 |
| Dueño | Equipo `GrupoRfacilEmpresarial/release-managers` |
| Fecha límite | 2026-12-01 |
| Estado | Vigente, pendiente de cumplimiento |

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
