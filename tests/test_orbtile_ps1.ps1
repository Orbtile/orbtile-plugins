# Tests for shared/orbtile.ps1 (Windows). Runs in temp folders only; never reads your real settings.
# Usage (Windows): powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_orbtile_ps1.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$script = Join-Path $here 'shared\orbtile.ps1'
$dl = 'https://orbtile.com/download'
$script:pass = 0; $script:fail = 0
function Ok { $script:pass++ }
function Bad([string]$m) { $script:fail++; Write-Output "FAIL $m" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("orbtile-ps1-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

# Run the script in a child PowerShell with a clean CODEX_HOME, LOCALAPPDATA and PLUGIN_DATA for <name>.
function Run([string]$name, [string]$hooks, [string]$command = 'session-start', [switch]$app) {
    $d = Join-Path $tmp $name
    foreach ($sub in 'codex', 'local', 'data') { New-Item -ItemType Directory -Force -Path (Join-Path $d $sub) | Out-Null }
    if ($hooks) { Set-Content -LiteralPath (Join-Path $d 'codex\hooks.json') -Value $hooks -Encoding ascii }
    if ($app) { New-Item -ItemType Directory -Force -Path (Join-Path $d 'local\Orbtile') | Out-Null }
    $saved = @{ CODEX_HOME = $env:CODEX_HOME; LOCALAPPDATA = $env:LOCALAPPDATA; PLUGIN_DATA = $env:PLUGIN_DATA }
    $env:CODEX_HOME = Join-Path $d 'codex'; $env:LOCALAPPDATA = Join-Path $d 'local'; $env:PLUGIN_DATA = Join-Path $d 'data'
    try { $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File $script codex $command | Out-String).Trim(); $code = $LASTEXITCODE }
    finally { foreach ($k in $saved.Keys) { Set-Item -Path "env:$k" -Value $saved[$k] } }
    if ($code -ne 0) { Bad "$name exit code $code" }
    return $out
}

function ExpectSilent([string]$name, [string]$out) { if ($out -eq '') { Ok } else { Bad "${name}: expected silence, got: $out" } }
function ExpectMessage([string]$name, [string]$out, [string]$needle) {
    try { $j = $out | ConvertFrom-Json } catch { Bad "${name}: not JSON: $out"; return }
    $keys = @($j.PSObject.Properties.Name)
    if ($keys.Count -eq 1 -and $keys[0] -eq 'systemMessage' -and $j.systemMessage.Contains($needle)) { Ok } else { Bad "${name}: expected a systemMessage with '$needle', got: $out" }
}

$macHooks = '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"\"/Users/u/Library/Application Support/Orbtile/bin/orbtile-codex-hook\" SessionStart"}]}]}}'
$winHooks = '{"hooks":{"Stop":[{"hooks":[{"type":"process","command":"C:/Program Files/Orbtile/Orbtile.HookHelper.exe","args":["--orbtile-agent","codex","--event","Stop"]}]}]}}'
$otherHooks = '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"notify.exe Stop"}]}]}}'

# session-start
$first = Run 'no-app' ''
ExpectMessage 'no-app' $first $dl
$expected = '{"systemMessage":"Orbtile shows your Codex sessions live on a keypad: https://orbtile.com/download (ask Codex to check your Orbtile setup)"}'
if ($first -eq $expected) { Ok } else { Bad "no-app: wording differs from orbtile.sh: $first" }
ExpectSilent 'no-app-second-same-day' (Run 'no-app' '')
ExpectSilent 'app-installed' (Run 'app-installed' '' -app)
ExpectSilent 'windows-hooks' (Run 'windows-hooks' $winHooks)
ExpectSilent 'mac-hooks' (Run 'mac-hooks' $macHooks)
ExpectMessage 'other-hooks' (Run 'other-hooks' $otherHooks) $dl
ExpectMessage 'broken-json' (Run 'broken-json' '{"hooks": {"Stop"') $dl

# status
$st = Run 'status-no-app' '' 'status'
if ($st -match [regex]::Escape('- Orbtile app: not found on this computer') -and $st -match [regex]::Escape("Next step: download Orbtile from $dl")) { Ok } else { Bad "status-no-app: $st" }
$st = Run 'status-app' '' 'status' -app
if ($st -match 'found at' -and $st -match [regex]::Escape("hooks: off (optional: Orbtile reads Codex sessions without them)") -and $st -match 'Next step: none' -and $st -notmatch 'trust them') { Ok } else { Bad "status-app: $st" }
$st = Run 'status-hooks' $winHooks 'status'
if ($st -match [regex]::Escape("Orbtile's Codex hooks: on (Orbtile hooks in") -and $st -match 'trust them once in /hooks' -and $st -match 'Next step: none') { Ok } else { Bad "status-hooks: $st" }

# Antigravity (skills only, so status only): %USERPROFILE%\.gemini\config\hooks.json
function RunAg([string]$name, [string]$hooks, [switch]$app) {
    $d = Join-Path $tmp "ag-$name"
    foreach ($sub in 'home\.gemini\config', 'local') { New-Item -ItemType Directory -Force -Path (Join-Path $d $sub) | Out-Null }
    if ($hooks) { Set-Content -LiteralPath (Join-Path $d 'home\.gemini\config\hooks.json') -Value $hooks -Encoding ascii }
    if ($app) { New-Item -ItemType Directory -Force -Path (Join-Path $d 'local\Orbtile') | Out-Null }
    $saved = @{ USERPROFILE = $env:USERPROFILE; LOCALAPPDATA = $env:LOCALAPPDATA }
    $env:USERPROFILE = Join-Path $d 'home'; $env:LOCALAPPDATA = Join-Path $d 'local'
    try { $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File $script antigravity status | Out-String).Trim(); $code = $LASTEXITCODE }
    finally { foreach ($k in $saved.Keys) { Set-Item -Path "env:$k" -Value $saved[$k] } }
    if ($code -ne 0) { Bad "ag-$name exit code $code" }
    return $out
}
$agWinHooks = '{"orbtile-status":{"Stop":[{"type":"process","command":"C:/Program Files/Orbtile/Orbtile.HookHelper.exe","args":["--orbtile-agent","antigravity","--event","Stop"]}]}}'
$st = RunAg 'no-app' ''
if ($st -match '^Orbtile setup check for Antigravity' -and $st -match [regex]::Escape("Antigravity hooks: off (optional: Orbtile reads Antigravity sessions without them)") -and $st -match [regex]::Escape("Next step: download Orbtile from $dl")) { Ok } else { Bad "ag-no-app: $st" }
$st = RunAg 'hooks' $agWinHooks
if ($st -match [regex]::Escape("Orbtile's Antigravity hooks: on (Orbtile hooks in") -and $st -match [regex]::Escape('Next step: none. Orbtile is set up. You can remove the orbtile-start plugin from Antigravity.') -and $st -notmatch 'trust them') { Ok } else { Bad "ag-hooks: $st" }
$st = RunAg 'app' '' -app
if ($st -match 'found at' -and $st -match 'hooks: off' -and $st -match 'Next step: none') { Ok } else { Bad "ag-app: $st" }
$st = RunAg 'codex-marker' '{"x":"orbtile-codex-hook"}'
if ($st -match 'Antigravity hooks: off' -and $st -match 'Next step: download') { Ok } else { Bad "ag-codex-marker: $st" }

# bad arguments never fail (their usage line on stderr is expected, so stderr must not stop this test)
$ErrorActionPreference = 'Continue'
foreach ($a in @(@(), @('gemini', 'session-start'), @('codex', 'nope'), @('antigravity', 'nope'))) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script @a 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok } else { Bad "bad args '$($a -join ' ')': exit $LASTEXITCODE" }
}

# The plugin copies match the shared script
foreach ($plugin in 'codex', 'antigravity') {
    $copy = Join-Path $here "$plugin\orbtile-start\skills\orbtile-status\scripts\orbtile.ps1"
    if ((Get-FileHash $script).Hash -eq (Get-FileHash $copy).Hash) { Ok } else { Bad "$plugin plugin copy of orbtile.ps1 differs from shared/orbtile.ps1" }
}

Remove-Item -Recurse -Force $tmp
Write-Output "passed $($script:pass), failed $($script:fail)"
if ($script:fail -ne 0) { exit 1 }
