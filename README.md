# Vault Template — Negocios Digitales con Claude Code

Estructura de Obsidian + Claude Code para operar tu negocio con IA.

> Para configurar el servidor, MCPs y automatizaciones → [client-vps-template](https://github.com/mazeos/client-vps-template)

## Qué incluye

| Componente | Qué hace |
|---|---|
| Estructura del vault | 6 secciones organizadas para operar tu negocio |
| Hook `SessionStart` | Claude lee tu vault al iniciar — ya sabe todo desde el primer mensaje |
| Hook `Stop` | Archiva cada conversación organizada por fecha |
| Skill `vault-guardian` | Claude respeta la estructura, routing y nomenclatura del vault |

## Instalación

### Mac / Linux
```bash
curl -sSL https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.sh | bash
```

### Windows (PowerShell como Administrador)
```powershell
irm https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.ps1 | iex
```

El instalador verifica e instala los prerrequisitos (Node.js, Python, Claude Code), copia la estructura del vault, instala los hooks y configura el skill vault-guardian.

## Requisitos

- Obsidian con plugin **Local REST API** activo
- Node.js 18+ y Python 3.8+ (el instalador los instala si no están)

## Estructura del vault

```
_Sistema/              → Reglas y templates (no modificar)
00 Agentes/            → Agentes IA de tu negocio
01 Growth Engine/      → Producto-Oferta, Marketing, Publicidad, Ventas, Operaciones
02 Fulfillment Engine/ → Seguimiento de clientes activos
03 Equipo/             → Fichas del equipo interno
04 Credenciales/       → APIs y tokens (excluido de git)
```

## Creado por

[Maze Funnels](https://mazefunnels.io)
