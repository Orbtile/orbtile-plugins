# orbtile-start for Codex

A small starter for [Orbtile](https://orbtile.com), the app that shows the live state of your coding agents on a keypad and lets you answer them from the keys.

## What it does

- The `orbtile-status` skill checks this computer: is the Orbtile app installed, is it connected to Codex, and is it running. It tells you the one next step, if any. Ask Codex to "check my Orbtile setup".
- At the start of a new session it shows one line that points to Orbtile, at most once a day. Codex runs a plugin's hook only after you trust it in `/hooks` (Settings > Hooks in the Codex app). If you leave it untrusted, the skill still works and the line never shows.
- Once Orbtile is connected to Codex, the line stops for good. You can then remove this plugin.

## What it does not do

- It sends nothing anywhere. It only reads local files: your Codex `hooks.json` and the usual app folders.
- It never blocks a session. The hook always exits successfully, usually in a few milliseconds, and Codex stops it after 5 seconds at most.
- It is not Orbtile. The app itself installs its own Codex hooks when you connect Codex in Orbtile.

## Install

```
codex plugin marketplace add Orbtile/orbtile-plugins
codex plugin add orbtile-start@orbtile-public
```

## Remove

```
codex plugin remove orbtile-start@orbtile-public
```

## Requirements

macOS or Linux. Uses only `sh`, `grep`, `tr` and `date`.

## License

MIT. Made by Orbtile Team.
