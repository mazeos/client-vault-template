# Vault Template — Negocios Digitales con Claude Code

Estructura de Obsidian + Claude Code para operar tu negocio con IA. Réplica del sistema operativo de [Maze Funnels](https://mazefunnels.io).

> Para configurar el servidor, MCPs y automatizaciones → [client-vps-template](https://github.com/mazeos/client-vps-template)

## Qué incluye

| Componente | Qué hace |
|---|---|
| Estructura del vault | 5 secciones organizadas para operar tu negocio |
| Hook `SessionStart` | Claude lee tu vault al iniciar — ya sabe todo desde el primer mensaje |
| Hook `PostToolUse` | Sincroniza la memoria de Claude a Obsidian en tiempo real |
| Hook `Stop` | Archiva cada conversación organizada por fecha |
| Hook `SessionEnd` | Sync final de memoria + tabla de MCPs en Servicios.md |
| Hook `PreToolUse` | `delete-guard` — bloquea borrados accidentales (rm/rmdir/...) |
| Skill `fate-vault-guardian` | Claude respeta la estructura, routing y nomenclatura del vault |
| MCP de Obsidian | Claude lee y escribe en el vault por nombre |

## Instalación

### Mac / Linux
```bash
curl -sSL https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.sh | bash
```

### Windows (PowerShell como Administrador)
```powershell
irm https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.ps1 | iex
```

El instalador verifica e instala los prerrequisitos (Node.js, Python, Claude Code), copia la estructura del vault, personaliza hooks y skill con tus datos, configura `settings.json` y conecta el MCP de Obsidian.

Te pregunta 5 cosas:
1. Ruta del vault
2. Nombre de tu negocio
3. Tu nombre (fundador)
4. Nombre del vault en Obsidian (para el MCP)
5. API Key del plugin Local REST API

## Requisitos

- Obsidian con plugin **Local REST API** activo
- Node.js 18+ y Python 3.8+ (el instalador los instala si no están)
- Claude Code instalado y autenticado

## Estructura del vault

```
_Sistema/               → Constitución, mapa, templates, skills (no modificar)
00 Operating System/    → Infraestructura: Activos + SOPs + Claude Code (memoria, convos, MCPs)
01 Growth Engine/       → Marketing (Activos+Branding+Contenido+SOPs) + Ventas (Activos+SOPs)
02 Fulfillment Engine/  → Activos + Clientes + SOPs
03 Credenciales/        → APIs, tokens, servicios (excluido de git)
```

## Creado por

[Maze Funnels](https://mazefunnels.io)
