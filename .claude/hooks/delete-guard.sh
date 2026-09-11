#!/bin/bash
# Bloquea comandos de borrado sin confirmación explícita del usuario.
# Detecta: rm, unlink, rmdir, shred (como comandos reales, no dentro de strings o variables)

INPUT=$(cat)
CMD=$(/usr/bin/python3 -c "import sys,json; d=json.loads('''$INPUT'''.replace(\"'\", \"'\\\"'\\\"'\") if False else sys.stdin.read()); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null <<< "$INPUT" || echo "")

if echo "$CMD" | /usr/bin/grep -qE '(^|[;&|(])\s*(rm|unlink|rmdir|shred)(\s|$)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Borrado detectado (rm/unlink/rmdir/shred). Requiere autorización explícita de __FOUNDER_NAME__ antes de ejecutarse."}}'
  exit 0
fi

exit 0
