# orbtile-start for Claude Code

`/orbtile` checks whether [Orbtile](https://orbtile.com) is set up for Claude Code on this computer, and tells you the one next step if it is not. Orbtile is an app for macOS and Windows that shows the live state of your Claude Code sessions on a keypad and lets you answer them from the keys.

## What /orbtile checks

- Is the Orbtile app installed on this computer?
- Is Orbtile connected to Claude Code (its plugin enabled, or its hooks in your settings)?
- On macOS: is Orbtile running?

It answers in a few lines and gives one next step: download Orbtile, open it to connect Claude Code, or nothing (all set, and you can remove this plugin).

## The session reminder

Until Orbtile is connected, a new session shows one line that points to Orbtile and to `/orbtile`, at most once a day. Once Orbtile is connected, the line stops for good. On Linux and other systems where Orbtile does not run, the plugin never shows it.

## What it runs, reads and sends

- It runs one shell script, `scripts/orbtile.sh`, at session start and when you type `/orbtile`.
- It reads local files only: your Claude Code `settings.json` and the usual app folders (`/Applications`, `~/Applications`, `%LOCALAPPDATA%\Orbtile`). On macOS it checks whether a process named Orbtile is running.
- It writes one small file in its own plugin data folder: the day the reminder was last shown.
- It sends nothing anywhere and fetches nothing. It makes no network calls.
- It never blocks a session. The hook always exits successfully, usually in a few milliseconds, and Claude Code stops it after 5 seconds at most.
- It is not Orbtile. The Orbtile app installs its own Claude Code integration when you connect Claude Code in Orbtile.

## Install from the command line

    /plugin marketplace add Orbtile/orbtile-plugins
    /plugin install orbtile-start@orbtile-public

## Remove

    /plugin uninstall orbtile-start@orbtile-public

## Requirements

macOS or Windows, where the Orbtile app runs. On Windows it runs in the Git Bash that Claude Code uses.

## License

MIT. Made by Orbtile Team.
