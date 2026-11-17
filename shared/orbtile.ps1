# Orbtile starter script for Windows shells without sh (Codex runs hooks with cmd.exe on Windows).
# Source of truth: shared/orbtile.ps1. The Codex plugin carries an identical copy (tests check this).
# Same behaviour and wording as shared/orbtile.sh for Codex on Windows.
#
#   orbtile.ps1 codex session-start   Session-start hook: at most one line a day pointing to the Orbtile app,
#                                     nothing once the Orbtile app is installed or its Codex hooks are set up.
#   orbtile.ps1 codex status          Plain-text setup check.
#
# Reads local files only. Sends nothing anywhere. Always exits 0 so it can never block a session.

param([string]$Agent = '', [string]$Command = '')
$ErrorActionPreference = 'SilentlyContinue'
$downloadUrl = 'https://orbtile.com/download'

if ($Agent -ne 'codex' -or ($Command -ne 'session-start' -and $Command -ne 'status')) {
    [Console]::Error.WriteLine('usage: orbtile.ps1 codex session-start|status')
    exit 0
}

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$configFile = Join-Path $codexHome 'hooks.json'

# Orbtile's Codex hooks: the Windows app's helper (--orbtile-agent), or the Mac app's script name.
function Get-HookMarker {
    if (-not (Test-Path -LiteralPath $configFile)) { return '' }
    $text = Get-Content -LiteralPath $configFile -Raw
    if ($text -and $text -match 'orbtile(-[a-z]+)?-codex-hook|--orbtile-agent') { return 'Orbtile hooks' }
    return ''
}

# The Windows app keeps its data in %LOCALAPPDATA%\Orbtile.
function Get-AppPath {
    if (-not $env:LOCALAPPDATA) { return '' }
    $p = Join-Path $env:LOCALAPPDATA 'Orbtile'
    if (Test-Path -LiteralPath $p -PathType Container) { return $p }
    return ''
}

if ($Command -eq 'session-start') {
    # Orbtile follows Codex without hooks: an installed app is a set-up app.
    if ((Get-HookMarker) -or (Get-AppPath)) { exit 0 }
    # Once a day at most. Without a writable state folder it still shows (the hook runs once per new session).
    $today = [string][math]::Floor([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() / 86400)
    if ($env:PLUGIN_DATA) {
        $stateFile = Join-Path $env:PLUGIN_DATA 'last-shown-day'
        $last = Get-Content -LiteralPath $stateFile -TotalCount 1
        if ($last -eq $today) { exit 0 }
        New-Item -ItemType Directory -Force -Path $env:PLUGIN_DATA | Out-Null
        Set-Content -LiteralPath $stateFile -Value $today -Encoding ascii
    }
    $msg = "Orbtile shows your Codex sessions live on a keypad: $downloadUrl (ask Codex to check your Orbtile setup)"
    [Console]::Out.WriteLine('{"systemMessage":"' + $msg + '"}')
    exit 0
}

# status
$marker = Get-HookMarker
$app = Get-AppPath
[Console]::Out.WriteLine('Orbtile setup check for Codex')
if ($app) { [Console]::Out.WriteLine("- Orbtile app: found at $app") } else { [Console]::Out.WriteLine('- Orbtile app: not found on this computer') }
if ($marker) { [Console]::Out.WriteLine("- Orbtile's Codex hooks: on ($marker in $configFile)") }
else { [Console]::Out.WriteLine("- Orbtile's Codex hooks: off (optional: Orbtile reads Codex sessions without them)") }
if ($marker -or $app) {
    if ($marker) { [Console]::Out.WriteLine("- Note: Codex runs Orbtile's hooks only after you trust them once in /hooks (Settings > Hooks in the Codex app).") }
    [Console]::Out.WriteLine('Next step: none. Orbtile is set up; this starter plugin stays quiet and can be removed with: codex plugin remove orbtile-start@orbtile-public')
} else {
    [Console]::Out.WriteLine("Next step: download Orbtile from $downloadUrl")
}
exit 0
