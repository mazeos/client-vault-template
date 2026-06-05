---
titulo: "Reglas del Vault"
tipo: sistema
actualizado: 2026-06-05
autor: fundador
---

# Reglas del Vault

> Este archivo es la constitución del vault. Todo agente o humano que opere aquí DEBE leerlo primero.

## 1. Estructura inamovible

Secciones raíz (NO crear, eliminar ni renombrar sin aprobación del fundador):

| Sección | Propósito |
|---------|-----------|
| `_Sistema/` | Constitución, mapa, templates, skills del vault |
| `00 Operating System/` | Infraestructura operativa: Claude Code, SOPs de sistema, activos internos |
| `01 Growth Engine/` | Motor de crecimiento — Marketing y Ventas |
| `02 Fulfillment Engine/` | Entrega y seguimiento de clientes |
| `03 Credenciales/` | APIs, tokens, servicios, MCPs |

### Estructura interna de cada sección

**`00 Operating System/`**
- `Activos/` — documentos informativos de la infraestructura
- `SOPs/` — procedimientos operativos del sistema
- `Claude Code/` — conversaciones, MCPs, contexto de Claude

**`01 Growth Engine/`**
- `Marketing/` → `Activos/` + `Branding/` + `Contenido/` + `SOPs/`
- `Ventas/` → `Activos/` + `SOPs/`

**`02 Fulfillment Engine/`**
- `Activos/` — documentos de oferta y producto (plano, sin subcarpetas)
- `Clientes/` — una carpeta por cliente
- `SOPs/` — procedimientos de entrega y onboarding

**`03 Credenciales/`** — archivos planos de credenciales por servicio

## 2. Definición de tipos de documento

### Activo
Documento **informativo**. Almacena conocimiento, contexto, referencias o datos del área. **No contiene pasos ni procedimientos.** Ejemplos: banco de ángulos, documentos de oferta, fichas de herramientas, diagnósticos, blueprints.

### SOP
Documento **procedimental**. Define cómo ejecutar un proceso de forma estandarizada. Sigue el template `_tpl-sop.md` obligatoriamente:
- Encabezado con Objetivo + Tiempo estimado + Requisitos previos
- Cuerpo con secciones numeradas y emojis
- Checklist final si aplica
- Verbos en imperativo: "Haz clic", "Ingresa", "Selecciona"

Si un documento no tiene pasos accionables → es un Activo, no un SOP.

## 3. Nomenclatura

| Tipo | Formato |
|------|---------|
| SOP | `SOP - {Titulo}.md` |
| Dashboard de depto | `{Depto}.md` |
| Ficha de cliente | `{Nombre}.md` |
| Análisis de contenido | `@{creador} - {Titulo}.md` |
| Template | `_tpl-{tipo}.md` |

Carpetas: raíz con prefijo numérico. Subcarpetas SIN prefijo. Sin acentos en nombres de carpeta. Prefijo `_` solo para sistema.

## 4. Frontmatter obligatorio

```yaml
---
titulo: "Nombre descriptivo"
tipo: sop | activo | dashboard | ficha-cliente | credencial
departamento: marketing | ventas | operating-system | fulfillment | sistema
actualizado: YYYY-MM-DD
autor: fundador | agente
---
```

## 5. Reglas de escritura

1. Un tema por archivo (máx. 300 líneas — si crece, dividir)
2. Links internos con `[[Nombre]]` — todo archivo debe tener al menos 1 link salvo índices
3. Sin duplicación — linkear, NUNCA copiar
4. Máximo H3 (3 niveles de heading)
5. Dashboards usan tablas de estado

## 6. Routing

| Si necesitas guardar... | Va en... |
|------------------------|----------|
| Un procedimiento accionable | `{Sección}/SOPs/SOP - {Titulo}.md` |
| Información/contexto/conocimiento | `{Sección}/Activos/` |
| Ficha de cliente | `02 Fulfillment Engine/Clientes/{Nombre}/` |
| Credencial, API key, token, password | `03 Credenciales/` — NUNCA en otro lugar |
| Conversación de Claude Code | `00 Operating System/Claude Code/Conversaciones/` |

**Regla de SOPs:** siempre dentro de la carpeta `SOPs/` de su sección. NUNCA sueltos ni en carpeta centralizada entre secciones.

## 7. Validación (5 pasos antes de crear carpeta nueva)

1. **Pertenencia** → ¿Pertenece a una sección existente? Si sí, va dentro
2. **Existencia** → ¿Ya hay carpeta para esto? Usar la existente
3. **Justificación** → "Es necesaria porque ___ y no cabe en ___ porque ___"
4. **Nivel** → Subcarpeta (libre) vs. sección raíz (requiere aprobación del fundador)
5. **Consistencia** → Sin acentos en el nombre, dashboard creado si aplica

## 8. Prohibido sin aprobación del fundador

- Crear, eliminar o renombrar sección raíz (00–03)
- Crear o eliminar departamentos dentro de Growth Engine
- Modificar `REGLAS.md` o `MAPA.md`
- Mover credenciales fuera de `03 Credenciales/`
