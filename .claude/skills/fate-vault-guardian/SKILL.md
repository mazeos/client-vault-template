---
name: fate-vault-guardian
description: "Reglas del vault de Obsidian. Usar SIEMPRE al crear, editar, mover o eliminar archivos .md en el vault local. Aplica estructura, routing, nomenclatura y frontmatter. SOLO vault local, NUNCA VPS/SSH/remoto."
---

# Vault Guardian

Reglas obligatorias del vault de __BUSINESS_NAME__. Leer y aplicar antes de cualquier operación sobre archivos .md.

---

## Scope de aplicación

**APLICA cuando:**
- Se crea, edita, mueve o elimina un archivo .md en el vault
- Se crea una carpeta nueva dentro del vault
- Se interactúa con el MCP de Obsidian (vault: `__VAULT_NAME__`)
- Se trabaja con archivos en `__VAULT_PATH__/`

**NUNCA aplica cuando:**
- Se trabaja en VPS, servidor remoto, o cualquier conexión SSH
- El path contiene `/root/`, una IP, o está en un servidor
- Se ejecutan comandos en Docker, Portainer, o contenedores remotos

---

## Regla 0 — Leer antes de actuar

Antes de escribir CUALQUIER cosa en el vault, leer `_Sistema/REGLAS.md`. Es la constitución del vault y tiene prioridad absoluta.

---

## Regla 1 — Estructura inamovible

Estas 5 secciones raíz NO se crean, eliminan ni renombran sin aprobación explícita del fundador:

```
_Sistema/
00 Operating System/
01 Growth Engine/
02 Fulfillment Engine/
03 Credenciales/
```

### Estructura interna de cada sección

**`00 Operating System/`** → `Activos/` + `SOPs/` + `Claude Code/`

**`01 Growth Engine/`** → solo 2 departamentos:
- `Marketing/` → `Activos/` + `Branding/` + `Contenido/` + `SOPs/`
- `Ventas/` → `Activos/` + `SOPs/`

**`02 Fulfillment Engine/`** → `Activos/` + `Clientes/` + `SOPs/`

**`03 Credenciales/`** → archivos planos de credenciales por servicio

**Si algún comando intenta crear una sección raíz nueva o un departamento no listado, RECHAZAR y notificar al fundador.**

---

## Regla 2 — Tipos de documento

### Activo
Documento **informativo**. Almacena conocimiento, contexto, referencias o datos. **No contiene pasos ni procedimientos.** Tipo en frontmatter: `activo`.

### SOP
Documento **procedimental**. Define cómo ejecutar un proceso de forma estandarizada. Tipo en frontmatter: `sop`. Sigue el template `_tpl-sop.md` obligatoriamente:
- Encabezado: `# SOP: {Nombre}` + **Objetivo** + **Tiempo estimado** + **Requisitos previos**
- Cuerpo: secciones numeradas con emojis, pasos en imperativo
- Checklist final si aplica

**Si el documento no tiene pasos accionables → es Activo, no SOP.**

---

## Regla 3 — Routing obligatorio

Antes de crear un archivo, determinar dónde va:

| El archivo es... | Va en... |
|----------------|----------|
| Un procedimiento "cómo hacer X" | `{Sección}/SOPs/SOP - {Titulo}.md` |
| Información, contexto, conocimiento | `{Sección}/Activos/` |
| Dashboard de un departamento | `01 Growth Engine/{Depto}/{Depto}.md` |
| Ficha de un cliente | `02 Fulfillment Engine/Clientes/{Nombre}/` |
| Credencial, API key, token, password | `03 Credenciales/` — NUNCA en otro lugar |
| Conversación de Claude Code | `00 Operating System/Claude Code/Conversaciones/` |

**Los SOPs van SIEMPRE dentro de la carpeta `SOPs/` de su sección. NUNCA sueltos ni en carpeta centralizada.**

---

## Regla 4 — Nomenclatura

| Tipo | Formato |
|------|---------|
| SOP | `SOP - {Titulo descriptivo}.md` |
| Dashboard de depto | `{Departamento}.md` |
| Ficha de cliente | `{Nombre Cliente}.md` |
| Análisis de contenido externo | `@{creador} - {Titulo corto}.md` |
| Template | `_tpl-{tipo}.md` |

**Carpetas:** raíz con prefijo numérico (`00`, `01`...). Subcarpetas SIN prefijo. Sin acentos en nombres de carpeta. Prefijo `_` solo para sistema.

---

## Regla 5 — Frontmatter obligatorio

Todo archivo .md creado en el vault DEBE tener frontmatter YAML:

```yaml
---
titulo: "Nombre descriptivo"
tipo: sop | activo | dashboard | ficha-cliente | credencial
departamento: marketing | ventas | operating-system | fulfillment | sistema
actualizado: YYYY-MM-DD
autor: fundador | agente
---
```

**Al editar un archivo existente, SIEMPRE actualizar el campo `actualizado` con la fecha del día.**

---

## Regla 6 — Validación antes de crear carpeta nueva (5 pasos)

1. **Pertenencia** — ¿Pertenece a una sección existente? Si sí, va dentro.
2. **Existencia** — ¿Ya existe una carpeta donde esto encaja? Usar la existente.
3. **Justificación** — "Esta carpeta es necesaria porque ___ y no puede vivir dentro de ___ porque ___".
4. **Nivel** — Subcarpeta (libre) vs. sección raíz (requiere aprobación del fundador).
5. **Consistencia** — Nombre sin acentos, dashboard creado si aplica.

---

## Regla 7 — Permisos

| Sección | Quién escribe |
|---------|---------------|
| `_Sistema/` | Solo el fundador |
| `00 Operating System/` | Claude + fundador |
| `01 Growth Engine/` | Claude + fundador |
| `02 Fulfillment Engine/` | Claude + fundador |
| `03 Credenciales/` | Solo el fundador |

---

## Regla 8 — Checklist post-operación

Después de CADA operación en el vault, verificar:

- [ ] El archivo tiene frontmatter YAML completo y correcto
- [ ] Está en la carpeta correcta según la tabla de routing (Regla 3)
- [ ] El nombre sigue la convención de nomenclatura (Regla 4)
- [ ] No se creó una carpeta innecesaria
- [ ] No se duplicó información (linkear con `[[]]` en vez de copiar)
- [ ] Si es SOP, sigue el formato del template `_tpl-sop.md`
- [ ] El campo `actualizado` refleja la fecha de hoy

---

## Protocolos de expansión

### Nuevo cliente
1. Crear carpeta en `02 Fulfillment Engine/Clientes/{Nombre}/`
2. Crear `{Nombre}.md` con frontmatter: `tipo: ficha-cliente`
3. Agregar subcarpetas de contexto si aplica (planas, sin sub-niveles)

### Nuevo SOP
1. Copiar `_Sistema/Templates/_tpl-sop.md`
2. Ubicar en `{Sección}/SOPs/SOP - {Titulo}.md`
3. Llenar frontmatter y seguir el formato: encabezado + cuerpo numerado + checklist

### Nuevo activo
1. Crear archivo `.md` en `{Sección}/Activos/`
2. Frontmatter: `tipo: activo`
3. Sin pasos ni procedimientos — solo información y contexto
