# orbtile-start for Claude Code

A small starter for [Orbtile](https://orbtile.com), the app that shows the live state of your coding agents on a keypad and lets you answer them from the keys.

## What it does

- `/orbtile` checks this computer: is the Orbtile app installed, is it connected to Claude Code, and is it running. It tells you the one next step, if any.
- At the start of a new session it shows one line that points to Orbtile, at most once a day.
- Once Orbtile is connected to Claude Code, the line stops for good. You can then remove this plugin.

## What it does not do

- It sends nothing anywhere. It only reads local files: your Claude Code `settings.json` and the usual app folders.
- It never blocks a session. The hook always exits successfully, usually in a few milliseconds, and Claude Code stops it after 5 seconds at most.
- It is not Orbtile. The app itself installs its own Claude Code integration when you connect Claude Code in Orbtile.

## Install

```
/plugin marketplace add Orbtile/orbtile-plugins
/plugin install orbtile-start@orbtile-public
```

## Remove

```
/plugin uninstall orbtile-start@orbtile-public
```

## Requirements

macOS, where the Orbtile app runs. Uses only `sh`, `grep`, `tr` and `date`. On other systems the starter stays quiet.

## License

MIT. Made by Orbtile Team.
