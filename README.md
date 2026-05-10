# Vault Template — Negocios Digitales con Claude Code

Sistema completo de organización de negocio para Obsidian con Claude Code integrado.

## Qué incluye

| Componente | Qué hace |
|---|---|
| Estructura del vault | 6 secciones organizadas para operar tu negocio |
| Hook `SessionStart` | Claude lee tu vault al iniciar — ya sabe todo desde el primer mensaje |
| Hook `PostToolUse` | Guarda memoria en tiempo real mientras trabajas |
| Hook `Stop` | Archiva cada conversación organizada por fecha |
| Skill `vault-guardian` | Claude respeta la estructura, routing y nomenclatura del vault |

## Instalación

### Mac
```bash
curl -sSL https://raw.githubusercontent.com/mazeos/client-vault-template/main/install.sh | bash
```

### Windows (PowerShell como Administrador)
```powershell
irm https://raw.githubusercontent.com/mazeos/client-vault-template/main/install.ps1 | iex
```

## Requisitos

- Obsidian instalado con plugin **Local REST API** activo
- Claude Code instalado (`npm install -g @anthropic-ai/claude-code`)
- Node.js y Python 3.8+

## Estructura del vault

```
_Sistema/          → Reglas y templates
00 Agentes/        → Agentes IA de tu negocio
01 Growth Engine/  → Motor de crecimiento (Producto, Marketing, Publicidad, Ventas, Operaciones)
02 Fulfillment Engine/ → Seguimiento de clientes
03 Equipo/         → Fichas del equipo
04 Credenciales/   → APIs y tokens
```

## Creado por

[Maze Funnels](https://mazefunnels.io)
