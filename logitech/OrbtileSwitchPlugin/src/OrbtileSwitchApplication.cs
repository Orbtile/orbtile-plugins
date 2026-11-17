namespace Loupedeck.OrbtileSwitchPlugin
{
    using System;

    // Not tied to an application window: the action works whichever app is in front.
    public class OrbtileSwitchApplication : ClientApplication
    {
        protected override String GetProcessName() => "";

        protected override String GetBundleName() => "";

        public override ClientApplicationStatus GetApplicationStatus() => ClientApplicationStatus.Unknown;
    }
}
