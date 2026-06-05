#!/bin/bash
# Bloquea comandos de borrado sin confirmación explícita del usuario.
# Detecta: rm, unlink, rmdir, shred (como comandos reales, no dentro de strings o variables)

INPUT=$(cat)
CMD=$(/usr/bin/python3 -c "import sys,json; d=json.loads('''$INPUT'''.replace(\"'\", \"'\\\"'\\\"'\") if False else sys.stdin.read()); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null <<< "$INPUT" || echo "")

if echo "$CMD" | /usr/bin/grep -qE '(^|[;&|(])\s*(rm|unlink|rmdir|shred)(\s|$)'; then
  printf '{"continue":false,"stopReason":"BORRADO BLOQUEADO: el comando contiene rm/unlink/rmdir/shred. __FOUNDER_NAME__ debe aprobar este borrado manualmente antes de ejecutarlo."}'
  exit 0
fi

exit 0
