# Instrucciones para Claude Code — __BUSINESS_NAME__

## Identidad
- Fundador: __FOUNDER_NAME__
- Negocio: __BUSINESS_NAME__
- Idioma: español (responder siempre en español salvo que el fundador escriba en otro idioma)

## El vault — cerebro permanente

El vault de Obsidian en `__VAULT_PATH__` es la fuente de verdad de todo el contexto del negocio, para humanos y para agentes de IA.

### Acceso
- **MCP de Obsidian** (vault: `__VAULT_NAME__`) — método preferido para crear, editar, mover y buscar notas
- **Filesystem directo** (`__VAULT_PATH__`) — para lo que el MCP no soporte

### Guardián del vault — APLICAR SIEMPRE
Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault, **leer y aplicar el skill `fate-vault-guardian`** (`~/.claude/skills/fate-vault-guardian/SKILL.md`). Contiene las reglas obligatorias: estructura, routing, nomenclatura, frontmatter, permisos y validación de carpetas. La constitución completa está en `_Sistema/REGLAS.md`.

**El guardián aplica SOLO al vault local. NUNCA a servidores, SSH, Docker ni rutas remotas.**

### Estructura
```
_Sistema/               → Constitución, mapa, templates, skills
00 Operating System/    → Infraestructura: Activos + SOPs + Claude Code
01 Growth Engine/       → Marketing (Activos+Branding+SOPs) + Ventas (Activos+SOPs)
02 Fulfillment Engine/  → Activos + Clientes + SOPs
03 Credenciales/        → APIs, tokens, servicios del negocio
```

### Reglas críticas (resumen)
- **SOPs SIEMPRE dentro de su departamento**: `01 Growth Engine/{Depto}/SOPs/` — nunca en una carpeta centralizada
- **Nomenclatura**: SOPs = `SOP - {Titulo}.md` | Dashboards = `{Depto}.md` | Análisis = `@{creador} - {Titulo}.md`
- **Frontmatter YAML obligatorio** en cada archivo .md
- **Las 5 secciones raíz no se tocan** sin aprobación del fundador
- **Validar 5 pasos** antes de crear cualquier carpeta nueva
- **Cero sermón**: el vault resuelve, no opina. Las observaciones van en el chat

### Cuándo actualizar el vault durante una conversación
- **Clientes** (`02 Fulfillment Engine/Clientes/{Nombre}/`): cuando se menciona una sesión, decisión, tarea, avance, bloqueo o cambio de situación → actualizar su ficha
- **Credenciales** (`03 Credenciales/` o `Clientes/{Nombre}/Credenciales/`): cuando aparece o cambia un token, API key, dominio o servicio → actualizar al momento
- **SOPs** (`{Sección}/SOPs/`): cuando se documenta un proceso nuevo → crear `SOP - {Titulo}.md`
- **MCPs** (`00 Operating System/Claude Code/MCPs/`): cuando se agrega o elimina un MCP → una ficha por MCP

**Regla general:** si en la conversación surge información que no está en el vault o contradice lo que hay, actualizarlo en el momento, no al final. No esperar a que el fundador lo pida.

## Memoria interna
Usar el sistema de memoria de Claude Code (`__MEMORY_DIR__`) para guardar decisiones del negocio, feedback sobre cómo trabajar con el fundador, estado de proyectos y referencias a sistemas externos. El hook de `PostToolUse` sincroniza esos archivos al vault automáticamente (`00 Operating System/Activos/Memoria/`). **Nunca editar la copia del vault**: se pisa en cada sync; corregir siempre el archivo fuente.

## Comportamiento general
- Respuestas cortas y directas, sin relleno
- Verificar el estado real de los archivos antes de suponer
- Ante una tarea ambigua, hacer UNA pregunta concreta, no varias
- Pedir OK antes de acciones difíciles de revertir (borrar, publicar, enviar mensajes)
