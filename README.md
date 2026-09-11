# Vault Template — Negocios Digitales con Claude Code

Estructura de Obsidian + Claude Code para operar tu negocio con IA. Réplica del sistema operativo de [Maze Funnels](https://mazefunnels.io), sincronizada con el vault real (septiembre 2026).

> Para configurar el servidor (Traefik + n8n + Supabase) → [client-vps-template](https://github.com/mazeos/client-vps-template). Los dos repos son independientes: podés instalar solo el vault.

## Qué incluye

| Componente | Qué hace |
|---|---|
| Estructura del vault | 5 secciones raíz, 2 departamentos, routing y nomenclatura fijos |
| `_Sistema/REGLAS.md` | La constitución: tipos de documento, frontmatter, cero sermón, routing, validación de carpetas |
| `.claude/CLAUDE.md` | Instrucciones globales para Claude Code: cuándo y cómo actualizar el vault |
| Hook `SessionStart` | Claude lee el vault al iniciar — ya sabe todo desde el primer mensaje |
| Hook `PostToolUse` | Sincroniza la memoria de Claude a Obsidian en tiempo real |
| Hook `Stop` | Archiva cada conversación por fecha, con el mismo título que muestra Claude Code |
| Hook `SessionEnd` | Sync final de memoria + tabla de MCPs en `Servicios.md` |
| Hook `PreToolUse` | `delete-guard` — cualquier `rm`/`rmdir`/`unlink` pide confirmación antes de ejecutarse |
| Skill `fate-vault-guardian` | Claude audita y respeta estructura, routing, nomenclatura y frontmatter en cada operación |
| MCP de Obsidian | Claude lee y escribe en el vault por nombre |

## Instalación

### Mac / Linux
```bash
curl -sSL https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.sh -o /tmp/setup-vault.sh && bash /tmp/setup-vault.sh
```

### Windows (PowerShell como Administrador)
```powershell
irm https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.ps1 -OutFile $env:TEMP\setup-vault.ps1; & $env:TEMP\setup-vault.ps1
```

El instalador verifica los prerrequisitos (Node.js, Python, Claude Code), copia la estructura, personaliza hooks, skill y `CLAUDE.md` con tus datos, configura `settings.json` y conecta el MCP de Obsidian.

Te pregunta 5 cosas:
1. Ruta del vault
2. Nombre de tu negocio
3. Tu nombre (fundador)
4. Nombre del vault en Obsidian (para el MCP)
5. API Key del plugin Local REST API

## Requisitos

- [Obsidian](https://obsidian.md) con el plugin **Local REST API** activo
- [Claude Code](https://claude.com/claude-code) instalado y autenticado
- Node.js 18+ y Python 3.8+ (el instalador los instala si faltan)

## Estructura del vault

```
_Sistema/               → Constitución, mapa, templates, skills (no modificar)
00 Operating System/    → Infraestructura: Activos + SOPs + Claude Code (memoria, conversaciones, MCPs)
01 Growth Engine/       → Marketing (Activos+Branding+SOPs) + Ventas (Activos+SOPs)
02 Fulfillment Engine/  → Activos + Clientes + SOPs
03 Credenciales/        → APIs, tokens, servicios del negocio (excluido de git)
```

Las credenciales de cada cliente viven en su propia carpeta: `02 Fulfillment Engine/Clientes/{Nombre}/Credenciales/`.

## Después de instalar

1. Abrí Obsidian en la ruta del vault.
2. Corré `claude` desde cualquier carpeta: debe aparecer "Cargando contexto desde vault...".
3. Pedile a Claude que corra la auditoría del vault (`/fate-vault-guardian`) para verificar que todo quedó en orden.

## Creado por

[Maze Funnels](https://mazefunnels.io)
