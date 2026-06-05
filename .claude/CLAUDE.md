# Vault — Instrucciones para Claude Code

Este directorio es el vault de Obsidian de __BUSINESS_NAME__. Es la fuente de verdad del negocio para humanos y agentes de IA.

## ANTES DE CUALQUIER OPERACION

1. **Leer el skill `fate-vault-guardian`** — Contiene las reglas obligatorias del vault (estructura, routing, nomenclatura, frontmatter, permisos, validacion de carpetas).
2. **Leer `_Sistema/REGLAS.md`** — Es la constitucion del vault. Tiene prioridad absoluta.

## REGLAS CRITICAS (resumen ejecutivo)

- **Estructura inamovible**: 5 secciones raiz (`_Sistema/`, `00 Operating System/`, `01 Growth Engine/`, `02 Fulfillment Engine/`, `03 Credenciales/`). NO crear, eliminar ni renombrar sin aprobacion del fundador.
- **2 departamentos** dentro de `01 Growth Engine/`: Marketing, Ventas.
- **SOPs SIEMPRE dentro del departamento** en `{Seccion}/SOPs/` — NUNCA en carpeta centralizada. Esta es la regla mas importante.
- **Nomenclatura**: SOPs = `SOP - {Titulo}.md` | Dashboards = `{Depto}.md` | Content = `@{creador} - {Titulo}.md`
- **Frontmatter YAML obligatorio** en cada archivo .md (titulo, tipo, departamento, actualizado, autor).
- **Validar 5 pasos** antes de crear cualquier carpeta nueva.

## SCOPE

- **APLICA**: Solo archivos locales del vault y MCP Obsidian vault `__VAULT_NAME__`
- **NO APLICA**: VPS, SSH, servidores remotos, Docker, IPs, `/root/`

## MCP Obsidian

El vault se llama `__VAULT_NAME__` en el MCP de Obsidian. Usar ese nombre en todas las operaciones.
