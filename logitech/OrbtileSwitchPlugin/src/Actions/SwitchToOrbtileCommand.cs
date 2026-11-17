namespace Loupedeck.OrbtileSwitchPlugin
{
    using System;

    // One key: hands the keypad to Orbtile. Without the Orbtile app it opens the download page instead.
    public class SwitchToOrbtileCommand : PluginDynamicCommand
    {
        private const String IconResource = "SwitchToOrbtile.png";

        public SwitchToOrbtileCommand()
            : base(displayName: "Switch to Orbtile", description: "Hands this keypad to the Orbtile app. Opens orbtile.com/download when Orbtile is not installed.", groupName: "Orbtile")
        {
        }

        protected override void RunCommand(String actionParameter)
        {
            var target = OrbtileLauncher.TargetFor(OrbtileLauncher.IsInstalled());
            try
            {
                OrbtileLauncher.Open(target);
                this.Plugin.Log.Info($"Opened {target}");
            }
            catch (Exception e)
            {
                this.Plugin.Log.Error(e, $"Could not open {target}");
            }
        }

        protected override BitmapImage GetCommandImage(String actionParameter, PluginImageSize imageSize)
        {
            var assembly = typeof(SwitchToOrbtileCommand).Assembly;
            return assembly.ReadImage(assembly.FindFileOrThrow(IconResource));
        }
    }
}
