---
titulo: "Mapa del Vault"
tipo: sistema
actualizado: 2026-09-11
autor: fundador
departamento: sistema

---

# Mapa del Vault

## Estructura raíz

| Sección | Propósito | Rotación |
|---------|-----------|----------|
| `_Sistema/` | Constitución, mapa, templates, skills | Baja |
| `00 Operating System/` | Infraestructura, Claude Code, SOPs de sistema | Media |
| `01 Growth Engine/` | Marketing y Ventas | Alta |
| `02 Fulfillment Engine/` | Entrega y seguimiento de clientes | Media |
| `03 Credenciales/` | APIs, tokens, servicios propios del negocio | Baja |

## 00 Operating System

| Carpeta | Contenido |
|---------|-----------|
| `Activos/` | Documentos de infraestructura, herramientas, `Memoria/` (espejo de la memoria de Claude) |
| `SOPs/` | Procedimientos de sistema: CRM, automatización, servidor |
| `Claude Code/` | `Conversaciones/` (archivo automático por fecha) y `MCPs/` (una ficha por MCP) |

## 01 Growth Engine

| Departamento | Estructura |
|-------------|-----------|
| `Marketing/` | Activos + Branding + SOPs |
| `Ventas/` | Activos + SOPs |

## 02 Fulfillment Engine

| Carpeta | Contenido |
|---------|-----------|
| `Activos/` | Documentos de oferta, producto, roadmap (plano, sin subcarpetas) |
| `Clientes/` | Una carpeta por cliente: ficha, sesiones, `Credenciales/` del cliente |
| `SOPs/` | Onboarding, entrega, seguimiento |

## 03 Credenciales

Archivos planos por servicio: `APIs y Tokens.md`, `Servicios.md`. Solo credenciales **del negocio**; las de cada cliente viven en su carpeta dentro de `Clientes/`.

---

[[_Sistema/REGLAS]]
