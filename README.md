# Orbtile plugins

Starter plugins that help you set up [Orbtile](https://orbtile.com) for your coding agents. Each one checks whether the Orbtile app is set up for its agent, points you to it until it is, and then goes quiet. None of them sends anything anywhere.

| Agent | Plugin | Install |
|---|---|---|
| Claude Code | [`orbtile-start`](claude/orbtile-start) | `/plugin marketplace add Orbtile/orbtile-plugins` then `/plugin install orbtile-start@orbtile-public` |
| Codex | [`orbtile-start`](codex/orbtile-start) | `codex plugin marketplace add Orbtile/orbtile-plugins` then `codex plugin add orbtile-start@orbtile-public` |

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
