# setup.ps1 — Instalador del Vault Template (Windows)
# Ejecutar como Administrador

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

function Ok($msg)   { Write-Host "OK  $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "!   $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "X   $msg" -ForegroundColor Red }
function Step($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Ask($msg)  { Write-Host "?   $msg" -ForegroundColor Yellow }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Err "Ejecuta PowerShell como Administrador (click derecho -> Ejecutar como administrador)"
    exit 1
}

Clear-Host
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Vault Template - Setup para Claude Code        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Configura tu vault de Obsidian con Claude Code:"
Write-Host "  estructura, 5 hooks de sesion, skill y MCP de Obsidian."
Write-Host ""
Read-Host "  Presiona Enter para comenzar"

# ================================================================
Step "[ PASO 1 / 5 ]  Verificar prerrequisitos"
# ================================================================
Write-Host ""

if (Get-Command python -ErrorAction SilentlyContinue) {
    Ok "Python ($(python --version 2>&1))"
} else {
    Warn "Python no encontrado. Instalando..."
    winget install --id Python.Python.3 -e --accept-source-agreements --accept-package-agreements
    Ok "Python instalado"
}

if (Get-Command node -ErrorAction SilentlyContinue) {
    Ok "Node.js ($(node --version))"
} else {
    Warn "Node.js no encontrado. Instalando..."
    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    $env:PATH += ";$env:ProgramFiles\nodejs"
    Ok "Node.js instalado - reinicia la terminal si hay errores"
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Ok "Claude Code instalado"
} else {
    Err "Claude Code no esta instalado."
    Write-Host "  Instalalo primero corriendo el setup del VPS template:"
    Write-Host "  -> https://github.com/mazeos/client-vps-template"
    exit 1
}

$PyCmd = "python"

# ================================================================
Step "[ PASO 2 / 5 ]  Informacion de tu negocio"
# ================================================================
Write-Host ""

$DefaultVault = "$env:USERPROFILE\Documents\Obsidian Vault"
Ask "Ruta del vault [$DefaultVault]:"
$VaultPath = Read-Host "  -> "
if ([string]::IsNullOrWhiteSpace($VaultPath)) { $VaultPath = $DefaultVault }

Ask "Nombre de tu negocio:"
$BusinessName = Read-Host "  -> "
while ([string]::IsNullOrWhiteSpace($BusinessName)) {
    Err "No puede estar vacio."
    $BusinessName = Read-Host "  -> "
}

Ask "Tu nombre (fundador):"
$FounderName = Read-Host "  -> "
while ([string]::IsNullOrWhiteSpace($FounderName)) {
    Err "No puede estar vacio."
    $FounderName = Read-Host "  -> "
}

Ask "Nombre del vault en Obsidian (el que aparece arriba a la izquierda):"
$VaultName = Read-Host "  -> "
while ([string]::IsNullOrWhiteSpace($VaultName)) {
    Err "No puede estar vacio."
    $VaultName = Read-Host "  -> "
}

Ask "API Key del plugin 'Local REST API' de Obsidian:"
Write-Host "  (Obsidian -> Settings -> Community Plugins -> Local REST API)" -ForegroundColor Gray
$ApiKey = Read-Host "  -> "
while ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Err "No puede estar vacio. Instala el plugin 'Local REST API' primero."
    $ApiKey = Read-Host "  -> "
}

Write-Host ""
Write-Host "  Vault    -> $VaultPath"
Write-Host "  Negocio  -> $BusinessName"
Write-Host "  Fundador -> $FounderName"
Write-Host "  MCP name -> $VaultName"
Write-Host ""
Ask "Continuar? [S/n]:"
$Confirm = Read-Host "  -> "
if ($Confirm -match "^[nN]") { Write-Host "  Cancelado."; exit 0 }

# -- Detectar rutas de Claude Code --
$Username = $env:USERNAME
$MemoryDir = "$env:USERPROFILE\.claude\projects\-C-Users-$Username\memory"
New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null
$VaultPathFwd = $VaultPath.Replace("\", "/")
$MemoryDirFwd = $MemoryDir.Replace("\", "/")

# ================================================================
Step "[ PASO 3 / 5 ]  Instalar vault, hooks y skill"
# ================================================================
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $VaultPath)) { New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null }
Copy-Item "$ScriptDir\*" $VaultPath -Recurse -Force
Remove-Item "$VaultPath\setup.sh"  -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\setup.ps1" -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\README.md" -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\.git" -Recurse -Force -ErrorAction SilentlyContinue
Ok "Estructura del vault copiada en $VaultPath"

# -- Personalizador (reemplaza placeholders) --
function Personalizar($file) {
    if (-not (Test-Path $file)) { return }
    $c = Get-Content $file -Raw
    $c = $c.Replace("__VAULT_PATH__", $VaultPathFwd)
    $c = $c.Replace("__BUSINESS_NAME__", $BusinessName)
    $c = $c.Replace("__FOUNDER_NAME__", $FounderName)
    $c = $c.Replace("__VAULT_NAME__", $VaultName)
    $c = $c.Replace("__MEMORY_DIR__", $MemoryDirFwd)
    $c | Set-Content $file -Encoding UTF8 -NoNewline
}

Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\\.git\\" } | ForEach-Object {
    Personalizar $_.FullName
}
Ok "Placeholders reemplazados en el vault"

# -- Instalar hooks --
$HooksDir = "$env:USERPROFILE\.claude\hooks"
New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null
foreach ($hook in @("obsidian_start_hook.py", "obsidian_memory_sync.py", "obsidian_hook.py", "conversation_capture.py", "delete-guard.sh")) {
    Copy-Item "$VaultPath\.claude\hooks\$hook" "$HooksDir\$hook" -Force
    Personalizar "$HooksDir\$hook"
}
Ok "Hooks instalados (5)"

# -- Instalar skill --
$SkillDir = "$env:USERPROFILE\.claude\skills\fate-vault-guardian"
New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
Copy-Item "$VaultPath\.claude\skills\fate-vault-guardian\SKILL.md" "$SkillDir\SKILL.md" -Force
Personalizar "$SkillDir\SKILL.md"
Ok "Skill fate-vault-guardian instalado"

# -- Configurar settings.json --
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
if (-not (Test-Path $SettingsPath)) { '{}' | Set-Content $SettingsPath -Encoding UTF8 }
$pyPath = (Get-Command python).Source
$SettingsScript = @"
import json, sys
settings_path, hd, py = sys.argv[1], sys.argv[2], sys.argv[3]
with open(settings_path, encoding='utf-8') as f:
    s = json.load(f)
h = s.setdefault('hooks', {})
h['SessionStart'] = [{'hooks': [{'type': 'command', 'command': py + ' ' + hd + '\\\\obsidian_start_hook.py', 'timeout': 30, 'statusMessage': 'Cargando contexto desde vault...'}]}]
h['PostToolUse']  = [{'matcher': 'Write|Edit', 'hooks': [{'type': 'command', 'command': py + ' ' + hd + '\\\\obsidian_memory_sync.py', 'timeout': 10}]}]
h['Stop']         = [{'hooks': [{'type': 'command', 'command': py + ' ' + hd + '\\\\conversation_capture.py', 'timeout': 15}]}]
h['SessionEnd']   = [{'hooks': [{'type': 'command', 'command': py + ' ' + hd + '\\\\obsidian_hook.py', 'timeout': 30, 'statusMessage': 'Guardando en vault...'}]}]
with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
"@
& $PyCmd -c $SettingsScript $SettingsPath $HooksDir $pyPath
Ok "settings.json configurado (nota: delete-guard requiere bash; opcional en Windows)"

# -- Configurar MCP de Obsidian --
$ClaudeJson = "$env:USERPROFILE\.claude.json"
if (-not (Test-Path $ClaudeJson)) { '{"mcpServers": {}}' | Set-Content $ClaudeJson -Encoding UTF8 }
$McpScript = @"
import json, sys
path, api_key = sys.argv[1], sys.argv[2]
with open(path, encoding='utf-8') as f:
    c = json.load(f)
c.setdefault('mcpServers', {})
if 'obsidian' not in c['mcpServers']:
    c['mcpServers']['obsidian'] = {
        'command': 'npx',
        'args': ['-y', 'mcp-obsidian'],
        'env': {'OBSIDIAN_API_KEY': api_key, 'OBSIDIAN_HOST': '127.0.0.1', 'OBSIDIAN_PORT': '27123'}
    }
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(c, f, indent=2, ensure_ascii=False)
"@
& $PyCmd -c $McpScript $ClaudeJson $ApiKey
Ok "MCP de Obsidian configurado en .claude.json"

# ================================================================
Step "[ PASO 4 / 5 ]  Verificacion final"
# ================================================================
Write-Host ""

$errors = 0
foreach ($hook in @("obsidian_start_hook.py", "obsidian_memory_sync.py", "obsidian_hook.py", "conversation_capture.py")) {
    if (Test-Path "$HooksDir\$hook") { Ok "Hook $hook" } else { Err "Hook $hook no encontrado"; $errors++ }
}
if (Test-Path "$SkillDir\SKILL.md") { Ok "Skill fate-vault-guardian" } else { Err "Skill no encontrado"; $errors++ }
if (Test-Path "$VaultPath\_Sistema") { Ok "Vault en $VaultPath" } else { Err "Vault incompleto"; $errors++ }

# ================================================================
Step "[ PASO 5 / 5 ]  Resumen"
# ================================================================
Write-Host ""
if ($errors -eq 0) {
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "   OK  Vault instalado correctamente              " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
} else {
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "   !   Completado con $errors error(s)                   " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Proximos pasos:" -ForegroundColor White
Write-Host "  1. Abre Obsidian -> vault: $VaultPath"
Write-Host "  2. Settings -> Community Plugins -> verifica 'Local REST API' activo"
Write-Host "  3. Corre: cd `$HOME && claude"
Write-Host ""
Write-Host "  Para configurar el servidor y los MCPs:"
Write-Host "  -> https://github.com/mazeos/client-vps-template"
Write-Host ""
