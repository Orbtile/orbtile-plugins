// Tests for OrbtileLauncher's pure parts. Run: dotnet run --project tests
using System;
using System.IO;
using Loupedeck.OrbtileSwitchPlugin;

var fails = 0; var pass = 0;
void Check(Boolean ok, String name) { if (ok) { pass++; } else { fails++; Console.WriteLine($"FAIL {name}"); } }

Check(OrbtileLauncher.TargetFor(true) == "orbtile://on", "installed opens orbtile://on");
Check(OrbtileLauncher.TargetFor(false) == "https://orbtile.com/download", "missing opens the download page");

var root = Path.Combine(Path.GetTempPath(), "orbtile-logi-test-" + Guid.NewGuid().ToString("N"));
var apps = Path.Combine(root, "Applications"); var home = Path.Combine(root, "home");
Directory.CreateDirectory(apps); Directory.CreateDirectory(Path.Combine(home, "Applications"));
Check(!OrbtileLauncher.IsInstalledOnMac(home, apps), "no app found when none is installed");
Directory.CreateDirectory(Path.Combine(apps, "Orbtile.app"));
Check(OrbtileLauncher.IsInstalledOnMac(home, apps), "Orbtile.app in /Applications");
Directory.Delete(Path.Combine(apps, "Orbtile.app"));
Directory.CreateDirectory(Path.Combine(home, "Applications", "Orbtile Enterprise.app"));
Check(OrbtileLauncher.IsInstalledOnMac(home, apps), "Orbtile Enterprise.app in ~/Applications");
Directory.Delete(Path.Combine(home, "Applications", "Orbtile Enterprise.app"));
Directory.CreateDirectory(Path.Combine(apps, "Orbtile Helper.app"));
Check(!OrbtileLauncher.IsInstalledOnMac(home, apps), "look-alike app name does not count");
Check(!OrbtileLauncher.IsInstalledOnMac("", Path.Combine(root, "missing")), "missing folders do not count");
if (!OperatingSystem.IsWindows()) { Check(!OrbtileLauncher.IsInstalledOnWindows(), "Windows check is false elsewhere"); }
Directory.Delete(root, true);

Console.WriteLine($"passed {pass}, failed {fails}");
return fails == 0 ? 0 : 1;
