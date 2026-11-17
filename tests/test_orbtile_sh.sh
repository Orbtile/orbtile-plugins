#!/bin/sh
# Tests for shared/orbtile.sh and the copies the plugins carry. Runs in temp folders only; never reads your real
# settings. Usage: sh tests/test_orbtile_sh.sh
here=$(cd "$(dirname "$0")/.." && pwd)
script="$here/shared/orbtile.sh"
fails=0
pass=0
ok() { pass=$((pass+1)); }
bad() { fails=$((fails+1)); echo "FAIL $*"; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# run <agent> <case-name> <config text or ""> [extra env assignments...] -> stdout of session-start.
# The config text goes to Claude's settings.json or Codex's hooks.json (Antigravity has its own helper below).
run() {
    agent=$1; name=$2; config=$3; shift 3
    d="$tmp/$agent-$name"
    mkdir -p "$d/home" "$d/config" "$d/apps" "$d/data"
    case "$agent" in
        claude) file="$d/config/settings.json"; dirvar="CLAUDE_CONFIG_DIR=$d/config"; datavar="CLAUDE_PLUGIN_DATA=$d/data" ;;
        codex) file="$d/config/hooks.json"; dirvar="CODEX_HOME=$d/config"; datavar="PLUGIN_DATA=$d/data" ;;
    esac
    [ -n "$config" ] && printf '%s\n' "$config" > "$file"
    env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" HOME="$d/home" "$dirvar" "$datavar" ORBTILE_START_APPS_DIR="$d/apps" ORBTILE_START_OS=Darwin "$@" \
        sh "$script" "$agent" session-start
}

expect_silent() { if [ -z "$2" ]; then ok; else bad "$1: expected silence, got: $2"; fi; }

# expect_message <case> <output> <substring>: one valid JSON object whose systemMessage holds <substring>.
expect_message() {
    if printf '%s' "$2" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); assert list(d)==["systemMessage"]; assert sys.argv[1] in d["systemMessage"]' "$3" 2>/dev/null
    then ok; else bad "$1: expected a systemMessage with '$3', got: $2"; fi
}

dl="https://orbtile.com/download"

# --- Claude Code: ~/.claude/settings.json
expect_message claude-no-settings "$(run claude no-settings '')" "$dl"
expect_message claude-no-settings-name "$(run claude no-settings2 '')" "Claude Code sessions"
expect_message claude-empty-object "$(run claude empty-object '{}')" "$dl"
expect_silent claude-mac-plugin-on "$(run claude mac-plugin-on '{
  "enabledPlugins": {
    "orbtile@orbtile": true
  }
}')"
expect_message claude-mac-plugin-off "$(run claude mac-plugin-off '{"enabledPlugins": {"orbtile@orbtile": false}}')" "$dl"
expect_silent claude-enterprise-on "$(run claude enterprise-on '{"enabledPlugins":{"orbtile-enterprise@orbtile-enterprise":true}}')"
expect_silent claude-sandbox-on "$(run claude sandbox-on '{"enabledPlugins":{"orbtile-sandbox@orbtile-sandbox":true}}')"
expect_silent claude-mac-marketplace-path "$(run claude mac-marketplace-path '{
  "extraKnownMarketplaces": {
    "orbtile": {
      "source": {
        "source": "directory",
        "path": "/Users/u/Library/Application Support/Orbtile/claude-plugin"
      }
    }
  }
}')"
expect_silent claude-remote-marketplace-path "$(run claude remote-marketplace-path '{"extraKnownMarketplaces":{"orbtile":{"source":{"source":"directory","path":"/home/u/.local/share/orbtile/claude-plugin"}}}}')"
expect_silent claude-windows-hooks "$(run claude windows-hooks '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"\"C:/Program Files/Orbtile/Orbtile.HookHelper.exe\" --orbtile-claude-hook"}]}]}}')"
# Its own entry, or a look-alike name, must not count as Orbtile being set up.
expect_message claude-only-starter "$(run claude only-starter '{"enabledPlugins":{"orbtile-start@orbtile-public":true}}')" "$dl"
expect_message claude-lookalike "$(run claude lookalike '{"enabledPlugins":{"xorbtile@orbtile":true,"orbtile@orbtile-public":true}}')" "$dl"
expect_message claude-broken-json "$(run claude broken-json '{"enabledPlugins": {"orbtile@orbt')" "$dl"
# Run by Codex (which loads Claude-format plugins and sets PLUGIN_ROOT): no Claude Code line in a Codex session.
expect_silent claude-under-codex "$(run claude under-codex '' PLUGIN_ROOT=/tmp/plugins/orbtile-start)"
# Run by ZCode (it can pick up this repo's Claude marketplace and sets ZCODE_PLUGIN_ROOT): no Claude Code line there either.
expect_silent claude-under-zcode "$(run claude under-zcode '' ZCODE_PLUGIN_ROOT=/tmp/plugins/orbtile-start)"
# A Codex marker in Claude's settings does not count, and the other way round (below).
expect_message claude-codex-marker "$(run claude codex-marker '{"x":"orbtile-codex-hook"}')" "$dl"

# --- Codex: ~/.codex/hooks.json
expect_message codex-no-hooks "$(run codex no-hooks '')" "$dl"
expect_message codex-no-hooks-name "$(run codex no-hooks2 '')" "Codex sessions"
expect_silent codex-mac-hooks "$(run codex mac-hooks '{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "\"/Users/u/Library/Application Support/Orbtile/bin/orbtile-codex-hook\" SessionStart", "timeout": 3 } ] }
    ]
  }
}')"
expect_silent codex-remote-hooks "$(run codex remote-hooks '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"/home/u/.local/share/orbtile/remote-agents/orbtile-codex-hook Stop"}]}]}}')"
expect_silent codex-windows-hooks "$(run codex windows-hooks '{"hooks":{"Stop":[{"hooks":[{"type":"process","command":"C:/Program Files/Orbtile/Orbtile.HookHelper.exe","args":["--orbtile-agent","codex","--event","Stop"]}]}]}}')"
expect_message codex-other-hooks "$(run codex other-hooks '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"/usr/local/bin/notify Stop"}]}]}}')" "$dl"
expect_message codex-claude-marker "$(run codex claude-marker '{"enabledPlugins":{"orbtile@orbtile":true}}')" "$dl"

# --- Shared behaviour, per agent
for a in claude codex; do
    # Once a day: the second start in the same state folder is silent.
    first=$(run $a once-a-day '')
    second=$(run $a once-a-day '')
    expect_message $a-once-a-day-first "$first" "$dl"
    expect_silent $a-once-a-day-second "$second"

    # App installed, no hooks. Claude Code needs the app's plugin: a "not connected" line, no download link.
    # Codex is zero-install in the app (Adapter.swift .zeroInstallMode): an installed app means silence.
    mkdir -p "$tmp/$a-app-installed/apps/Orbtile.app"
    out=$(run $a app-installed '')
    if [ $a = claude ]; then
        expect_message $a-app-installed "$out" "installed but not connected"
        case "$out" in *"$dl"*) bad "$a-app-installed: should not show the download link";; *) ok;; esac
    else
        expect_silent $a-app-installed "$out"
    fi

    # Unwritable state folder: still shows, still exits 0.
    case $a in claude) v=CLAUDE_PLUGIN_DATA;; codex) v=PLUGIN_DATA;; esac
    out=$(run $a no-state '' "$v=/nonexistent/forbidden"); code=$?
    expect_message $a-no-state "$out" "$dl"
    [ "$code" -eq 0 ] && ok || bad "$a-no-state: exit $code"
done

# --- status
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Darwin HOME="$tmp/claude-mac-plugin-on/home" CLAUDE_CONFIG_DIR="$tmp/claude-mac-plugin-on/config" \
    ORBTILE_START_APPS_DIR="$tmp/claude-mac-plugin-on/apps" sh "$script" claude status)
case "$st" in *"Claude Code integration: on (plugin orbtile@orbtile"*) ok;; *) bad "claude-status-on: $st";; esac
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Darwin HOME="$tmp/claude-no-settings/home" CLAUDE_CONFIG_DIR="$tmp/claude-no-settings/config" \
    ORBTILE_START_APPS_DIR="$tmp/claude-no-settings/apps" sh "$script" claude status)
case "$st" in *"integration: off"*"Next step: download Orbtile from $dl"*) ok;; *) bad "claude-status-off: $st";; esac
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Darwin HOME="$tmp/codex-mac-hooks/home" CODEX_HOME="$tmp/codex-mac-hooks/config" \
    ORBTILE_START_APPS_DIR="$tmp/codex-mac-hooks/apps" sh "$script" codex status)
case "$st" in *"Orbtile's Codex hooks: on (Orbtile hooks"*"trust them once in /hooks"*"Next step: none"*) ok;; *) bad "codex-status-on: $st";; esac
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Darwin HOME="$tmp/codex-app-installed/home" CODEX_HOME="$tmp/codex-app-installed/config" \
    ORBTILE_START_APPS_DIR="$tmp/codex-app-installed/apps" sh "$script" codex status)
case "$st" in *"found at"*"hooks: off (optional: Orbtile reads Codex sessions without them)"*"Next step: none"*) ok;; *) bad "codex-status-zero-install: $st";; esac
case "$st" in *"trust them"*) bad "codex-status-zero-install: trust note without hooks";; *) ok;; esac
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Darwin HOME="$tmp/codex-no-hooks/home" CODEX_HOME="$tmp/codex-no-hooks/config" \
    ORBTILE_START_APPS_DIR="$tmp/codex-no-hooks/apps" sh "$script" codex status)
case "$st" in *"not found"*"Next step: download Orbtile from $dl"*) ok;; *) bad "codex-status-no-app: $st";; esac

# --- Linux and other systems: the app does not run there, so no line and no download step
for a in claude codex; do
    expect_silent $a-linux "$(run $a linux '' ORBTILE_START_OS=Linux)"
    st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Linux HOME="$tmp/$a-linux/home" CLAUDE_CONFIG_DIR="$tmp/$a-linux/config" \
        CODEX_HOME="$tmp/$a-linux/config" ORBTILE_START_APPS_DIR="$tmp/$a-linux/apps" sh "$script" $a status)
    case "$st" in *"runs on macOS and Windows, not on this system"*"Next step: none here. Orbtile runs on macOS and Windows."*) ok;; *) bad "$a-linux-status: $st";; esac
    case "$st" in *download*|*"$dl"*) bad "$a-linux-status: mentions a download";; *) ok;; esac
done
# A Linux host the Mac app set up over SSH reports the integration as on.
st=$(env -i PATH="/usr/bin:/bin" ORBTILE_START_OS=Linux HOME="$tmp/claude-remote-marketplace-path/home" \
    CLAUDE_CONFIG_DIR="$tmp/claude-remote-marketplace-path/config" sh "$script" claude status)
case "$st" in *"integration: on (Orbtile plugin folder"*"Next step: none. Orbtile is set up"*) ok;; *) bad "claude-linux-remote-status: $st";; esac

# --- Windows shells (Git Bash reports MINGW64_NT-...): the app's data folder counts as installed
expect_message claude-windows-no-app "$(run claude windows-no-app '' ORBTILE_START_OS=MINGW64_NT-10.0-26100)" "$dl"
mkdir -p "$tmp/claude-windows-app/home/AppData/Local/Orbtile"
expect_message claude-windows-app "$(run claude windows-app '' ORBTILE_START_OS=MINGW64_NT-10.0-26100 LOCALAPPDATA="$tmp/claude-windows-app/home/AppData/Local")" "installed but not connected"
mkdir -p "$tmp/codex-windows-app/home/AppData/Local/Orbtile"
expect_silent codex-windows-app "$(run codex windows-app '' ORBTILE_START_OS=MINGW64_NT-10.0-26100 LOCALAPPDATA="$tmp/codex-windows-app/home/AppData/Local")"

# --- Antigravity: ~/.gemini/config/hooks.json. Skills only (no hook in the plugin), so only status is used.
# ag_status <case> <hooks.json text or ""> [extra env...] -> stdout of status.
ag_status() {
    name=$1; config=$2; shift 2
    d="$tmp/antigravity-$name"
    mkdir -p "$d/home/.gemini/config" "$d/apps"
    [ -n "$config" ] && printf '%s\n' "$config" > "$d/home/.gemini/config/hooks.json"
    env -i PATH="/usr/bin:/bin" HOME="$d/home" ORBTILE_START_APPS_DIR="$d/apps" ORBTILE_START_OS=Darwin "$@" sh "$script" antigravity status
}
ag_mac_hooks='{
  "orbtile-status": {
    "Stop": [
      { "type": "command", "command": "'"'"'/Users/u/Library/Application Support/Orbtile/bin/orbtile-antigravity-hook'"'"' Stop", "timeout": 3 }
    ]
  }
}'
st=$(ag_status no-app '')
case "$st" in "Orbtile setup check for Antigravity"*"not found on this computer"*"Antigravity hooks: off (optional: Orbtile reads Antigravity sessions without them)"*"Next step: download Orbtile from $dl") ok;; *) bad "antigravity-status-no-app: $st";; esac
st=$(ag_status mac-hooks "$ag_mac_hooks")
case "$st" in *"Orbtile's Antigravity hooks: on (Orbtile hooks in"*"Next step: none. Orbtile is set up. You can remove the orbtile-start plugin from Antigravity.") ok;; *) bad "antigravity-status-mac-hooks: $st";; esac
case "$st" in *"trust them"*|*"in /hooks"*) bad "antigravity-status-mac-hooks: Codex trust note shown";; *) ok;; esac
st=$(ag_status windows-hooks '{"orbtile-status":{"Stop":[{"type":"process","command":"C:/Program Files/Orbtile/Orbtile.HookHelper.exe","args":["--orbtile-agent","antigravity","--event","Stop"]}]}}' ORBTILE_START_OS=MINGW64_NT-10.0-26100)
case "$st" in *"Antigravity hooks: on"*"Next step: none"*) ok;; *) bad "antigravity-status-windows-hooks: $st";; esac
mkdir -p "$tmp/antigravity-app/apps/Orbtile.app"
st=$(ag_status app '')
case "$st" in *"found at"*"hooks: off (optional"*"Next step: none. Orbtile is set up."*) ok;; *) bad "antigravity-status-app: $st";; esac
st=$(ag_status codex-marker '{"x":"orbtile-codex-hook"}')
case "$st" in *"Antigravity hooks: off"*"Next step: download"*) ok;; *) bad "antigravity-status-codex-marker: $st";; esac
st=$(ag_status linux "$ag_mac_hooks" ORBTILE_START_OS=Linux)
case "$st" in *"not on this system"*) ok;; *) bad "antigravity-status-linux: $st";; esac
st=$(ag_status linux-none '' ORBTILE_START_OS=Linux)
case "$st" in *"Next step: none here. Orbtile runs on macOS and Windows."*) ok;; *) bad "antigravity-status-linux-none: $st";; esac
case "$st" in *download*) bad "antigravity-status-linux-none: mentions a download";; *) ok;; esac

# Antigravity plugin manifest: the fields Antigravity's directory asks for, and a square logo of at least 128 px.
if python3 -I - "$here/antigravity/orbtile-start" <<'PY'
import json, struct, sys, os
root = sys.argv[1]
m = json.load(open(os.path.join(root, "plugin.json")))
for k in ("name", "displayName", "description", "version", "logo", "suggestedPrompts", "author"):
    assert m.get(k), k
assert m["name"] == "orbtile-start"
assert not m["name"].lower().startswith(("antigravity", "gemini", "claude", "cursor"))
assert 1 <= len(m["suggestedPrompts"]) <= 3
assert m["author"]["name"] == "Orbtile Team"
png = open(os.path.join(root, m["logo"]), "rb").read(24)
assert png[:8] == b"\x89PNG\r\n\x1a\n"
w, h = struct.unpack(">II", png[16:24])
assert w == h and w >= 128, (w, h)
assert os.path.isfile(os.path.join(root, "README.md"))
assert os.path.isfile(os.path.join(root, "skills", "orbtile-status", "SKILL.md"))
PY
then ok; else bad "antigravity/orbtile-start/plugin.json or its logo"; fi
[ -x "$here/antigravity/orbtile-start/skills/orbtile-status/scripts/orbtile.sh" ] && ok || bad "antigravity copy of orbtile.sh is not executable"
# No hooks of its own: the Antigravity starter only answers when asked.
if [ -e "$here/antigravity/orbtile-start/hooks.json" ] || [ -e "$here/antigravity/orbtile-start/hooks" ]; then bad "antigravity plugin ships hooks"; else ok; fi

# --- ZCode: ~/.zcode/cli/config.json. Skills only; Orbtile reads ZCode task files, plus one optional approval hook.
zc_status() {
    name=$1; config=$2; shift 2
    d="$tmp/zcode-$name"
    mkdir -p "$d/home/.zcode/cli" "$d/apps"
    [ -n "$config" ] && printf '%s\n' "$config" > "$d/home/.zcode/cli/config.json"
    env -i PATH="/usr/bin:/bin" HOME="$d/home" ORBTILE_START_APPS_DIR="$d/apps" ORBTILE_START_OS=Darwin "$@" sh "$script" zcode status
}
zc_mac_hook='{"hooks":{"enabled":true,"events":{"PermissionRequest":[{"hooks":[{"type":"process","command":"/Users/u/Library/Application Support/Orbtile/bin/orbtile-zcode-hook","args":["PermissionRequest"]}]}]}}}'
st=$(zc_status no-app '')
case "$st" in "Orbtile setup check for ZCode"*"not found on this computer"*"ZCode hooks: off (optional: Orbtile follows ZCode tasks from their files without them)"*"Next step: download Orbtile from $dl") ok;; *) bad "zcode-status-no-app: $st";; esac
st=$(zc_status mac-hook "$zc_mac_hook")
case "$st" in *"Orbtile's ZCode hooks: on (Orbtile hooks in"*"Next step: none. Orbtile is set up. You can remove the orbtile-start plugin from ZCode.") ok;; *) bad "zcode-status-mac-hook: $st";; esac
st=$(zc_status windows-hook '{"hooks":{"events":{"PermissionRequest":[{"hooks":[{"type":"process","command":"C:/Program Files/Orbtile/Orbtile.HookHelper.exe","args":["--orbtile-agent","zcode","--event","PermissionRequest","--wait","approval"]}]}]}}}' ORBTILE_START_OS=MINGW64_NT-10.0-26100)
case "$st" in *"ZCode hooks: on"*"Next step: none"*) ok;; *) bad "zcode-status-windows-hook: $st";; esac
mkdir -p "$tmp/zcode-app/apps/Orbtile.app"
st=$(zc_status app '')
case "$st" in *"found at"*"hooks: off (optional"*"Next step: none. Orbtile is set up."*) ok;; *) bad "zcode-status-app: $st";; esac
st=$(zc_status other-hook '{"hooks":{"events":{"Stop":[{"hooks":[{"type":"process","command":"orbtile-antigravity-hook"}]}]}}}')
case "$st" in *"ZCode hooks: off"*"Next step: download"*) ok;; *) bad "zcode-status-other-agent-marker: $st";; esac
st=$(zc_status linux-none '' ORBTILE_START_OS=Linux)
case "$st" in *"not on this system"*"Next step: none here. Orbtile runs on macOS and Windows."*) ok;; *) bad "zcode-status-linux: $st";; esac
case "$st" in *download*) bad "zcode-status-linux: mentions a download";; *) ok;; esac
# A Linux host the Mac app set up over SSH (remote ZCode hook) reports the hook as on.
st=$(zc_status linux-remote '{"hooks":{"events":{"PermissionRequest":[{"hooks":[{"type":"process","command":"/home/u/.local/share/orbtile/remote-agents/orbtile-zcode-hook"}]}]}}}' ORBTILE_START_OS=Linux)
case "$st" in *"ZCode hooks: on"*"Next step: none. Orbtile is set up"*) ok;; *) bad "zcode-status-linux-remote: $st";; esac

# ZCode plugin manifest: the fields zai-org/zcode-plugins requires, both READMEs, no hooks.
if python3 -I - "$here/zcode/orbtile-start" <<'PY'
import json, os, re, sys
root = sys.argv[1]
m = json.load(open(os.path.join(root, ".zcode-plugin", "plugin.json")))
for k in ("name", "description", "version", "author"):
    assert m.get(k), k
assert re.fullmatch(r"[a-z0-9][a-z0-9._-]{0,127}", m["name"]) and m["name"] == "orbtile-start"
assert m["description_i18n"]["en"] == m["description"] and m["description_i18n"]["zh-CN"]
assert m["author"]["name"] == "Orbtile Team"
for f in ("README.md", "README_CN.md", "LICENSE", "skills/orbtile-status/SKILL.md"):
    assert os.path.isfile(os.path.join(root, f)), f
assert not os.path.exists(os.path.join(root, "hooks"))
PY
then ok; else bad "zcode/orbtile-start manifest or files"; fi
[ -x "$here/zcode/orbtile-start/skills/orbtile-status/scripts/orbtile.sh" ] && ok || bad "zcode copy of orbtile.sh is not executable"
# Versions match across the plugins.
v=$(grep -h '"version"' "$here/.claude-plugin/marketplace.json" "$here/claude/orbtile-start/.claude-plugin/plugin.json" "$here/codex/orbtile-start/.codex-plugin/plugin.json" \
    "$here/antigravity/orbtile-start/plugin.json" "$here/zcode/orbtile-start/.zcode-plugin/plugin.json" "$here/zcode/marketplace.json" | tr -d ' ,' | sort -u | wc -l)
[ "$v" -eq 1 ] && ok || bad "plugin versions differ"

# --- Codex hook wrapper (shared/orbtile-hook.cmd): one file that sh and cmd both run. Codex starts it as
# "<path> <PLUGIN_DATA>" (PowerShell on Windows does not get PLUGIN_DATA in its environment).
wrapper="$here/shared/orbtile-hook.cmd"
[ -x "$wrapper" ] && ok || bad "orbtile-hook.cmd is not executable (chmod +x, and commit the mode)"
[ -x "$here/codex/orbtile-start/skills/orbtile-status/scripts/orbtile-hook.cmd" ] && ok || bad "plugin copy of orbtile-hook.cmd is not executable"
w="$tmp/wrapper"; mkdir -p "$w/home" "$w/codex" "$w/apps" "$w/data"
out=$(env -i PATH="/usr/bin:/bin" HOME="$w/home" CODEX_HOME="$w/codex" ORBTILE_START_APPS_DIR="$w/apps" ORBTILE_START_OS=Darwin \
    sh -c '"$0" "$1"' "$wrapper" "$w/data"); code=$?
expect_message wrapper-message "$out" "$dl"
[ "$code" -eq 0 ] && ok || bad "wrapper exit $code"
[ -f "$w/data/last-shown-day" ] && ok || bad "wrapper did not use the data folder argument"
out=$(env -i PATH="/usr/bin:/bin" HOME="$w/home" CODEX_HOME="$w/codex" ORBTILE_START_APPS_DIR="$w/apps" ORBTILE_START_OS=Darwin \
    sh -c '"$0" "$1"' "$wrapper" "$w/data")
expect_silent wrapper-second "$out"
mkdir -p "$w/apps/Orbtile.app"; rm -f "$w/data/last-shown-day"
out=$(env -i PATH="/usr/bin:/bin" HOME="$w/home" CODEX_HOME="$w/codex" ORBTILE_START_APPS_DIR="$w/apps" ORBTILE_START_OS=Darwin \
    sh -c '"$0" "$1"' "$wrapper" "$w/data")
expect_silent wrapper-app-installed "$out"

# --- Bad arguments never fail
env -i PATH="/usr/bin:/bin" HOME="$tmp" sh "$script" >/dev/null 2>&1 && ok || bad "no-args exit code"
env -i PATH="/usr/bin:/bin" HOME="$tmp" sh "$script" gemini session-start >/dev/null 2>&1 && ok || bad "unknown agent exit code"

# --- Plugin copies match the shared script
for copy in claude/orbtile-start/scripts/orbtile.sh codex/orbtile-start/skills/orbtile-status/scripts/orbtile.sh \
            antigravity/orbtile-start/skills/orbtile-status/scripts/orbtile.sh zcode/orbtile-start/skills/orbtile-status/scripts/orbtile.sh; do
    if cmp -s "$script" "$here/$copy"; then ok; else bad "$copy differs from shared/orbtile.sh (copy it again)"; fi
done
if cmp -s "$here/shared/orbtile-hook.cmd" "$here/codex/orbtile-start/skills/orbtile-status/scripts/orbtile-hook.cmd"; then ok
else bad "codex/orbtile-start/skills/orbtile-status/scripts/orbtile-hook.cmd differs from shared/orbtile-hook.cmd (copy it again)"; fi
for copy in codex/orbtile-start/skills/orbtile-status/scripts/orbtile.ps1 antigravity/orbtile-start/skills/orbtile-status/scripts/orbtile.ps1 \
            zcode/orbtile-start/skills/orbtile-status/scripts/orbtile.ps1; do
    if cmp -s "$here/shared/orbtile.ps1" "$here/$copy"; then ok; else bad "$copy differs from shared/orbtile.ps1 (copy it again)"; fi
done

# --- Public copy rules: no em-dash anywhere in what ships
if grep -rq "$(printf '\342\200\224')" "$here/claude" "$here/codex" "$here/antigravity" "$here/zcode" "$here/shared" "$here/.claude-plugin" "$here/.agents" "$here/logitech" "$here/README.md"; then
    bad "em-dash in shipped files"
else ok; fi

echo "passed $pass, failed $fails"
[ "$fails" -eq 0 ]
