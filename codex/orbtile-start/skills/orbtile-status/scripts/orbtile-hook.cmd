:; # Codex session-start hook for macOS, Linux and Windows (one file, two shells). Source: shared/orbtile-hook.cmd.
:; # sh reads the next line (cmd skips lines starting with ":" as labels); cmd runs the lines after it.
:; PLUGIN_DATA="${PLUGIN_DATA:-$1}" exec sh "$(dirname "$0")/orbtile.sh" codex session-start; exit 0
@echo off
if "%PLUGIN_DATA%"=="" set "PLUGIN_DATA=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0orbtile.ps1" codex session-start
exit /b 0
