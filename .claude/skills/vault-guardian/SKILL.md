---
name: vault-guardian
description: "Guardián del vault de Obsidian. Activar SIEMPRE al crear, editar, mover o eliminar archivos .md en el vault. Aplica estructura, routing, nomenclatura y frontmatter. SOLO vault local, NUNCA VPS/SSH/remoto."
---

# Vault Guardian

Mantiene el orden del vault de Obsidian de tu negocio.

## Scope

APLICA: vault local de Obsidian, MCP obsidian local
NO APLICA: VPS, SSH, servidores remotos, Docker, IPs

## Routing crítico

| El archivo es... | Va en... |
|-----------------|----------|
| Procedimiento / "cómo hacer X" | `01 Growth Engine/{Depto}/SOPs/` |
| Dashboard de departamento | `01 Growth Engine/{Depto}/{Depto}.md` |
| Info de cliente | `02 Fulfillment Engine/{Plan}/{Cliente}/` |
| Conocimiento / framework | `01 Growth Engine/{Depto}/{Sub-tema}/` |
| Análisis de competidores | `01 Growth Engine/Marketing/Análisis de Competidores/` |
| Credencial / API key / token | `04 Credenciales/` |
| Memoria de agente | `00 Agentes/{Agente}/Memoria/` |
| Ficha de equipo | `03 Equipo/` |

**REGLA CRÍTICA: SOPs siempre en `{Depto}/SOPs/`. NO existe carpeta centralizada de SOPs.**

## Obligatorio en cada operación

1. Frontmatter YAML completo (titulo, tipo, departamento, actualizado, autor)
2. Nomenclatura correcta según tabla
3. Validar 5 pasos antes de crear carpeta nueva
4. Sin acentos en nombres de carpeta
5. Usar templates de `_Sistema/Templates/` antes de crear desde cero

## Checklist post-operación

- [ ] Frontmatter YAML completo
- [ ] Carpeta correcta según routing
- [ ] Nomenclatura correcta
- [ ] No se duplicó info (linkear con `[[]]` en vez de copiar)
- [ ] Si es SOP → está en `{Depto}/SOPs/`

[[_Sistema/REGLAS]]
