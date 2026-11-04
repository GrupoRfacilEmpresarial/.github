# Registro de despliegue manual

<!--
Se copia en la sección «Despliegues» del GitHub Release del tag, una vez por despliegue.
Aplica ENG-STD-001 §12.6.8 (repos sin pipeline de despliegue). Si el despliegue no es
el artefacto de un tag, esta plantilla no alcanza: hace falta una excepción (§17.3).
-->

| Campo | Valor |
|---|---|
| Repositorio | `<repo>` |
| Versión (tag) | `vX.Y.Z` |
| Commit del tag | `<sha>` |
| Ambiente | `PROD` / `QA` / `DEMO` |
| Fecha y hora (UTC) | `AAAA-MM-DD HH:MM` |
| Desplegó | `<persona>` |
| Autorizó | `<persona>` (enlace al Go, o al incidente si es hotfix) |
| Hotfix | no / sí: `<enlace al incidente>` |

## Antes

- [ ] El artefacto se compiló desde un checkout limpio del tag (`git status` sin cambios), o lo compiló el CI
- [ ] El zip está publicado en este Release. Hash (SHA-256): `<hash>`
- [ ] Respaldo del sitio actual, con su configuración de ambiente intacta: `<ruta del respaldo>`
- [ ] Lista de lo que **no** se copia (configuración de ambiente, logs): `<appsettings.json, web.config, logs/>`

## Después

- [ ] El hash de los archivos desplegados coincide con el del artefacto (sin logs ni configuración de ambiente)
- [ ] La versión visible es la del tag: `<respuesta de /version, o versión del ensamblado>`
- [ ] Smoke test (§14.2): `<flujos probados>` → `<resultado>`
- [ ] Si es hotfix: PR de sincronía a `develop` abierto: `<enlace>`

## Rollback

Cómo se revierte este despliegue: `<restaurar el respaldo en la ruta de arriba / redesplegar el artefacto de vX.Y.Z-1>`.
