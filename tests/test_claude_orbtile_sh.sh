#!/bin/sh
# Tests for claude/orbtile-start/scripts/orbtile.sh. Runs in temp folders only; never reads your real settings.
# Usage: sh tests/test_claude_orbtile_sh.sh
here=$(cd "$(dirname "$0")/.." && pwd)
script="$here/claude/orbtile-start/scripts/orbtile.sh"
fails=0
pass=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# run <case-name> <settings-json or ""> [extra env assignments...] -> stdout of session-start
run() {
    name=$1; settings=$2; shift 2
    case_dir="$tmp/$name"
    mkdir -p "$case_dir/home" "$case_dir/config" "$case_dir/apps" "$case_dir/data"
    [ -n "$settings" ] && printf '%s\n' "$settings" > "$case_dir/config/settings.json"
    env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" HOME="$case_dir/home" CLAUDE_CONFIG_DIR="$case_dir/config" \
        CLAUDE_PLUGIN_DATA="$case_dir/data" ORBTILE_START_APPS_DIR="$case_dir/apps" "$@" \
        sh "$script" session-start
}

expect_silent() {
    if [ -z "$2" ]; then pass=$((pass+1)); else fails=$((fails+1)); echo "FAIL $1: expected silence, got: $2"; fi
}

# expect_message <case> <output> <substring>: one valid JSON object whose systemMessage holds <substring>.
expect_message() {
    if printf '%s' "$2" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); assert list(d)==["systemMessage"]; assert sys.argv[1] in d["systemMessage"]' "$3" 2>/dev/null; then
        pass=$((pass+1))
    else
        fails=$((fails+1)); echo "FAIL $1: expected a systemMessage with '$3', got: $2"
    fi
}

dl="https://orbtile.com/download"

expect_message no-settings "$(run no-settings '')" "$dl"
expect_message empty-object "$(run empty-object '{}')" "$dl"
expect_silent mac-plugin-on "$(run mac-plugin-on '{
  "enabledPlugins": {
    "orbtile@orbtile": true
  }
}')"
expect_message mac-plugin-off "$(run mac-plugin-off '{"enabledPlugins": {"orbtile@orbtile": false}}')" "$dl"
expect_silent enterprise-on "$(run enterprise-on '{"enabledPlugins":{"orbtile-enterprise@orbtile-enterprise":true}}')"
expect_silent sandbox-on "$(run sandbox-on '{"enabledPlugins":{"orbtile-sandbox@orbtile-sandbox":true}}')"
expect_silent mac-marketplace-path "$(run mac-marketplace-path '{
  "extraKnownMarketplaces": {
    "orbtile": {
      "source": {
        "source": "directory",
        "path": "/Users/u/Library/Application Support/Orbtile/claude-plugin"
      }
    }
  }
}')"
expect_silent remote-marketplace-path "$(run remote-marketplace-path '{"extraKnownMarketplaces":{"orbtile":{"source":{"source":"directory","path":"/home/u/.local/share/orbtile/claude-plugin"}}}}')"
expect_silent windows-hooks "$(run windows-hooks '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"\"C:/Program Files/Orbtile/Orbtile.HookHelper.exe\" --orbtile-claude-hook"}]}]}}')"
# Its own entry, or another marketplace with a similar name, must not count as Orbtile being set up.
expect_message only-starter "$(run only-starter '{"enabledPlugins":{"orbtile-start@orbtile-public":true}}')" "$dl"
expect_message lookalike "$(run lookalike '{"enabledPlugins":{"xorbtile@orbtile":true,"orbtile@orbtile-public":true}}')" "$dl"
expect_message broken-json "$(run broken-json '{"enabledPlugins": {"orbtile@orbt')" "$dl"

# Once a day: the second start in the same state folder is silent.
first=$(run once-a-day '')
second=$(env -i PATH="/usr/bin:/bin" HOME="$tmp/once-a-day/home" CLAUDE_CONFIG_DIR="$tmp/once-a-day/config" \
    CLAUDE_PLUGIN_DATA="$tmp/once-a-day/data" ORBTILE_START_APPS_DIR="$tmp/once-a-day/apps" sh "$script" session-start)
expect_message once-a-day-first "$first" "$dl"
expect_silent once-a-day-second "$second"

# App installed but not connected: a different line, no download link.
mkdir -p "$tmp/app-installed/apps/Orbtile.app"
out=$(run app-installed '')
expect_message app-installed "$out" "installed but not connected"
case "$out" in *"$dl"*) fails=$((fails+1)); echo "FAIL app-installed: should not show the download link";; *) pass=$((pass+1));; esac

# Unreadable state folder: still shows, still exits 0.
out=$(run no-state '' CLAUDE_PLUGIN_DATA=/nonexistent/forbidden); code=$?
expect_message no-state "$out" "$dl"
[ "$code" -eq 0 ] && pass=$((pass+1)) || { fails=$((fails+1)); echo "FAIL no-state: exit $code"; }

# status
st=$(env -i PATH="/usr/bin:/bin" HOME="$tmp/mac-plugin-on/home" CLAUDE_CONFIG_DIR="$tmp/mac-plugin-on/config" \
    ORBTILE_START_APPS_DIR="$tmp/mac-plugin-on/apps" sh "$script" status)
case "$st" in *"Claude Code integration: on (plugin orbtile@orbtile"*) pass=$((pass+1));; *) fails=$((fails+1)); echo "FAIL status-on: $st";; esac
st=$(env -i PATH="/usr/bin:/bin" HOME="$tmp/no-settings/home" CLAUDE_CONFIG_DIR="$tmp/no-settings/config" \
    ORBTILE_START_APPS_DIR="$tmp/no-settings/apps" sh "$script" status)
case "$st" in *"integration: off"*"Next step: download Orbtile from $dl"*) pass=$((pass+1));; *) fails=$((fails+1)); echo "FAIL status-off: $st";; esac

# Public copy rules: no em-dash anywhere in the shipped plugin.
if grep -rq "$(printf '\342\200\224')" "$here/claude/orbtile-start"; then fails=$((fails+1)); echo "FAIL em-dash in claude/orbtile-start"; else pass=$((pass+1)); fi

echo "passed $pass, failed $fails"
[ "$fails" -eq 0 ]
