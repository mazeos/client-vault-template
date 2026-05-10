#!/bin/bash
# setup.sh — Instalador completo del Vault Template (Mac/Linux)
set -e

# ── Colores ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
step() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }
ask()  { echo -e "${YELLOW}?${NC}  $1"; }

# ── Detección de OS ─────────────────────────────────────────────
OS=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
else
  err "Este script es para Mac/Linux. En Windows usa: setup.ps1"
  exit 1
fi

# ── Banner ──────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   Vault Template — Setup completo para Claude Code   ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Este instalador configura tu vault de Obsidian para trabajar"
echo "  con Claude Code: hooks, skill guardian y MCPs."
echo ""
echo -e "  Sistema detectado: ${BOLD}$(uname -s) $(uname -m)${NC}"
echo ""
read -p "  Presiona Enter para comenzar..."

# ════════════════════════════════════════════════════════════════
step "[ PASO 1 / 6 ]  Verificar prerrequisitos"
# ════════════════════════════════════════════════════════════════
echo ""

# Homebrew (solo Mac)
if [[ "$OS" == "mac" ]]; then
  if command -v brew &>/dev/null; then
    ok "Homebrew instalado ($(brew --version | head -1))"
  else
    warn "Homebrew no está instalado."
    echo "       Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Homebrew instalado"
  fi
fi

# Python 3
if command -v python3 &>/dev/null; then
  ok "Python 3 instalado ($(python3 --version))"
else
  warn "Python 3 no encontrado. Instalando..."
  if [[ "$OS" == "mac" ]]; then
    brew install python3
  else
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
  fi
  ok "Python 3 instalado"
fi

# Node.js / npm
if command -v node &>/dev/null; then
  ok "Node.js instalado ($(node --version))"
else
  warn "Node.js no encontrado. Instalando..."
  if [[ "$OS" == "mac" ]]; then
    brew install node
  else
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
  ok "Node.js instalado"
fi

# Claude Code CLI
if command -v claude &>/dev/null; then
  ok "Claude Code instalado ($(claude --version 2>/dev/null | head -1 || echo 'OK'))"
else
  warn "Claude Code no está instalado. Instalando..."
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code instalado"
fi

# ════════════════════════════════════════════════════════════════
step "[ PASO 2 / 6 ]  Información de tu negocio"
# ════════════════════════════════════════════════════════════════
echo ""

DEFAULT_VAULT="$HOME/Documents/Obsidian Vault"
ask "Ruta del vault de Obsidian [${DEFAULT_VAULT}]:"
read -p "  → " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"

ask "Nombre de tu negocio (ej: Acme Agency):"
read -p "  → " BUSINESS_NAME
while [[ -z "$BUSINESS_NAME" ]]; do
  err "El nombre del negocio no puede estar vacío."
  read -p "  → " BUSINESS_NAME
done

ask "Tu nombre (ej: Carlos):"
read -p "  → " FOUNDER_NAME
while [[ -z "$FOUNDER_NAME" ]]; do
  err "El nombre no puede estar vacío."
  read -p "  → " FOUNDER_NAME
done

echo ""
echo "  Configuración:"
echo -e "    Vault    → ${BOLD}$VAULT_PATH${NC}"
echo -e "    Negocio  → ${BOLD}$BUSINESS_NAME${NC}"
echo -e "    Fundador → ${BOLD}$FOUNDER_NAME${NC}"
echo ""
read -p "  ¿Continuar? [S/n]: " CONFIRM
CONFIRM="${CONFIRM:-S}"
if [[ "$CONFIRM" =~ ^[nN] ]]; then
  echo "  Instalación cancelada."
  exit 0
fi

# ════════════════════════════════════════════════════════════════
step "[ PASO 3 / 6 ]  Instalar vault y hooks"
# ════════════════════════════════════════════════════════════════
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar vault
echo "  Copiando estructura del vault a: $VAULT_PATH"
mkdir -p "$VAULT_PATH"
cp -r "$SCRIPT_DIR"/. "$VAULT_PATH/"
rm -f "$VAULT_PATH/setup.sh" "$VAULT_PATH/setup.ps1" "$VAULT_PATH/README.md"
ok "Estructura del vault copiada"

# Instalar hooks
echo "  Instalando hooks en ~/.claude/hooks/"
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

# Instalar skill vault-guardian
echo "  Instalando skill vault-guardian en ~/.claude/skills/"
mkdir -p ~/.claude/skills/vault-guardian
cp "$VAULT_PATH/.claude/skills/vault-guardian/SKILL.md" ~/.claude/skills/vault-guardian/SKILL.md
ok "Skill vault-guardian instalado"

# Configurar settings.json
echo "  Configurando settings.json..."
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
ok "settings.json configurado (hooks activados)"

# ════════════════════════════════════════════════════════════════
step "[ PASO 4 / 6 ]  Configurar MCPs"
# ════════════════════════════════════════════════════════════════
echo ""
echo "  Ahora configuramos los MCPs. Necesitarás tener las API Keys"
echo "  de cada servicio. Puedes saltar cualquier MCP presionando Enter"
echo "  y configurarlo manualmente después en ~/.claude.json"
echo ""

CLAUDE_JSON="$HOME/.claude.json"
[[ ! -f "$CLAUDE_JSON" ]] && echo '{}' > "$CLAUDE_JSON"

add_mcp() {
  local name="$1"
  local config="$2"
  python3 - <<PYEOF
import json
from pathlib import Path

p = Path("$CLAUDE_JSON")
c = json.loads(p.read_text())
servers = c.setdefault("mcpServers", {})
servers["$name"] = $config
p.write_text(json.dumps(c, indent=2, ensure_ascii=False))
PYEOF
}

# ── MCP: Obsidian ──────────────────────────────────────────────
echo -e "  ${BOLD}[MCP 1/9] Obsidian${NC}"
echo "  Requiere el plugin 'Local REST API' activo en Obsidian."
echo "  Para obtener la key: Obsidian → Settings → Local REST API → API Key"
echo ""
ask "API Key de Obsidian (Enter para saltar):"
read -p "  → " OBSIDIAN_KEY
if [[ -n "$OBSIDIAN_KEY" ]]; then
  add_mcp "obsidian" '{"command":"npx","args":["-y","mcp-obsidian","'"$VAULT_PATH"'"],"env":{"OBSIDIAN_API_KEY":"'"$OBSIDIAN_KEY"'"}}'
  ok "MCP Obsidian configurado"
else
  warn "MCP Obsidian omitido — configúralo después en ~/.claude.json"
fi
echo ""

# ── MCP: Google Drive / Calendar / Gmail ──────────────────────
echo -e "  ${BOLD}[MCP 2-4] Google Drive, Calendar y Gmail${NC}"
echo "  Estos MCPs usan OAuth. Para configurarlos:"
echo ""
echo "  1. Crea credenciales OAuth en Google Cloud Console:"
echo "     https://console.cloud.google.com/apis/credentials"
echo "     Tipo: Desktop app — descarga credentials.json"
echo ""
echo "  2. Instala los servidores:"
echo "     npx @modelcontextprotocol/server-gdrive --credentials ~/credentials.json"
echo "     npx @modelcontextprotocol/server-google-calendar --credentials ~/credentials.json"
echo "     npx @modelcontextprotocol/server-gmail --credentials ~/credentials.json"
echo ""
echo "  3. Agrega a ~/.claude.json bajo 'mcpServers':"
echo '     "gdrive": {"command":"npx","args":["@modelcontextprotocol/server-gdrive","--credentials","~/credentials.json"]}'
echo '     "google-calendar": {"command":"npx","args":["@modelcontextprotocol/server-google-calendar","--credentials","~/credentials.json"]}'
echo '     "gmail": {"command":"npx","args":["@modelcontextprotocol/server-gmail","--credentials","~/credentials.json"]}'
echo ""
warn "Google MCPs requieren configuración manual — instrucciones mostradas arriba"
echo ""

# ── MCP: Notion ───────────────────────────────────────────────
echo -e "  ${BOLD}[MCP 5/9] Notion${NC}"
echo "  Para obtener la API Key: https://www.notion.so/my-integrations"
echo "  Crea una integración nueva y copia el Internal Integration Secret."
echo ""
ask "Notion API Key (Enter para saltar):"
read -p "  → " NOTION_KEY
if [[ -n "$NOTION_KEY" ]]; then
  add_mcp "notion" '{"command":"npx","args":["-y","@notionhq/notion-mcp-server"],"env":{"OPENAPI_MCP_HEADERS":"{\"Authorization\":\"Bearer '"$NOTION_KEY"'\",\"Notion-Version\":\"2022-06-28\"}"}}'
  ok "MCP Notion configurado"
else
  warn "MCP Notion omitido — configúralo después en ~/.claude.json"
fi
echo ""

# ── MCP: n8n ──────────────────────────────────────────────────
echo -e "  ${BOLD}[MCP 6/9] n8n${NC}"
echo "  Requiere una instancia de n8n activa (local o en la nube)."
echo "  Para obtener la API Key: n8n → Settings → API Keys"
echo ""
ask "URL de tu instancia n8n (ej: https://n8n.tudominio.com, Enter para saltar):"
read -p "  → " N8N_URL
if [[ -n "$N8N_URL" ]]; then
  ask "n8n API Key:"
  read -p "  → " N8N_KEY
  if [[ -n "$N8N_KEY" ]]; then
    add_mcp "n8n" '{"command":"npx","args":["-y","n8n-mcp-server"],"env":{"N8N_URL":"'"$N8N_URL"'","N8N_API_KEY":"'"$N8N_KEY"'"}}'
    ok "MCP n8n configurado"
  else
    warn "API Key vacía — MCP n8n omitido"
  fi
else
  warn "MCP n8n omitido — configúralo después en ~/.claude.json"
fi
echo ""

# ── MCP: Discord ──────────────────────────────────────────────
echo -e "  ${BOLD}[MCP 7/9] Discord${NC}"
echo "  Requiere un bot de Discord con permisos de lectura/escritura."
echo "  Para crear un bot: https://discord.com/developers/applications"
echo "  Copia el Token del bot."
echo ""
ask "Discord Bot Token (Enter para saltar):"
read -p "  → " DISCORD_TOKEN
if [[ -n "$DISCORD_TOKEN" ]]; then
  add_mcp "discord" '{"command":"npx","args":["-y","@modelcontextprotocol/server-discord"],"env":{"DISCORD_TOKEN":"'"$DISCORD_TOKEN"'"}}'
  ok "MCP Discord configurado"
else
  warn "MCP Discord omitido — configúralo después en ~/.claude.json"
fi
echo ""

# ── MCP: Meta Ads ─────────────────────────────────────────────
echo -e "  ${BOLD}[MCP 8/9] Meta Ads${NC}"
echo "  Usa el MCP oficial de Meta (HTTP). Requiere:"
echo "  - Un Meta Access Token con permisos de Ads Management"
echo "  - Tu Ad Account ID (ej: act_123456789)"
echo "  Para obtener el token: https://developers.facebook.com/tools/explorer/"
echo ""
ask "Meta Access Token (Enter para saltar):"
read -p "  → " META_TOKEN
if [[ -n "$META_TOKEN" ]]; then
  ask "Ad Account ID (ej: act_123456789):"
  read -p "  → " META_ACCOUNT
  add_mcp "meta-ads" '{"type":"http","url":"https://mcp.ads.meta.com/mcp","headers":{"Authorization":"Bearer '"$META_TOKEN"'"}}'
  ok "MCP Meta Ads configurado"
  [[ -n "$META_ACCOUNT" ]] && warn "Guarda tu Ad Account ID ($META_ACCOUNT) en $VAULT_PATH/04 Credenciales/APIs y Tokens.md"
else
  warn "MCP Meta Ads omitido — configúralo después en ~/.claude.json"
fi
echo ""

# ── MCP: GoHighLevel ──────────────────────────────────────────
echo -e "  ${BOLD}[MCP 9/9] GoHighLevel (GHL)${NC}"
echo "  Este MCP requiere un servidor local. Instalación:"
echo ""
echo "  1. Clona el servidor:"
echo "     git clone https://github.com/mastanley13/ghl-mcp-server.git ~/ghl-mcp-server"
echo "     cd ~/ghl-mcp-server && npm install && npm run build"
echo ""
echo "  2. Obtén tu GHL API Key y Location ID en:"
echo "     https://marketplace.gohighlevel.com/apps/private-integrations"
echo ""
echo "  3. Agrega a ~/.claude.json:"
echo '     "ghl": {"command":"node","args":["~/ghl-mcp-server/dist/server.js"],'
echo '       "env":{"GHL_API_KEY":"tu-key","GHL_LOCATION_ID":"tu-location-id"}}'
echo ""
warn "MCP GoHighLevel requiere instalación manual — instrucciones mostradas arriba"
echo ""

# ── MCP: Higgsfield ───────────────────────────────────────────
echo -e "  ${BOLD}[EXTRA] Higgsfield CLI${NC}"
echo "  CLI para generación de video. Más info: https://higgsfield.ai"
echo ""
ask "¿Instalar Higgsfield CLI? [s/N]:"
read -p "  → " HIGGSFIELD
if [[ "$HIGGSFIELD" =~ ^[sS] ]]; then
  pip3 install higgsfield-cli 2>/dev/null || pip install higgsfield-cli 2>/dev/null
  ok "Higgsfield CLI instalado"
fi
echo ""

# ════════════════════════════════════════════════════════════════
step "[ PASO 5 / 6 ]  Configurar Obsidian"
# ════════════════════════════════════════════════════════════════
echo ""
echo "  Para que los hooks funcionen, Obsidian necesita estar abierto"
echo "  con el plugin Local REST API activo."
echo ""
echo "  Si aún no tienes Obsidian:"
if [[ "$OS" == "mac" ]]; then
  ask "¿Abrir la página de descarga de Obsidian? [s/N]:"
  read -p "  → " OPEN_OBS
  if [[ "$OPEN_OBS" =~ ^[sS] ]]; then
    open "https://obsidian.md/download"
  fi
fi
echo ""
echo "  Pasos en Obsidian después de instalar:"
echo "  1. Abre Obsidian y selecciona el vault: ${BOLD}$VAULT_PATH${NC}"
echo "  2. Ir a Settings → Community Plugins → Browse"
echo "  3. Buscar e instalar: 'Local REST API'"
echo "  4. Activarlo y copiar la API Key a:"
echo "     ${BOLD}$VAULT_PATH/04 Credenciales/APIs y Tokens.md${NC}"

# ════════════════════════════════════════════════════════════════
step "[ PASO 6 / 6 ]  Verificación final"
# ════════════════════════════════════════════════════════════════
echo ""

ERRORS=0

# Verificar hooks
for hook in session_start.py conversation_capture.py; do
  if [[ -f "$HOME/.claude/hooks/$hook" ]]; then
    ok "Hook $hook presente"
  else
    err "Hook $hook NO encontrado en ~/.claude/hooks/"
    ERRORS=$((ERRORS+1))
  fi
done

# Verificar skill
if [[ -f "$HOME/.claude/skills/vault-guardian/SKILL.md" ]]; then
  ok "Skill vault-guardian presente"
else
  err "Skill vault-guardian NO encontrado"
  ERRORS=$((ERRORS+1))
fi

# Verificar vault
if [[ -d "$VAULT_PATH/_Sistema" ]]; then
  ok "Estructura del vault copiada en $VAULT_PATH"
else
  err "Estructura del vault NO encontrada en $VAULT_PATH/_Sistema"
  ERRORS=$((ERRORS+1))
fi

# Verificar MCPs configurados
MCP_COUNT=$(python3 -c "
import json,sys
from pathlib import Path
p = Path('$CLAUDE_JSON')
if not p.exists(): print(0); sys.exit()
c = json.loads(p.read_text())
print(len(c.get('mcpServers',{})))
" 2>/dev/null || echo 0)
ok "$MCP_COUNT MCP(s) configurados en ~/.claude.json"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}${BOLD}║   ✅  Instalación completada con éxito               ║${NC}"
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
else
  echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}${BOLD}║   ⚠️   Instalación completada con $ERRORS advertencia(s)       ║${NC}"
  echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BOLD}  Próximos pasos:${NC}"
echo "  1. Abre Obsidian → apunta al vault: $VAULT_PATH"
echo "  2. Activa el plugin 'Local REST API' en Obsidian"
echo "  3. Rellena las API Keys en: $VAULT_PATH/04 Credenciales/APIs y Tokens.md"
echo "  4. Corre: ${BOLD}claude${NC}"
echo "  5. Verifica MCPs activos: ${BOLD}claude mcp list${NC}"
echo ""
echo -e "  MCPs pendientes de configuración manual:"
echo "    - Google Drive / Calendar / Gmail (OAuth)"
echo "    - GoHighLevel (servidor local)"
echo ""
echo -e "  Documentación: https://github.com/mazeos/client-vault-template"
echo ""
