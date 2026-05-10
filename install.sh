#!/bin/bash
# install.sh — Vault Template Setup para Mac
set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Vault Template — Claude Code Setup     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Preguntas ───────────────────────────────────────────────
DEFAULT_VAULT="$HOME/Documents/Obsidian Vault"
read -p "📁 Ruta del vault [$DEFAULT_VAULT]: " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"

read -p "🏢 Nombre de tu negocio: " BUSINESS_NAME
read -p "👤 Tu nombre (fundador): " FOUNDER_NAME
read -p "🔑 API Key del plugin Local REST API de Obsidian: " OBSIDIAN_KEY

# ── 2. Copiar vault al destino ─────────────────────────────────
echo ""
echo "📦 Copiando estructura del vault a: $VAULT_PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$VAULT_PATH"
cp -r "$SCRIPT_DIR"/. "$VAULT_PATH/"
rm -f "$VAULT_PATH/install.sh" "$VAULT_PATH/install.ps1" "$VAULT_PATH/README.md"

# ── 3. Instalar hooks de Claude Code ──────────────────────────
echo "🔧 Instalando hooks en ~/.claude/hooks/"
mkdir -p ~/.claude/hooks

for hook in session_start.py conversation_capture.py; do
  sed \
    -e "s|__VAULT_PATH__|$VAULT_PATH|g" \
    -e "s|__BUSINESS_NAME__|$BUSINESS_NAME|g" \
    -e "s|__FOUNDER_NAME__|$FOUNDER_NAME|g" \
    "$VAULT_PATH/.claude/hooks/$hook" > ~/.claude/hooks/$hook
done

# ── 4. Instalar skill vault-guardian ──────────────────────────
echo "🛡️  Instalando skill vault-guardian en ~/.claude/skills/"
mkdir -p ~/.claude/skills/vault-guardian
cp "$VAULT_PATH/.claude/skills/vault-guardian/SKILL.md" ~/.claude/skills/vault-guardian/SKILL.md

# ── 5. Configurar settings.json ───────────────────────────────
echo "⚙️  Configurando hooks en ~/.claude/settings.json"
SETTINGS=~/.claude/settings.json

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

python3 - <<EOF
import json, sys
from pathlib import Path

settings_path = Path("$SETTINGS")
settings = json.loads(settings_path.read_text())

hooks = settings.setdefault("hooks", {})

hooks["SessionStart"] = [{"hooks": [{"type": "command", "command": "/usr/bin/python3 $HOME/.claude/hooks/session_start.py"}]}]
hooks["Stop"] = [{"hooks": [{"type": "command", "command": "/usr/bin/python3 $HOME/.claude/hooks/conversation_capture.py"}]}]

settings_path.write_text(json.dumps(settings, indent=2, ensure_ascii=False))
print("✅ settings.json actualizado")
EOF

# ── 6. Configurar MCP de Obsidian ─────────────────────────────
echo "🔌 Configurando MCP de Obsidian en ~/.claude.json"
python3 - <<EOF
import json
from pathlib import Path

claude_json = Path("$HOME/.claude.json")
config = json.loads(claude_json.read_text()) if claude_json.exists() else {}

mcp_servers = config.setdefault("mcpServers", {})
mcp_servers["obsidian"] = {
    "command": "npx",
    "args": ["-y", "mcp-obsidian", "$VAULT_PATH"],
    "env": {"OBSIDIAN_API_KEY": "$OBSIDIAN_KEY"}
}

claude_json.write_text(json.dumps(config, indent=2, ensure_ascii=False))
print("✅ MCP de Obsidian configurado")
EOF

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✅ Instalación completa                ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Próximos pasos:"
echo "  1. Abre Obsidian y apunta al vault: $VAULT_PATH"
echo "  2. Activa el plugin Local REST API en Obsidian"
echo "  3. Corre: claude"
echo ""
