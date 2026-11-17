# Switch to Orbtile (Logi plugin)

A plugin for the Logi Plugin Service that adds one action for the MX Creative Keypad: **Switch to Orbtile**. Press it and the [Orbtile](https://orbtile.com) app takes over the keypad. If Orbtile is not installed, the key opens https://orbtile.com/download instead. Orbtile runs on macOS and Windows.

## What it does

- Checks whether the Orbtile app is installed:
  - macOS: Orbtile.app or Orbtile Enterprise.app in /Applications or ~/Applications;
  - Windows: the `orbtile://` link registration under `HKCU\Software\Classes\orbtile`.
- Installed: opens `orbtile://on`. Orbtile starts if needed and decides whether it can take the keypad. If it cannot (for example when the trial is over), the keypad stays with Options+ and Orbtile shows the reason in its own panel.
- Not installed: opens https://orbtile.com/download in your browser.
- It sends nothing anywhere and collects no data.

## Licences

- The plugin package you install from the Logi Marketplace (`.lplug4`) is licensed under the [Orbtile Plugin EULA](EULA.md).
- The source code in this folder is licensed under MIT (see the repository's LICENSE).
- The Orbtile app is licensed separately under https://orbtile.com/terms.

## Build

Needs the .NET 10 SDK and Logitech's `LogiPluginTool` (`dotnet tool install --global LogiPluginTool`). The plugin API comes from the `LogiPluginApi` NuGet package.

    cd OrbtileSwitchPlugin/src
    dotnet build -c Release
    cd ..
    dotnet run --project tests
    logiplugintool pack ./bin/Release/ ./OrbtileSwitch_1_0.lplug4
    logiplugintool verify ./OrbtileSwitch_1_0.lplug4

On macOS and Windows, a build also links the plugin into your local Logi Plugin Service for testing. That is how Logitech's project template works.

Release builds carry no debug symbols or build-machine paths.

Made by Orbtile Team.
