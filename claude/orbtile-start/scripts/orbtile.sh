#!/bin/sh
# orbtile-start for Claude Code.
#   orbtile.sh session-start   SessionStart hook: at most one line a day pointing to the Orbtile app,
#                              nothing once Orbtile's own Claude Code integration is set up.
#   orbtile.sh status          Plain-text setup check for the /orbtile command.
# Reads local files only. Sends nothing anywhere. Always exits 0 so it can never block a session.

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="$config_dir/settings.json"
download_url="https://orbtile.com/download"

# Settings text on one line ("" when the file is missing or unreadable).
settings_text() {
    [ -r "$settings" ] && tr -d '\r\n' < "$settings" 2>/dev/null
}

# Which Orbtile integration is set up in Claude Code, or nothing.
#   Mac app:      enabledPlugins "orbtile@orbtile" (or the Enterprise / Sandbox ids) is true, or a marketplace
#                 path points at an Orbtile claude-plugin folder (Mac, or a remote host the app set up).
#   Windows app:  its hook commands in settings.json carry --orbtile-claude-hook.
hook_marker() {
    text=$(settings_text)
    [ -n "$text" ] || return 0
    id=$(printf '%s' "$text" | grep -Eo '"(orbtile@orbtile|orbtile-enterprise@orbtile-enterprise|orbtile-sandbox@orbtile-sandbox)"[[:space:]]*:[[:space:]]*true' | head -n 1 | cut -d '"' -f 2)
    if [ -n "$id" ]; then echo "plugin $id"; return 0; fi
    if printf '%s' "$text" | grep -Eq '"path"[[:space:]]*:[[:space:]]*"[^"]*[Oo]rbtile[^"]*claude-plugin[/\\]*"'; then
        echo "Orbtile plugin folder"; return 0
    fi
    if printf '%s' "$text" | grep -q -- '--orbtile-claude-hook'; then echo "Orbtile hooks"; return 0; fi
}

# Path of an installed Orbtile app, or nothing.
app_path() {
    apps="${ORBTILE_START_APPS_DIR:-/Applications}"  # override for tests only
    for p in "$apps/Orbtile.app" "$HOME/Applications/Orbtile.app" \
             "$apps/Orbtile Enterprise.app" "$HOME/Applications/Orbtile Enterprise.app"; do
        if [ -d "$p" ]; then echo "$p"; return 0; fi
    done
    # Windows (Git Bash): the app keeps its data in %LOCALAPPDATA%\Orbtile.
    if [ -n "${LOCALAPPDATA:-}" ] && [ -d "$LOCALAPPDATA/Orbtile" ]; then echo "$LOCALAPPDATA/Orbtile"; return 0; fi
}

session_start() {
    [ -z "$(hook_marker)" ] || return 0
    # Once a day at most. Without a writable state folder it still shows (never more than once a session).
    state_dir="${CLAUDE_PLUGIN_DATA:-}"
    today=$(( $(date +%s) / 86400 ))
    if [ -n "$state_dir" ]; then
        if [ "$(cat "$state_dir/last-shown-day" 2>/dev/null)" = "$today" ]; then return 0; fi
        mkdir -p "$state_dir" 2>/dev/null && printf '%s\n' "$today" > "$state_dir/last-shown-day" 2>/dev/null
    fi
    if [ -n "$(app_path)" ]; then
        msg="Orbtile is installed but not connected to Claude Code yet. Open Orbtile to connect it. Run /orbtile to check."
    else
        msg="Orbtile shows your Claude Code sessions live on a keypad and lets you answer them from the keys: $download_url (run /orbtile to check setup)"
    fi
    printf '{"systemMessage":"%s"}\n' "$msg"
}

status() {
    marker=$(hook_marker)
    app=$(app_path)
    echo "Orbtile setup check for Claude Code"
    if [ -n "$app" ]; then echo "- Orbtile app: found at $app"; else echo "- Orbtile app: not found on this computer"; fi
    if [ -n "$marker" ]; then echo "- Claude Code integration: on ($marker in $settings)"
    else echo "- Claude Code integration: off (nothing from Orbtile in $settings)"; fi
    if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
        if pgrep -x Orbtile >/dev/null 2>&1 || pgrep -x "Orbtile Enterprise" >/dev/null 2>&1; then
            echo "- Orbtile running: yes"
        else
            echo "- Orbtile running: no"
        fi
    fi
    if [ -n "$marker" ]; then
        echo "Next step: none. Orbtile is set up; this starter plugin stays quiet and can be removed with: claude plugin uninstall orbtile-start@orbtile-public"
    elif [ -n "$app" ]; then
        echo "Next step: open Orbtile and connect Claude Code in its settings."
    else
        echo "Next step: download Orbtile from $download_url"
    fi
}

case "${1:-}" in
    session-start) session_start ;;
    status) status ;;
    *) echo "usage: orbtile.sh session-start|status" >&2 ;;
esac
exit 0
