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
echo "  hooks de sesión y skill vault-guardian."
echo ""
read -p "  Presiona Enter para comenzar..."

# ════════════════════════════════════════════════════════════════
step "[ PASO 1 / 4 ]  Verificar prerrequisitos"
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
step "[ PASO 2 / 4 ]  Información de tu negocio"
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

echo ""
echo -e "  Vault    → ${BOLD}$VAULT_PATH${NC}"
echo -e "  Negocio  → ${BOLD}$BUSINESS_NAME${NC}"
echo -e "  Fundador → ${BOLD}$FOUNDER_NAME${NC}"
echo ""
read -p "  ¿Continuar? [S/n]: " CONFIRM
[[ "${CONFIRM:-S}" =~ ^[nN] ]] && echo "  Cancelado." && exit 0

# ════════════════════════════════════════════════════════════════
step "[ PASO 3 / 4 ]  Instalar vault, hooks y skill"
# ════════════════════════════════════════════════════════════════
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$VAULT_PATH"
cp -r "$SCRIPT_DIR"/. "$VAULT_PATH/"
rm -f "$VAULT_PATH/setup.sh" "$VAULT_PATH/setup.ps1" "$VAULT_PATH/README.md"
ok "Estructura del vault copiada en $VAULT_PATH"

mkdir -p ~/.claude/hooks
for hook in session_start.py conversation_capture.py; do
  sed \
    -e "s|__VAULT_PATH__|$VAULT_PATH|g" \
    -e "s|__BUSINESS_NAME__|$BUSINESS_NAME|g" \
    -e "s|__FOUNDER_NAME__|$FOUNDER_NAME|g" \
    "$VAULT_PATH/.claude/hooks/$hook" > ~/.claude/hooks/$hook
  chmod +x ~/.claude/hooks/$hook
done
ok "Hooks instalados (session_start.py, conversation_capture.py)"

mkdir -p ~/.claude/skills/vault-guardian
cp "$VAULT_PATH/.claude/skills/vault-guardian/SKILL.md" ~/.claude/skills/vault-guardian/SKILL.md
ok "Skill vault-guardian instalado"

SETTINGS=~/.claude/settings.json
[[ ! -f "$SETTINGS" ]] && echo '{}' > "$SETTINGS"
python3 - <<PYEOF
import json
from pathlib import Path
p = Path("$SETTINGS")
s = json.loads(p.read_text())
h = s.setdefault("hooks", {})
h["SessionStart"] = [{"hooks": [{"type": "command", "command": "/usr/bin/python3 $HOME/.claude/hooks/session_start.py"}]}]
h["Stop"]         = [{"hooks": [{"type": "command", "command": "/usr/bin/python3 $HOME/.claude/hooks/conversation_capture.py"}]}]
p.write_text(json.dumps(s, indent=2, ensure_ascii=False))
PYEOF
ok "settings.json configurado"

# ════════════════════════════════════════════════════════════════
step "[ PASO 4 / 4 ]  Verificación final"
# ════════════════════════════════════════════════════════════════
echo ""

ERRORS=0
for hook in session_start.py conversation_capture.py; do
  [[ -f "$HOME/.claude/hooks/$hook" ]] && ok "Hook $hook" || { err "Hook $hook no encontrado"; ERRORS=$((ERRORS+1)); }
done
[[ -f "$HOME/.claude/skills/vault-guardian/SKILL.md" ]] && ok "Skill vault-guardian" || { err "Skill no encontrado"; ERRORS=$((ERRORS+1)); }
[[ -d "$VAULT_PATH/_Sistema" ]] && ok "Vault en $VAULT_PATH" || { err "Vault incompleto"; ERRORS=$((ERRORS+1)); }

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
echo "  2. Settings → Community Plugins → instala 'Local REST API'"
echo "  3. Corre: claude"
echo ""
echo "  Para configurar el servidor y los MCPs:"
echo "  → https://github.com/mazeos/client-vps-template"
echo ""
