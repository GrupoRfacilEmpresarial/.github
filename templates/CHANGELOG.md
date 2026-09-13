# Changelog

Todos los cambios relevantes de este proyecto se documentan aquí.
Formato: Keep a Changelog. Versionado: SemVer 2.0.0.

## [No publicado]

## [4.0.0] - 2026-09-15
### ⚠ Cambios incompatibles
- **API:** los montos de `/api/v2/pagos` pasan de decimal a entero en
  centavos. Migración: `docs/migraciones/4.0.0.md`
- **Config:** `REDIS_URL` ahora es obligatoria y sin valor por defecto.
- **Eliminado:** campo `nombreCompleto` (deprecado desde 3.5.0, sunset
  2026-08-31).

### Added
- Endpoint `GET /api/v2/facturas/{id}/pdf`.
- Exportación de conciliación en formato XLSX.

### Changed
- El tamaño de página por defecto de listados pasa de 20 a 50.

### Deprecated
- `GET /api/v3/reportes/legacy` — reemplazo: `/api/v3/reportes`.
  Sunset: 2027-03-31.

### Removed
- Campo `nombreCompleto` (ver arriba).

### Fixed
- Corregido el redondeo de IVA en notas de crédito (#1842).

### Security
- Actualizado `libxyz` a 3.2.1 (CVE-2026-12345).

### Migración
Guía completa: `docs/migraciones/4.0.0.md`
Compatibilidad: ver matriz en `docs/compatibilidad.md`
Rollback: `docs/runbooks/rollback-4.0.0.md`

## [3.2.1] - 2026-08-20
### Fixed
- Corregido cálculo de total en facturas con descuento (#1830).

[4.0.0]: https://git.rfacil.com/core/compare/v3.2.1...v4.0.0
[3.2.1]: https://git.rfacil.com/core/compare/v3.2.0...v3.2.1
