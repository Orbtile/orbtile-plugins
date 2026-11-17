namespace Loupedeck.OrbtileSwitchPlugin
{
    using System;

    // The "Switch to Orbtile" plugin. It works with no target application: its one action opens Orbtile
    // (or the download page), so the plugin needs no setup when it loads.
    public class OrbtileSwitchPlugin : Plugin
    {
        public override Boolean UsesApplicationApiOnly => true;

        public override Boolean HasNoApplication => true;

        public override void Load()
        {
        }

        public override void Unload()
        {
        }
    }
}
