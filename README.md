# Vault Template — Negocios Digitales con Claude Code

Sistema completo de organización de negocio para Obsidian con Claude Code integrado.

## Qué incluye

| Componente | Qué hace |
|---|---|
| Estructura del vault | 6 secciones organizadas para operar tu negocio |
| Hook `SessionStart` | Claude lee tu vault al iniciar — ya sabe todo desde el primer mensaje |
| Hook `Stop` | Archiva cada conversación organizada por fecha |
| Skill `vault-guardian` | Claude respeta la estructura, routing y nomenclatura del vault |
| MCPs preconfigurados | Obsidian, Notion, n8n, Google Drive/Calendar/Gmail, Discord, Meta Ads, GHL |

## Instalación

El instalador detecta automáticamente Mac o Windows y guía paso a paso.

### Mac / Linux

```bash
curl -sSL https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.sh | bash
```

O si ya tienes el repo clonado:

```bash
bash setup.sh
```

### Windows (PowerShell como Administrador)

```powershell
irm https://raw.githubusercontent.com/mazeos/client-vault-template/main/setup.ps1 | iex
```

O si ya tienes el repo clonado:

```powershell
.\setup.ps1
```

## Qué hace el instalador (6 pasos)

1. **Prerrequisitos** — verifica e instala Node.js, Python 3 y Claude Code
2. **Configuración** — te pide nombre del negocio, nombre del fundador y ruta del vault
3. **Vault + hooks** — copia la estructura, instala los hooks y configura `settings.json`
4. **MCPs** — configura uno por uno los MCPs con tus API keys:
   - Obsidian (Local REST API)
   - Google Drive / Calendar / Gmail (OAuth — instrucciones manuales)
   - Notion
   - n8n
   - Discord
   - Meta Ads (HTTP oficial)
   - GoHighLevel (instrucciones manuales)
5. **Obsidian** — instrucciones para instalar el plugin Local REST API
6. **Verificación** — comprueba que todo quedó instalado correctamente

## Estructura del vault

```
_Sistema/              → Reglas y templates (no modificar)
00 Agentes/            → Agentes IA de tu negocio
01 Growth Engine/      → Motor de crecimiento
   ├── Producto-Oferta/
   ├── Marketing/
   ├── Publicidad/
   ├── Ventas/
   └── Operaciones/
02 Fulfillment Engine/ → Seguimiento de clientes activos
03 Equipo/             → Fichas del equipo interno
04 Credenciales/       → APIs y tokens (excluido de git)
```

## Requisitos

- **Obsidian** — con plugin **Local REST API** activo
- **Claude Code** — instalado automáticamente si no está presente
- **Node.js 18+** — instalado automáticamente si no está presente
- **Python 3.8+** — instalado automáticamente si no está presente

## Creado por

[Maze Funnels](https://mazefunnels.io)
