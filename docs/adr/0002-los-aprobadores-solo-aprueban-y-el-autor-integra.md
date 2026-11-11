# ADR-0002: Los aprobadores solo aprueban y el autor integra

| Campo | Valor |
|---|---|
| Estado | Aceptado el 2026-11-11, tras la verificación con un desarrollador real (`NewAdminAutoFacBack#356`); el punto 3 de la verificación queda como seguimiento |
| Fecha | 2026-11-11 |
| Autor | `rodrigozalpich` |
| Ticket | sin ticket |
| Norma | ENG-STD-001 §13.1 (un cambio R3 lleva ADR) y §13.3 (reglas 8 a 13, v1.6.0) |
| Implementación | `rfacil-platform#175` (`pr_approvers.org_rulesets.enforcement.restrict_updates`) y este repositorio (ENG-STD-001, `CONTRIBUTING.md`, plantilla de PR, formulario de suplente) |

## Resumen

Desde ENG-STD-001 v1.5.0 los tres aprobadores oficiales revisan, aprueban e integran todo PR hacia `main` y `develop`.
Este ADR cambia el modelo: los aprobadores solo aprueban y el autor del PR integra. La aprobación sigue siendo condición
técnica del merge; lo que se retira es el bloqueo técnico de quién integra.

## Contexto

- El ruleset de organización `restringir-actualizaciones` (id 27044017) bloquea la actualización de `main` y `develop`
  para todos salvo el equipo `aprobadores`, y solo por pull request. Por eso hoy solo ellos integran, y con el tilde
  «bypass rules» en cada merge.
- El autor conoce el orden de sus ramas y las dependencias entre sus PR. El aprobador integraba sin ese contexto y las
  integraciones dependían de tres personas.
- `aprobacion-obligatoria` (id 27044019) exige 1 aprobación de un code owner (`aprobadores` o `suplentes`) sobre el
  último push, sin bypass, en `main` y `develop` de todos los repositorios.

## Decisiones

### D1. Los aprobadores solo aprueban; integra el autor

Reglas 8 y 9 del §13.3. Si el autor es uno de los tres, otro aprueba y el autor integra.

**Por qué.** Quien integra es quien conoce el orden de sus ramas y de sus dependencias.

**Alternativa descartada:** *mantener que el aprobador integra (v1.5.0).* Concentra las integraciones en tres personas
que no conocen las dependencias de cada PR.

### D2. `restringir-actualizaciones` se deshabilita, no se borra

`enforcement: disabled` en `sites.yml`. El recurso Terraform y su guard se conservan.

**Por qué.** La reversión es un cambio de una línea y un apply dirigido, con el mismo id de ruleset.

**Alternativa descartada:** *destruirlo.* Deja la configuración más simple, pero la reversión recrea el ruleset con otro
id y el PR es más grande.

### D3. Lo que queda por proceso

- **El aprobador no integra.** La plataforma no lo impide: el aprobador tiene permiso de escritura como cualquier equipo
  con acceso. Integrar un PR ajeno es un incumplimiento de proceso, se anota en el propio PR y se corrige (regla 8).
- **R3.** El ruleset exige una aprobación y R3 pide dos. El aprobador que da la segunda escribe «R3: segunda
  aprobación» en su revisión y el autor no integra sin ese texto sobre el último push (regla 13).
- **R0.** Sin cambio de fondo y sin bypass: una aprobación vigente antes del merge y revisión formal posterior (regla 12).
- **Suplentes.** No integran (regla 10). La verificación del alcance de dominio del suplente pasa de «al integrar» a «al
  retirar al suplente», a cargo del aprobador que lo habilitó, y es posterior al merge.

### D4. Quién responde por el despliegue

Integrar es desplegar (`develop` publica en dev y `main` en QA, en los repositorios con pipeline). El despliegue lo
respaldan los checks en verde y una aprobación vigente sobre el último push. El autor integra a mano solo cuando puede
vigilar el despliegue y responde por el que resulte. El auto-merge sigue prohibido (regla 11).

### D5. La rama se actualiza antes de pedir revisión

Con `require_last_push_approval`, un push posterior a la aprobación la invalida. Antes el aprobador actualizaba la rama
y fusionaba en el mismo momento; ahora el autor actualiza la rama con su base (§13.5) antes de pedir revisión, o la
revisión se repite (regla 9).

## Transición

El apply de `rfacil-platform#175` se hizo el 2026-11-11, después de fusionar este cambio: desde entonces
`restringir-actualizaciones` está deshabilitado y la plataforma ya no limita quién integra. Antes del apply, solo los
aprobadores podían integrar, con el tilde «bypass rules»: la plataforma era más estricta que este ADR, no menos.

## Consecuencias

- La aprobación de un desarrollador sigue sin contar: el code owner son solo `aprobadores` y `suplentes`.
- Riesgo: un aprobador integra un PR ajeno. No hay bloqueo técnico; se controla con la anotación en el PR y su
  corrección.
- Riesgo: un desarrollador integra un PR R3 con una sola aprobación. El ruleset exige una; se controla con el texto «R3:
  segunda aprobación», que el autor exige antes de integrar.
- Riesgo: un suplente aprueba un PR de otro dominio. El alcance se verifica al retirarlo, después del merge (regla 10).
- Riesgo: un despliegue sin nadie atento. Lo cubre la regla 11: el autor integra solo si puede vigilarlo.

## Verificación

Con una cuenta de desarrollador real (miembro de la organización con permiso de escritura por su equipo de dominio,
fuera de `aprobadores` y `suplentes`):

1. Integra su PR con una aprobación vigente.
2. No integra sin aprobación.
3. Su propia aprobación (o la de otro desarrollador) no cuenta.
4. Un push posterior a la aprobación exige una aprobación nueva.
5. El push directo se rechaza.

**Resultado (2026-11-11).** Se verificó con `EmmanuelRocha-Rfacil` en `NewAdminAutoFacBack#356`, un PR solo de
documentación, sin CI ni despliegue. Los puntos 1, 2, 4 y 5 pasaron: el autor fusionó con una rule-suite en `pass` (no
`bypass`); el PR siguió bloqueado sin aprobación oficial; un push posterior dejó obsoletas las aprobaciones previas; y el
push directo a `develop` fue rechazado con una rule-suite en `fail`. El punto 3 quedó incompleto: el otro revisor solo
tenía lectura, y esa aprobación no cuenta en ningún modelo. Se repite con un desarrollador con escritura.

Los resultados y sus evidencias están en la tabla de verificación del repositorio `eng-metrics`
(`docs/pr-approvers-verification.md`, PR 3).

## Reversión

`restrict_updates: active` en `sites.yml` más un apply dirigido, con el mismo id de ruleset; en una emergencia, activarlo en
la interfaz de GitHub. Vuelve el modelo de v1.5.0 y el estándar se revierte con un PR.
