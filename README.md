# Orbtile plugins

Starter plugins that help you set up [Orbtile](https://orbtile.com) for your coding agents. Each one checks whether the Orbtile app is set up for its agent and tells you the one next step, if any. None of them sends anything anywhere.

| Agent | Plugin | Install |
|---|---|---|
| Claude Code | [`orbtile-start`](claude/orbtile-start) | `/plugin marketplace add Orbtile/orbtile-plugins` then `/plugin install orbtile-start@orbtile-public` |
| Codex | [`orbtile-start`](codex/orbtile-start) | `codex plugin marketplace add Orbtile/orbtile-plugins` then `codex plugin add orbtile-start@orbtile-public` |
| Antigravity | [`orbtile-start`](antigravity/orbtile-start) (skill only) | Copy the `antigravity/orbtile-start` folder into Antigravity's plugin folder, `~/.gemini/config/plugins/orbtile-start`. Google's docs also give `agy plugin install https://github.com/Orbtile/orbtile-plugins/antigravity/orbtile-start` (from Google's docs; not yet tested by us). |
| ZCode | [`orbtile-start`](zcode/orbtile-start) (skill only) | Pending in [zai-org/zcode-plugins#198](https://github.com/zai-org/zcode-plugins/pull/198). Until then, from a clone of this repository: `zcode plugins marketplace add <path to the clone>/zcode`, then `zcode plugins install orbtile-start@orbtile-public` and `zcode plugins enable orbtile-start@orbtile-public` |

## Logi plugin for MX Creative Keypad

[Switch to Orbtile](logitech) adds one action for the MX Creative Keypad: press it and the Orbtile app takes over the keypad. If Orbtile is not installed, the key opens https://orbtile.com/download instead. Coming to the Logi Marketplace. The source here is MIT; the installed package is under the [Orbtile Plugin EULA](logitech/EULA.md).

## Tests

```
sh tests/test_orbtile_sh.sh
```

On Windows:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_orbtile_ps1.ps1
```

## License

MIT. Made by Orbtile Team.
