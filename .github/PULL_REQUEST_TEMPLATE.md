## Qué cambia
<descripción en una o dos frases, orientada al comportamiento>

## Por qué
<problema o necesidad; enlace al ticket>
Refs: PROJ-1234

## Clasificación de versión
- [ ] semver:major   - [ ] semver:minor   - [ ] semver:patch   - [ ] semver:none

Justificación: <por qué ese nivel, aplicando la prueba del consumidor
honesto del §4.3>

## Nivel de revisión
- [ ] R1 ligera   - [ ] R2 estándar   - [ ] R3 crítica   - [ ] R0 emergencia

## Impacto en el contrato
- [ ] No toca la superficie pública
- [ ] Toca la API HTTP → OpenAPI actualizado
- [ ] Toca configuración / variables de entorno
- [ ] Toca esquema de base de datos (adjuntar plan expand/contract)
- [ ] Toca eventos, archivos o métricas
- [ ] Introduce una deprecación (con fecha de sunset y métrica de uso)

## Cómo se probó
<pruebas automáticas agregadas, pruebas manuales, ambiente>

## Cómo se revierte
<pasos de rollback; si hay migración, cómo se revierte el dato>

## Checklist del autor
- [ ] CHANGELOG actualizado
- [ ] Matriz de compatibilidad actualizada si aplica
- [ ] Guía de migración y ADR si es semver:major
- [ ] Sin secretos ni datos personales en código ni logs
- [ ] Un solo propósito en este PR
