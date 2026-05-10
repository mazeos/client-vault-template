# setup.ps1 — Instalador del Vault Template (Windows)
# Ejecutar como Administrador

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

function Ok($msg)   { Write-Host "✓  $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "⚠  $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "✗  $msg" -ForegroundColor Red }
function Step($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Ask($msg)  { Write-Host "?  $msg" -ForegroundColor Yellow }

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Err "Ejecuta PowerShell como Administrador (click derecho → Ejecutar como administrador)"
    exit 1
}

Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Vault Template — Setup para Claude Code        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Configura tu vault de Obsidian con Claude Code:"
Write-Host "  hooks de sesión y skill vault-guardian."
Write-Host ""
Read-Host "  Presiona Enter para comenzar"

# ════════════════════════════════════════════════════════════════
Step "[ PASO 1 / 4 ]  Verificar prerrequisitos"
# ════════════════════════════════════════════════════════════════
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
    Ok "Node.js instalado — reinicia la terminal si hay errores"
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Ok "Claude Code instalado"
} else {
    Err "Claude Code no está instalado."
    Write-Host "  Instálalo primero corriendo el setup del VPS template:"
    Write-Host "  → https://github.com/mazeos/client-vps-template"
    exit 1
}

# ════════════════════════════════════════════════════════════════
Step "[ PASO 2 / 4 ]  Información de tu negocio"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$DefaultVault = "$env:USERPROFILE\Documents\Obsidian Vault"
Ask "Ruta del vault [$DefaultVault]:"
$VaultPath = Read-Host "  → "
if ([string]::IsNullOrWhiteSpace($VaultPath)) { $VaultPath = $DefaultVault }

Ask "Nombre de tu negocio:"
$BusinessName = Read-Host "  → "
while ([string]::IsNullOrWhiteSpace($BusinessName)) {
    Err "No puede estar vacío."
    $BusinessName = Read-Host "  → "
}

Ask "Tu nombre (fundador):"
$FounderName = Read-Host "  → "
while ([string]::IsNullOrWhiteSpace($FounderName)) {
    Err "No puede estar vacío."
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
Step "[ PASO 3 / 4 ]  Instalar vault, hooks y skill"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $VaultPath)) { New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null }
Copy-Item "$ScriptDir\*" $VaultPath -Recurse -Force
Remove-Item "$VaultPath\setup.sh"  -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\setup.ps1" -ErrorAction SilentlyContinue
Remove-Item "$VaultPath\README.md" -ErrorAction SilentlyContinue
Ok "Estructura del vault copiada en $VaultPath"

$HooksDir = "$env:USERPROFILE\.claude\hooks"
New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null

foreach ($hook in @("session_start.py", "conversation_capture.py")) {
    $content = Get-Content "$VaultPath\.claude\hooks\$hook" -Raw
    $content = $content.Replace("__VAULT_PATH__", $VaultPath.Replace("\", "/"))
    $content = $content.Replace("__BUSINESS_NAME__", $BusinessName)
    $content = $content.Replace("__FOUNDER_NAME__", $FounderName)
    $content | Set-Content "$HooksDir\$hook" -Encoding UTF8
}
Ok "Hooks instalados"

$SkillDir = "$env:USERPROFILE\.claude\skills\vault-guardian"
New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
Copy-Item "$VaultPath\.claude\skills\vault-guardian\SKILL.md" "$SkillDir\SKILL.md" -Force
Ok "Skill vault-guardian instalado"

$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
if (-not (Test-Path $SettingsPath)) { '{}' | Set-Content $SettingsPath -Encoding UTF8 }
$s = Get-Content $SettingsPath -Raw | ConvertFrom-Json
if (-not $s.hooks) { $s | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{}) }
$pyPath = (Get-Command python).Source
$s.hooks | Add-Member -MemberType NoteProperty -Name "SessionStart" -Value @([PSCustomObject]@{ hooks = @([PSCustomObject]@{ type="command"; command="$pyPath $HooksDir\session_start.py" }) }) -Force
$s.hooks | Add-Member -MemberType NoteProperty -Name "Stop" -Value @([PSCustomObject]@{ hooks = @([PSCustomObject]@{ type="command"; command="$pyPath $HooksDir\conversation_capture.py" }) }) -Force
$s | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
Ok "settings.json configurado"

# ════════════════════════════════════════════════════════════════
Step "[ PASO 4 / 4 ]  Verificación final"
# ════════════════════════════════════════════════════════════════
Write-Host ""

$errors = 0
foreach ($hook in @("session_start.py", "conversation_capture.py")) {
    if (Test-Path "$HooksDir\$hook") { Ok "Hook $hook" } else { Err "Hook $hook no encontrado"; $errors++ }
}
if (Test-Path "$env:USERPROFILE\.claude\skills\vault-guardian\SKILL.md") { Ok "Skill vault-guardian" } else { Err "Skill no encontrado"; $errors++ }
if (Test-Path "$VaultPath\_Sistema") { Ok "Vault en $VaultPath" } else { Err "Vault incompleto"; $errors++ }

Write-Host ""
if ($errors -eq 0) {
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✅  Vault instalado correctamente              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║   ⚠️   Completado con $errors error(s)                   ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Próximos pasos:" -ForegroundColor White
Write-Host "  1. Abre Obsidian → vault: $VaultPath"
Write-Host "  2. Settings → Community Plugins → instala 'Local REST API'"
Write-Host "  3. Corre: claude"
Write-Host ""
Write-Host "  Para configurar el servidor y los MCPs:"
Write-Host "  → https://github.com/mazeos/client-vps-template"
Write-Host ""
