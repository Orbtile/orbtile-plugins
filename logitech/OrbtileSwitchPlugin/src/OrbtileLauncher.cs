namespace Loupedeck.OrbtileSwitchPlugin
{
    using System;
    using System.Diagnostics;
    using System.IO;

    // Decides what the "Switch to Orbtile" key opens, and opens it.
    // Orbtile installed: orbtile://on (the app takes the keypad). Not installed: the download page.
    // Reads local folders and, on Windows, the orbtile:// registration only. Sends nothing anywhere.
    public static class OrbtileLauncher
    {
        public const String SwitchUri = "orbtile://on";
        public const String DownloadUrl = "https://orbtile.com/download";

        // The target for the key, given whether the Orbtile app is installed.
        public static String TargetFor(Boolean appInstalled) => appInstalled ? SwitchUri : DownloadUrl;

        // Mac: Orbtile.app (or Orbtile Enterprise.app) in /Applications or ~/Applications.
        public static Boolean IsInstalledOnMac(String home, String applicationsDir = "/Applications")
        {
            foreach (var name in new[] { "Orbtile.app", "Orbtile Enterprise.app" })
            {
                if (Directory.Exists(Path.Combine(applicationsDir, name)) ||
                    (!String.IsNullOrEmpty(home) && Directory.Exists(Path.Combine(home, "Applications", name))))
                {
                    return true;
                }
            }
            return false;
        }

        // Windows: the installer registers orbtile:// under HKCU\Software\Classes\orbtile.
        public static Boolean IsInstalledOnWindows()
        {
            if (!OperatingSystem.IsWindows())
            {
                return false;
            }
            using var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Classes\orbtile");
            return key != null;
        }

        public static Boolean IsInstalled()
        {
            if (OperatingSystem.IsMacOS())
            {
                return IsInstalledOnMac(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));
            }
            return IsInstalledOnWindows();
        }

        // Opens the target with the system's default handler.
        public static void Open(String target)
        {
            if (OperatingSystem.IsMacOS())
            {
                Process.Start(new ProcessStartInfo("/usr/bin/open") { ArgumentList = { target }, UseShellExecute = false })?.Dispose();
            }
            else
            {
                Process.Start(new ProcessStartInfo(target) { UseShellExecute = true })?.Dispose();
            }
        }
    }
}
