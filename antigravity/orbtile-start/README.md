# orbtile-start for Antigravity

A small starter for [Orbtile](https://orbtile.com), the app that shows the live state of your coding agents on a keypad.

## What it does

- The `orbtile-status` skill checks this computer: is the Orbtile app installed, are Orbtile's Antigravity hooks on, and is the app running. It tells you the one next step, if any. Ask Antigravity to "check my Orbtile setup" or "set up Orbtile for Antigravity".
- Once the Orbtile app is installed, there is nothing more to set up: Orbtile follows Antigravity sessions without extra steps. You can then remove this plugin.

## What it does not do

- It adds no hooks and shows nothing on its own. It runs only when you ask.
- It sends nothing anywhere. It only reads local files: your Antigravity `hooks.json` and the usual app folders.
- It changes no files or settings. It is not Orbtile: the app sets up its own Antigravity hooks.

## Install

Install the `antigravity/orbtile-start` folder of [Orbtile/orbtile-plugins](https://github.com/Orbtile/orbtile-plugins) as an Antigravity plugin.

## Requirements

macOS or Windows, where the Orbtile app runs. On macOS it uses `sh`; on Windows it uses PowerShell. On other systems the check says that Orbtile does not run there.

## License

MIT. Made by Orbtile Team.
