# Contrato público — <nombre del proyecto>

Versión actual: <X.Y.Z>
Version Owner: <nombre>
Última actualización: <fecha>

## 1. Es público (cambiarlo puede obligar a MAYOR)
- API HTTP: rutas bajo /api/v2, definidas en `contracts/openapi.yaml`
- Códigos de error: catálogo en `docs/errores.md`
- Eventos publicados: `contracts/asyncapi.yaml`
- Variables de entorno requeridas: ver `.env.example` (sección REQUERIDAS)
- Métricas expuestas: `docs/observabilidad.md`
- Health check: GET /health · Versión: GET /version
- Archivos de intercambio: layout de conciliación en `docs/archivos/`

## 2. No es público (se puede cambiar libremente)
- Todo bajo `internal/`
- Esquema de tablas propias no consumidas por otros sistemas
- Rutas bajo /internal/* y /experimental/*
- Textos de error en prosa (los códigos SÍ son públicos)
- Rendimiento absoluto (no hay SLA escrito, salvo lo indicado abajo)

## 3. Cláusula de lector tolerante
Los consumidores DEBEN ignorar campos desconocidos y tolerar valores
nuevos en enums de respuesta. Un consumidor que falle por un campo
nuevo se considera no conforme.

## 4. SLA comprometido
- p95 de /api/v2/pagos < 800 ms
- Disponibilidad mensual 99.9 %

## 5. Consumidores conocidos
| Consumidor | Contacto | Versión de API | Notas |
|---|---|---|---|
| rfacil-web | equipo web | v2 | despliegue continuo |
| rfacil-app (iOS/Android) | equipo móvil | v2 | no forzable a migrar |
| Socio X | cuentas | v1 | deprecada, sunset 2026-10-31 |

## 6. Deprecaciones vigentes
| Elemento | Deprecado en | Reemplazo | Sunset |
|---|---|---|---|
| campo nombreCompleto | 4.1.0 | nombre + apellidos | 2026-10-31 |

## 7. Decisiones de clasificación ya resueltas
- Agregar campos a respuestas: MENOR (aplica cláusula de lector tolerante)
- Cambiar textos de error: PARCHE
- <se agregan aquí las discusiones ya zanjadas, para no repetirlas>
