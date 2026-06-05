#!/bin/bash
# setup.sh — Instalador del Vault Template (Mac/Linux)
set -e

# ── Colores ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }
ask()  { echo -e "${YELLOW}?${NC}  $1"; }

# ── Detección de OS ─────────────────────────────────────────────
if [[ "$OSTYPE" != "darwin"* && "$OSTYPE" != "linux-gnu"* ]]; then
  err "Este script es para Mac/Linux. En Windows usa: setup.ps1"
  exit 1
fi

# ── Banner ──────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   Vault Template — Setup para Claude Code        ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Configura tu vault de Obsidian con Claude Code:"
echo "  estructura, 5 hooks de sesión, skill y MCP de Obsidian."
echo ""
read -p "  Presiona Enter para comenzar..."

# ════════════════════════════════════════════════════════════════
step "[ PASO 1 / 5 ]  Verificar prerrequisitos"
# ════════════════════════════════════════════════════════════════
echo ""

if [[ "$OSTYPE" == "darwin"* ]] && ! command -v brew &>/dev/null; then
  warn "Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Homebrew instalado"
fi

if command -v python3 &>/dev/null; then
  ok "Python 3 ($(python3 --version))"
else
  warn "Python 3 no encontrado. Instalando..."
  [[ "$OSTYPE" == "darwin"* ]] && brew install python3 || sudo apt-get install -y python3
  ok "Python 3 instalado"
fi

if command -v node &>/dev/null; then
  ok "Node.js ($(node --version))"
else
  warn "Node.js no encontrado. Instalando..."
  [[ "$OSTYPE" == "darwin"* ]] && brew install node || { curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs; }
  ok "Node.js instalado"
fi

if command -v claude &>/dev/null; then
  ok "Claude Code instalado"
else
  err "Claude Code no está instalado."
  echo "  Instálalo primero corriendo el setup del VPS template:"
  echo "  → https://github.com/mazeos/client-vps-template"
  exit 1
fi

# ════════════════════════════════════════════════════════════════
step "[ PASO 2 / 5 ]  Información de tu negocio"
# ════════════════════════════════════════════════════════════════
echo ""

DEFAULT_VAULT="$HOME/Documents/Obsidian Vault"
ask "Ruta del vault de Obsidian [${DEFAULT_VAULT}]:"
read -p "  → " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"

ask "Nombre de tu negocio:"
read -p "  → " BUSINESS_NAME
while [[ -z "$BUSINESS_NAME" ]]; do
  err "No puede estar vacío."; read -p "  → " BUSINESS_NAME
done

ask "Tu nombre (fundador):"
read -p "  → " FOUNDER_NAME
while [[ -z "$FOUNDER_NAME" ]]; do
  err "No puede estar vacío."; read -p "  → " FOUNDER_NAME
done

ask "Nombre del vault en Obsidian (el que aparece arriba a la izquierda):"
read -p "  → " VAULT_NAME
while [[ -z "$VAULT_NAME" ]]; do
  err "No puede estar vacío."; read -p "  → " VAULT_NAME
done

ask "API Key del plugin 'Local REST API' de Obsidian:"
echo "  (Obsidian → Settings → Community Plugins → Local REST API → API Key)"
read -p "  → " OBSIDIAN_API_KEY
while [[ -z "$OBSIDIAN_API_KEY" ]]; do
  err "No puede estar vacío. Instala el plugin 'Local REST API' primero."
  read -p "  → " OBSIDIAN_API_KEY
done

echo ""
echo -e "  Vault    → ${BOLD}$VAULT_PATH${NC}"
echo -e "  Negocio  → ${BOLD}$BUSINESS_NAME${NC}"
echo -e "  Fundador → ${BOLD}$FOUNDER_NAME${NC}"
echo -e "  MCP name → ${BOLD}$VAULT_NAME${NC}"
echo ""
read -p "  ¿Continuar? [S/n]: " CONFIRM
[[ "${CONFIRM:-S}" =~ ^[nN] ]] && echo "  Cancelado." && exit 0

# ── Detectar rutas de Claude Code ───────────────────────────────
USERNAME=$(whoami)
MEMORY_DIR="$HOME/.claude/projects/-Users-${USERNAME}/memory"
mkdir -p "$MEMORY_DIR"

# Rutas con / para usar dentro de archivos
VAULT_PATH_FWD="$VAULT_PATH"
MEMORY_DIR_FWD="$MEMORY_DIR"

# ════════════════════════════════════════════════════════════════
step "[ PASO 3 / 5 ]  Instalar vault, hooks y skill"
# ════════════════════════════════════════════════════════════════
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -- Copiar estructura del vault --
mkdir -p "$VAULT_PATH"
cp -R "$SCRIPT_DIR"/. "$VAULT_PATH/"
rm -f "$VAULT_PATH/setup.sh" "$VAULT_PATH/setup.ps1" "$VAULT_PATH/README.md"
rm -rf "$VAULT_PATH/.git"
ok "Estructura del vault copiada en $VAULT_PATH"

# -- Personalizador: reemplaza placeholders en todos los .md, .py y .sh --
personalizar() {
  python3 - "$1" "$VAULT_PATH_FWD" "$BUSINESS_NAME" "$FOUNDER_NAME" "$VAULT_NAME" "$MEMORY_DIR_FWD" <<'PYEOF'
import sys
archivo, vault, negocio, fundador, vault_name, memory = sys.argv[1:7]
try:
    with open(archivo, encoding="utf-8") as f:
        c = f.read()
except Exception:
    sys.exit(0)
c = (c.replace("__VAULT_PATH__", vault)
      .replace("__BUSINESS_NAME__", negocio)
      .replace("__FOUNDER_NAME__", fundador)
      .replace("__VAULT_NAME__", vault_name)
      .replace("__MEMORY_DIR__", memory))
with open(archivo, "w", encoding="utf-8") as f:
    f.write(c)
PYEOF
}

# Personalizar todos los .md del vault (incluye .claude/CLAUDE.md)
find "$VAULT_PATH" -type f -name "*.md" -not -path "*/.git/*" | while read -r f; do
  personalizar "$f"
done
ok "Placeholders reemplazados en el vault"

# -- Instalar hooks en ~/.claude/hooks --
mkdir -p ~/.claude/hooks
HOOKS_PY="obsidian_start_hook.py obsidian_memory_sync.py obsidian_hook.py conversation_capture.py"
for hook in $HOOKS_PY; do
  cp "$VAULT_PATH/.claude/hooks/$hook" ~/.claude/hooks/$hook
  personalizar ~/.claude/hooks/$hook
  chmod +x ~/.claude/hooks/$hook
done
cp "$VAULT_PATH/.claude/hooks/delete-guard.sh" ~/.claude/hooks/delete-guard.sh
personalizar ~/.claude/hooks/delete-guard.sh
chmod +x ~/.claude/hooks/delete-guard.sh
ok "Hooks instalados (5): start, memory_sync, session_end, conversation_capture, delete-guard"

# -- Instalar skill --
mkdir -p ~/.claude/skills/fate-vault-guardian
cp "$VAULT_PATH/.claude/skills/fate-vault-guardian/SKILL.md" ~/.claude/skills/fate-vault-guardian/SKILL.md
personalizar ~/.claude/skills/fate-vault-guardian/SKILL.md
ok "Skill fate-vault-guardian instalado"

# -- Configurar settings.json --
SETTINGS=~/.claude/settings.json
[[ ! -f "$SETTINGS" ]] && echo '{}' > "$SETTINGS"
python3 - "$SETTINGS" "$HOME" <<'PYEOF'
import json, sys
settings_path, home = sys.argv[1], sys.argv[2]
hooks_dir = f"{home}/.claude/hooks"
py = "/usr/bin/python3"
with open(settings_path, encoding="utf-8") as f:
    s = json.load(f)
h = s.setdefault("hooks", {})
h["SessionStart"] = [{"hooks": [{"type": "command", "command": f"{py} {hooks_dir}/obsidian_start_hook.py", "timeout": 30, "statusMessage": "Cargando contexto desde vault..."}]}]
h["PostToolUse"]  = [{"matcher": "Write|Edit", "hooks": [{"type": "command", "command": f"{py} {hooks_dir}/obsidian_memory_sync.py", "timeout": 10}]}]
h["Stop"]         = [{"hooks": [{"type": "command", "command": f"{py} {hooks_dir}/conversation_capture.py", "timeout": 15}]}]
h["SessionEnd"]   = [{"hooks": [{"type": "command", "command": f"{py} {hooks_dir}/obsidian_hook.py", "timeout": 30, "statusMessage": "Guardando en vault..."}]}]
h["PreToolUse"]   = [{"matcher": "Bash", "hooks": [{"type": "command", "command": f"bash {hooks_dir}/delete-guard.sh"}]}]
with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
PYEOF
ok "settings.json configurado (5 eventos)"

# -- Configurar MCP de Obsidian en ~/.claude.json --
CLAUDE_JSON="$HOME/.claude.json"
[[ ! -f "$CLAUDE_JSON" ]] && echo '{"mcpServers": {}}' > "$CLAUDE_JSON"
python3 - "$CLAUDE_JSON" "$OBSIDIAN_API_KEY" <<'PYEOF'
import json, sys
path, api_key = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    c = json.load(f)
c.setdefault("mcpServers", {})
if "obsidian" not in c["mcpServers"]:
    c["mcpServers"]["obsidian"] = {
        "command": "npx",
        "args": ["-y", "mcp-obsidian"],
        "env": {
            "OBSIDIAN_API_KEY": api_key,
            "OBSIDIAN_HOST": "127.0.0.1",
            "OBSIDIAN_PORT": "27123"
        }
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(c, f, indent=2, ensure_ascii=False)
    print("nuevo")
else:
    print("existe")
PYEOF
ok "MCP de Obsidian configurado en ~/.claude.json"

# ════════════════════════════════════════════════════════════════
step "[ PASO 4 / 5 ]  Verificación final"
# ════════════════════════════════════════════════════════════════
echo ""

ERRORS=0
for hook in obsidian_start_hook.py obsidian_memory_sync.py obsidian_hook.py conversation_capture.py delete-guard.sh; do
  [[ -f "$HOME/.claude/hooks/$hook" ]] && ok "Hook $hook" || { err "Hook $hook no encontrado"; ERRORS=$((ERRORS+1)); }
done
[[ -f "$HOME/.claude/skills/fate-vault-guardian/SKILL.md" ]] && ok "Skill fate-vault-guardian" || { err "Skill no encontrado"; ERRORS=$((ERRORS+1)); }
[[ -d "$VAULT_PATH/_Sistema" ]] && ok "Vault en $VAULT_PATH" || { err "Vault incompleto"; ERRORS=$((ERRORS+1)); }

# Verificar que no quedaron placeholders sin reemplazar en los hooks
if grep -rl "__VAULT_PATH__\|__MEMORY_DIR__\|__FOUNDER_NAME__" "$HOME/.claude/hooks/" &>/dev/null; then
  err "Quedaron placeholders sin reemplazar en los hooks"
  ERRORS=$((ERRORS+1))
else
  ok "Hooks sin placeholders pendientes"
fi

# ════════════════════════════════════════════════════════════════
step "[ PASO 5 / 5 ]  Resumen"
# ════════════════════════════════════════════════════════════════
echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}${BOLD}║   ✅  Vault instalado correctamente              ║${NC}"
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
else
  echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}${BOLD}║   ⚠️   Completado con $ERRORS error(s)                    ║${NC}"
  echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BOLD}  Próximos pasos:${NC}"
echo "  1. Abre Obsidian → vault: $VAULT_PATH"
echo "  2. Settings → Community Plugins → verifica que 'Local REST API' esté activo"
echo "  3. Corre:  cd ~ && claude"
echo "  4. Debe aparecer: 'Cargando contexto desde vault...'"
echo ""
echo "  Para configurar el servidor y los MCPs de marketing:"
echo "  → https://github.com/mazeos/client-vps-template"
echo ""
