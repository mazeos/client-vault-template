---
titulo: "Reglas del Vault"
tipo: sistema
actualizado: 2026-05-10
autor: fundador
---

# Reglas del Vault

> Este archivo es la constitución del vault. Todo agente o humano que opere aquí DEBE leerlo primero.

## 1. Estructura inamovible

Secciones raíz (NO crear, eliminar ni renombrar sin aprobación del fundador):
- `_Sistema/` — Reglas, mapa y templates
- `00 Agentes/` — Definiciones de agentes IA
- `01 Growth Engine/` — Motor de crecimiento (5 departamentos)
- `02 Fulfillment Engine/` — Seguimiento y entrega a clientes
- `03 Equipo/` — Fichas del equipo interno
- `04 Credenciales/` — APIs, tokens, servicios

Departamentos de `01 Growth Engine/`:
- **Producto-Oferta** — oferta, roadmap, customer journey
- **Marketing** — branding, contenido, activos, análisis
- **Publicidad** — campañas pagas, ad manager, análisis
- **Ventas** — scripts y proceso de ventas
- **Operaciones** — Producto, Tools, Infraestructura IA, Finanzas

## 2. Nomenclatura

| Tipo | Formato |
|------|---------|
| Dashboard | `{Departamento}.md` |
| SOP | `SOP - {Titulo}.md` |
| Cliente | `{Nombre}.md` |
| Análisis | `@{creador} - {Titulo}.md` |
| Agente | `Identidad.md` |
| Template | `_tpl-{tipo}.md` |

Carpetas: raíz con prefijo numérico. Sub-carpetas sin prefijo. Sin acentos en nombres de carpeta.

## 3. Frontmatter obligatorio

```yaml
---
titulo: "Nombre descriptivo"
tipo: sop | dashboard | ficha-cliente | agente | conocimiento | credencial
departamento: producto-oferta | marketing | publicidad | ventas | operaciones | fulfillment | transversal
actualizado: YYYY-MM-DD
autor: fundador | agente
---
```

## 4. Routing

- Procedimientos → `01 Growth Engine/{Depto}/SOPs/`
- Dashboard de depto → `01 Growth Engine/{Depto}/{Depto}.md`
- Cliente → `02 Fulfillment Engine/{Plan}/{Cliente}/`
- Análisis de competidores → `01 Growth Engine/Marketing/Análisis de Competidores/`
- Credenciales → `04 Credenciales/`
- Memoria de agente → `00 Agentes/{Agente}/Memoria/`

## 5. Validación antes de crear carpeta nueva

1. ¿Pertenece a un departamento existente? → va dentro
2. ¿Ya existe una carpeta donde encaja? → usar la existente
3. Justificación: "Es necesaria porque ___ y no cabe en ___ porque ___"
4. ¿Es sub-carpeta (libre) o sección raíz (requiere aprobación)?
5. Nombre sin acentos, dashboard .md creado dentro

## 6. Prohibido sin aprobación del fundador

- Crear/eliminar/renombrar sección raíz
- Crear/eliminar departamento dentro de Growth Engine
- Modificar este archivo
