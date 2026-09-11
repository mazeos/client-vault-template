---
name: fate-vault-guardian
description: "Reglas del Vault de Obsidian. Usar SIEMPRE al crear, editar, mover o eliminar archivos .md en el vault local. Aplica estructura, routing, nomenclatura y frontmatter. SOLO vault local Mac, NUNCA VPS/SSH/remoto."
---

# Vault Guardian

Reglas obligatorias del vault de __BUSINESS_NAME__. Leer y aplicar antes de cualquier operación sobre archivos .md.

---

## Scope de aplicación

**APLICA cuando:**
- Se crea, edita, mueve o elimina un archivo .md en el vault
- Se crea una carpeta nueva dentro del vault
- Se interactúa con el MCP de Obsidian (vault: `fate-vault`)
- Se trabaja con archivos en `__VAULT_PATH__/`

**NUNCA aplica cuando:**
- Se trabaja en VPS, servidor remoto, o cualquier conexión SSH
- El path contiene `/root/`, una IP, o está en un servidor
- Se ejecutan comandos en Docker, Portainer, o contenedores remotos

---

## Auditoría automática — ejecutar SIEMPRE al invocar este skill

Cada vez que se ejecuta este skill, realizar el siguiente barrido antes de cualquier otra acción. Reportar hallazgos al fundador con formato claro: ✅ correcto / ⚠️ advertencia / ❌ problema.

### 1. Verificar estructura raíz
```bash
ls "__VAULT_PATH__/"
```
Confirmar que solo existen estas 5 carpetas raíz: `_Sistema/`, `00 Operating System/`, `01 Growth Engine/`, `02 Fulfillment Engine/`, `03 Credenciales/`. Cualquier carpeta extra → ❌ reportar.

### 2. Verificar departamentos de Growth Engine
```bash
ls "__VAULT_PATH__/01 Growth Engine/"
```
Solo deben existir: `Marketing/`, `Ventas/`, `Growth Engine.md`. Cualquier carpeta extra → ❌ reportar.

### 3. Verificar archivos sin frontmatter
```bash
find "__VAULT_PATH__" -name "*.md" \
  -not -path "*/Conversaciones/*" -not -path "*/.trash/*" -not -path "*/.claude/*" \
  -not -name "MEMORY.md" | xargs grep -rL "^---" 2>/dev/null
```
Cualquier .md sin frontmatter YAML → ⚠️ listar y corregir.

**Exclusiones y por qué:**
- `MEMORY.md` — es el índice del sistema de memoria de Claude Code; por diseño no lleva frontmatter.
- `.claude/` — archivos de configuración, no notas del vault.
- `.trash/` — papelera de Obsidian.
- Los archivos de `00 Operating System/Activos/Memoria/` los escribe el hook `obsidian_memory_sync.py` como **copia literal** del directorio de memoria. **Nunca editarlos en el vault**: el próximo sync los pisa. Corregir siempre el archivo fuente en `__MEMORY_DIR__/`, que usa el frontmatter del sistema de memoria (`name` / `description` / `metadata.type`), no el del vault.

### 4. Verificar SOPs fuera de carpeta SOPs/
```bash
find "__VAULT_PATH__" -name "SOP - *.md" -not -path "*/SOPs/*" | grep -v Conversaciones
```
Cualquier SOP fuera de su carpeta `SOPs/` → ❌ mover al lugar correcto.

### 5. Verificar tipos de frontmatter inválidos
```bash
grep -r "^tipo:" "__VAULT_PATH__" --include="*.md" | grep -v Conversaciones | grep -vE "tipo: (sop|activo|dashboard|ficha-cliente|credencial|sistema)"
```
Tipos no reconocidos → ⚠️ corregir al tipo correcto.

### Reporte final de auditoría
Al terminar el barrido, mostrar resumen:
```
## Auditoría del Vault — [fecha]
✅ Estructura raíz: OK / ❌ Problemas: [lista]
✅ Departamentos: OK / ❌ Problemas: [lista]
✅ Frontmatter: OK / ⚠️ Sin frontmatter: [lista]
✅ SOPs en lugar correcto: OK / ❌ SOPs mal ubicados: [lista]
✅ Tipos válidos: OK / ⚠️ Tipos inválidos: [lista]
```

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
- `Marketing/` → `Activos/` + `Branding/` + `SOPs/`
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
| Credencial **del negocio** (API key, token, password propios) | `03 Credenciales/` |
| Credencial **de un cliente** (API key, token, password del cliente) | `02 Fulfillment Engine/Clientes/{Nombre}/Credenciales/` |
| Conversación de Claude Code | `00 Operating System/Claude Code/Conversaciones/` |

**Los SOPs van SIEMPRE dentro de la carpeta `SOPs/` de su sección. NUNCA sueltos ni en carpeta centralizada.**

**Credenciales — separación obligatoria:** las credenciales **del negocio** viven en `03 Credenciales/`; las credenciales **de cada cliente** viven en su propia carpeta `Credenciales/` dentro de `Clientes/{Nombre}/`. NUNCA mezclar credenciales de clientes en `03 Credenciales/`.

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

> **El vault es responsabilidad 100% de Claude Code.** Claude crea, edita y mantiene todos los archivos del vault — incluidas las credenciales. El fundador no necesita escribir manualmente; su rol es aprobar y dar contexto. Ningún permiso del vault debe bloquear a Claude para depositar o actualizar información.

| Sección | Quién escribe |
|---------|---------------|
| `_Sistema/` | Claude + fundador — *cambios a `REGLAS.md` o a los skills se confirman con el fundador antes de aplicar* |
| `00 Operating System/` | Claude + fundador |
| `01 Growth Engine/` | Claude + fundador |
| `02 Fulfillment Engine/` | Claude + fundador |
| `03 Credenciales/` | Claude + fundador — Claude deposita y actualiza credenciales (tokens, API keys, passwords) directamente |

---

## Regla 8 — Idioma obligatorio

**Todo el contenido del vault se redacta en el idioma y registro definidos en `_Sistema/REGLAS.md`** (por defecto: español neutro, tuteo, sin regionalismos). Si el negocio usa otro registro a propósito (por ejemplo, la voz de un bot o el tono de marca de un cliente), se declara en el activo correspondiente y se respeta.


## Regla 9 — Checklist post-operación

Después de CADA operación en el vault, verificar:

- [ ] El archivo tiene frontmatter YAML completo y correcto
- [ ] Está en la carpeta correcta según la tabla de routing (Regla 3)
- [ ] El nombre sigue la convención de nomenclatura (Regla 4)
- [ ] No se creó una carpeta innecesaria
- [ ] No se duplicó información (linkear con `[[]]` en vez de copiar)
- [ ] Si es SOP, sigue el formato del template `_tpl-sop.md`
- [ ] El campo `actualizado` refleja la fecha de hoy
- [ ] El texto está en español latino venezolano (Regla 8)

---

## Protocolos de expansión

### Nuevo cliente
1. Crear carpeta en `02 Fulfillment Engine/Clientes/{Nombre}/`
2. Crear `{Nombre}.md` con frontmatter: `tipo: ficha-cliente`
3. Crear su carpeta `Credenciales/` para las API keys, tokens y passwords DE ESE CLIENTE (nunca en `03 Credenciales/`, que es solo de Maze)
4. Agregar subcarpetas de contexto si aplica (planas, sin sub-niveles): `Branding/`, `Credenciales/`, etc.

### Nuevo SOP
1. Copiar `_Sistema/Templates/_tpl-sop.md`
2. Ubicar en `{Sección}/SOPs/SOP - {Titulo}.md`
3. Llenar frontmatter y seguir el formato: encabezado + cuerpo numerado + checklist

### Nuevo activo
1. Crear archivo `.md` en `{Sección}/Activos/`
2. Frontmatter: `tipo: activo`
3. Sin pasos ni procedimientos — solo información y contexto
