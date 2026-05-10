# setup.ps1 — Instalador completo del Vault Template (Windows)
# Requiere PowerShell 5.1+ y ejecutar como Administrador

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ── Helpers ─────────────────────────────────────────────────────
function Ok($msg)   { Write-Host "✓  $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "⚠  $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "✗  $msg" -ForegroundColor Red }
function Step($msg) { Write-Host "`n$msg" -ForegroundColor Cyan -NoNewline; Write-Host "" }
function Ask($msg)  { Write-Host "?  $msg" -ForegroundColor Yellow }

function Add-Mcp($Name, $Config) {
    $claudeJson = "$env:USERPROFILE\.claude.json"
    if (-not (Test-Path $claudeJson)) { '{}' | Set-Content $claudeJson -Encoding UTF8 }
    $c = Get-Content $claudeJson -Raw | ConvertFrom-Json
    if (-not $c.mcpServers) { $c | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{}) }
    $c.mcpServers | Add-Member -MemberType NoteProperty -Name $Name -Value $Config -Force
    $c | ConvertTo-Json -Depth 10 | Set-Content $claudeJson -Encoding UTF8
}

# ── Verificar administrador ──────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Err "Ejecuta PowerShell como Administrador."
    Err "Click derecho en PowerShell → Ejecutar como administrador"
    exit 1
}

# ── Banner ──────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   Vault Template — Setup completo para Claude Code   ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "  Sistema detectado: Windows $([System.Environment]::OSVersion.Version)"
Write-Host ""
Read-Host "  Presiona Enter para comenzar"

# ════════════════════════════════════════════════════════════════
Step "[ PASO 1 / 6 ]  Verificar prerrequisitos"
# ════════════════════════════════════════════════════════════════
Write-Host ""

# Winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Ok "winget disponible"
} else {
    Warn "winget no disponible. Instala 'App Installer' desde la Microsoft Store."
}

# Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    Ok "Python instalado ($(python --version 2>&1))"
} else {
    Warn "Python no encontrado. Instalando via winget..."
    winget install --id Python.Python.3 -e --accept-source-agreements --accept-package-agreements
    Ok "Python instalado"
}

# Node.js / npm
if (Get-Command node -ErrorAction SilentlyContinue) {
    Ok "Node.js instalado ($(node --version))"
} else {
    Warn "Node.js no encontrado. Instalando via winget..."
    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    $env:PATH += ";$env:ProgramFiles\nodejs"
    Ok "Node.js instalado — reinicia la terminal si hay errores después"
}

# Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Ok "Claude Code instalado"
} else {
    Warn "Claude Code no encontrado. Instalando..."
    npm install -g "@anthropic-ai/claude-code"
    Ok "Claude Code instalado"
}

# Git (para clonar MCPs locales)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok "Git instalado ($(git --version))"
} else {
    Warn "Git no encontrado. Instalando via winget..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    Ok "Git instalado"
}

# ════════════════════════════════════════════════════════════════
Step "[ PASO 2 / 6 ]  Información de tu negocio"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$DefaultVault = "$env:USERPROFILE\Documents\Obsidian Vault"
Ask "Ruta del vault de Obsidian [$DefaultVault]:"
$VaultPath = Read-Host "  → "
if ([string]::IsNullOrWhiteSpace($VaultPath)) { $VaultPath = $DefaultVault }

Ask "Nombre de tu negocio (ej: Acme Agency):"
$BusinessName = Read-Host "  → "
while ([string]::IsNullOrWhiteSpace($BusinessName)) {
    Err "El nombre no puede estar vacío."
    $BusinessName = Read-Host "  → "
}

Ask "Tu nombre (ej: Carlos):"
$FounderName = Read-Host "  → "
while ([string]::IsNullOrWhiteSpace($FounderName)) {
    Err "El nombre no puede estar vacío."
    $FounderName = Read-Host "  → "
}

Write-Host ""
Write-Host "  Vault    → $VaultPath"
Write-Host "  Negocio  → $BusinessName"
Write-Host "  Fundador → $FounderName"
Write-Host ""
Ask "¿Continuar? [S/n]:"
$Confirm = Read-Host "  → "
if ($Confirm -match "^[nN]") { Write-Host "  Cancelado."; exit 0 }

# ════════════════════════════════════════════════════════════════
Step "[ PASO 3 / 6 ]  Instalar vault y hooks"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Copiar vault
Write-Host "  Copiando estructura del vault..."
if (-not (Test-Path $VaultPath)) { New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null }
Copy-Item "$ScriptDir\*" $VaultPath -Recurse -Force
Remove-Item "$VaultPath\setup.sh" -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\setup.ps1" -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\README.md" -ErrorAction SilentlyContinue
Ok "Estructura del vault copiada"

# Instalar hooks
$HooksDir = "$env:USERPROFILE\.claude\hooks"
New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null

foreach ($hook in @("session_start.py", "conversation_capture.py")) {
    $content = Get-Content "$VaultPath\.claude\hooks\$hook" -Raw
    $content = $content.Replace("__VAULT_PATH__", $VaultPath.Replace("\", "/"))
    $content = $content.Replace("__BUSINESS_NAME__", $BusinessName)
    $content = $content.Replace("__FOUNDER_NAME__", $FounderName)
    $content | Set-Content "$HooksDir\$hook" -Encoding UTF8
}
Ok "Hooks instalados (session_start.py, conversation_capture.py)"

# Instalar skill vault-guardian
$SkillDir = "$env:USERPROFILE\.claude\skills\vault-guardian"
New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
Copy-Item "$VaultPath\.claude\skills\vault-guardian\SKILL.md" "$SkillDir\SKILL.md" -Force
Ok "Skill vault-guardian instalado"

# Configurar settings.json
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
if (-not (Test-Path $SettingsPath)) { '{}' | Set-Content $SettingsPath -Encoding UTF8 }

$settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
if (-not $settings.hooks) { $settings | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{}) }

$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
$sessionHook = [PSCustomObject]@{
    hooks = @([PSCustomObject]@{ type = "command"; command = "$pythonPath $HooksDir\session_start.py" })
}
$stopHook = [PSCustomObject]@{
    hooks = @([PSCustomObject]@{ type = "command"; command = "$pythonPath $HooksDir\conversation_capture.py" })
}
$settings.hooks | Add-Member -MemberType NoteProperty -Name "SessionStart" -Value @($sessionHook) -Force
$settings.hooks | Add-Member -MemberType NoteProperty -Name "Stop" -Value @($stopHook) -Force
$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
Ok "settings.json configurado (hooks activados)"

# ════════════════════════════════════════════════════════════════
Step "[ PASO 4 / 6 ]  Configurar MCPs"
# ════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  Configura los MCPs uno por uno. Presiona Enter para saltar"
Write-Host "  cualquiera y configurarlo manualmente después en ~/.claude.json"
Write-Host ""

$ClaudeJson = "$env:USERPROFILE\.claude.json"
if (-not (Test-Path $ClaudeJson)) { '{}' | Set-Content $ClaudeJson -Encoding UTF8 }

# ── MCP: Obsidian ─────────────────────────────────────────────
Write-Host "  [MCP 1/9] Obsidian" -ForegroundColor White
Write-Host "  Plugin requerido: 'Local REST API' en Obsidian"
Write-Host "  Ruta: Obsidian → Settings → Local REST API → API Key"
Write-Host ""
Ask "API Key de Obsidian (Enter para saltar):"
$ObsidianKey = Read-Host "  → "
if ($ObsidianKey) {
    $vaultPathFwd = $VaultPath.Replace("\", "/")
    Add-Mcp "obsidian" ([PSCustomObject]@{
        command = "npx"
        args = @("-y", "mcp-obsidian", $vaultPathFwd)
        env = [PSCustomObject]@{ OBSIDIAN_API_KEY = $ObsidianKey }
    })
    Ok "MCP Obsidian configurado"
} else { Warn "MCP Obsidian omitido" }
Write-Host ""

# ── MCP: Google (OAuth) ────────────────────────────────────────
Write-Host "  [MCP 2-4] Google Drive, Calendar y Gmail" -ForegroundColor White
Write-Host "  Requieren OAuth. Pasos:"
Write-Host "  1. Crea credenciales OAuth en: https://console.cloud.google.com/apis/credentials"
Write-Host "  2. Tipo: Desktop app — descarga credentials.json"
Write-Host "  3. Instala los servidores MCP y agrega a ~/.claude.json manualmente"
Write-Host ""
Warn "Google MCPs requieren configuración manual"
Write-Host ""

# ── MCP: Notion ───────────────────────────────────────────────
Write-Host "  [MCP 5/9] Notion" -ForegroundColor White
Write-Host "  Obtén la API Key en: https://www.notion.so/my-integrations"
Write-Host ""
Ask "Notion API Key (Enter para saltar):"
$NotionKey = Read-Host "  → "
if ($NotionKey) {
    $headers = "{`"Authorization`":`"Bearer $NotionKey`",`"Notion-Version`":`"2022-06-28`"}"
    Add-Mcp "notion" ([PSCustomObject]@{
        command = "npx"
        args = @("-y", "@notionhq/notion-mcp-server")
        env = [PSCustomObject]@{ OPENAPI_MCP_HEADERS = $headers }
    })
    Ok "MCP Notion configurado"
} else { Warn "MCP Notion omitido" }
Write-Host ""

# ── MCP: n8n ──────────────────────────────────────────────────
Write-Host "  [MCP 6/9] n8n" -ForegroundColor White
Write-Host "  API Key en: n8n → Settings → API Keys"
Write-Host ""
Ask "URL de tu instancia n8n (Enter para saltar):"
$N8nUrl = Read-Host "  → "
if ($N8nUrl) {
    Ask "n8n API Key:"
    $N8nKey = Read-Host "  → "
    if ($N8nKey) {
        Add-Mcp "n8n" ([PSCustomObject]@{
            command = "npx"
            args = @("-y", "n8n-mcp-server")
            env = [PSCustomObject]@{ N8N_URL = $N8nUrl; N8N_API_KEY = $N8nKey }
        })
        Ok "MCP n8n configurado"
    } else { Warn "API Key vacía — MCP n8n omitido" }
} else { Warn "MCP n8n omitido" }
Write-Host ""

# ── MCP: Discord ──────────────────────────────────────────────
Write-Host "  [MCP 7/9] Discord" -ForegroundColor White
Write-Host "  Crea un bot en: https://discord.com/developers/applications"
Write-Host ""
Ask "Discord Bot Token (Enter para saltar):"
$DiscordToken = Read-Host "  → "
if ($DiscordToken) {
    Add-Mcp "discord" ([PSCustomObject]@{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-discord")
        env = [PSCustomObject]@{ DISCORD_TOKEN = $DiscordToken }
    })
    Ok "MCP Discord configurado"
} else { Warn "MCP Discord omitido" }
Write-Host ""

# ── MCP: Meta Ads ─────────────────────────────────────────────
Write-Host "  [MCP 8/9] Meta Ads" -ForegroundColor White
Write-Host "  Obtén un Access Token en: https://developers.facebook.com/tools/explorer/"
Write-Host ""
Ask "Meta Access Token (Enter para saltar):"
$MetaToken = Read-Host "  → "
if ($MetaToken) {
    Ask "Ad Account ID (ej: act_123456789):"
    $MetaAccount = Read-Host "  → "
    Add-Mcp "meta-ads" ([PSCustomObject]@{
        type = "http"
        url = "https://mcp.ads.meta.com/mcp"
        headers = [PSCustomObject]@{ Authorization = "Bearer $MetaToken" }
    })
    Ok "MCP Meta Ads configurado"
} else { Warn "MCP Meta Ads omitido" }
Write-Host ""

# ── MCP: GoHighLevel ──────────────────────────────────────────
Write-Host "  [MCP 9/9] GoHighLevel (GHL)" -ForegroundColor White
Write-Host "  Requiere instalación manual del servidor local:"
Write-Host "  git clone https://github.com/mastanley13/ghl-mcp-server.git ~/ghl-mcp-server"
Write-Host "  cd ~/ghl-mcp-server && npm install && npm run build"
Write-Host ""
Warn "MCP GoHighLevel requiere instalación manual"
Write-Host ""

# ════════════════════════════════════════════════════════════════
Step "[ PASO 5 / 6 ]  Configurar Obsidian"
# ════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  Pasos en Obsidian:"
Write-Host "  1. Abre Obsidian y selecciona el vault: $VaultPath"
Write-Host "  2. Settings → Community Plugins → Browse"
Write-Host "  3. Busca e instala: 'Local REST API'"
Write-Host "  4. Actívalo y copia la API Key"
Write-Host ""

Ask "¿Abrir Obsidian ahora? [s/N]:"
$OpenObs = Read-Host "  → "
if ($OpenObs -match "^[sS]") {
    if (Get-Command obsidian -ErrorAction SilentlyContinue) {
        Start-Process obsidian
    } else {
        Start-Process "https://obsidian.md/download"
    }
}

# ════════════════════════════════════════════════════════════════
Step "[ PASO 6 / 6 ]  Verificación final"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$errors = 0

foreach ($hook in @("session_start.py", "conversation_capture.py")) {
    if (Test-Path "$HooksDir\$hook") { Ok "Hook $hook presente" }
    else { Err "Hook $hook NO encontrado"; $errors++ }
}

if (Test-Path "$env:USERPROFILE\.claude\skills\vault-guardian\SKILL.md") {
    Ok "Skill vault-guardian presente"
} else { Err "Skill vault-guardian NO encontrado"; $errors++ }

if (Test-Path "$VaultPath\_Sistema") {
    Ok "Estructura del vault copiada en $VaultPath"
} else { Err "Estructura del vault incompleta"; $errors++ }

$mcpCount = 0
if (Test-Path $ClaudeJson) {
    $cfg = Get-Content $ClaudeJson -Raw | ConvertFrom-Json
    if ($cfg.mcpServers) {
        $mcpCount = ($cfg.mcpServers | Get-Member -MemberType NoteProperty).Count
    }
}
Ok "$mcpCount MCP(s) configurados en ~/.claude.json"

Write-Host ""
if ($errors -eq 0) {
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✅  Instalación completada con éxito               ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║   ⚠️   Completado con $errors advertencia(s)                  ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Próximos pasos:" -ForegroundColor White
Write-Host "  1. Abre Obsidian → vault: $VaultPath"
Write-Host "  2. Activa el plugin 'Local REST API'"
Write-Host "  3. Rellena APIs en: $VaultPath\04 Credenciales\APIs y Tokens.md"
Write-Host "  4. Corre: claude"
Write-Host "  5. Verifica MCPs: claude mcp list"
Write-Host ""
Write-Host "  MCPs pendientes de configuración manual:"
Write-Host "    - Google Drive / Calendar / Gmail (OAuth)"
Write-Host "    - GoHighLevel (servidor local)"
Write-Host ""
Write-Host "  Documentación: https://github.com/mazeos/client-vault-template"
Write-Host ""
