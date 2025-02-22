using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using ACW = Autodesk.Connectivity.WebServices;
using ACWT = Autodesk.Connectivity.WebServicesTools;
using VDF = Autodesk.DataManagement.Client.Framework;
using Autodesk.Connectivity.Explorer.Extensibility;


namespace VdsSampleUtilities
{
    class VdsSampleAdmin : IExplorerExtension
    {
        public static VDF.Vault.Currency.Connections.Connection mConnection = null;
        public static Settings mSettings = null;
        public static bool mConfigPerm = false;
        public static bool mSettingsChanged = false;
        public bool mIsDarkTheme = VDF.Forms.SkinUtils.ThemeState.IsDarkTheme;
        private string mCurrentTheme;

        IEnumerable<CommandSite> IExplorerExtension.CommandSites()
        {
            List<CommandSite> mAdminFormCmdSites = new List<CommandSite>();

            //Describe admin command item
            CommandItem mAdminCmd = new CommandItem("Command.VdsSampleAdmin", "VDS-Sample-Administration...")
            {                
                Image = Properties.Resources.Open_Settings_16_Light
            };
            mAdminCmd.Execute += mAdminCmd_Execute;

            //Deploy command site
            CommandSite mAdminCmdSite = new CommandSite("Menu.ToolsMenu", "VDS-Sample-Administration")
            {
                Location = CommandSiteLocation.ToolsMenu,
                DeployAsPulldownMenu = false
            };
            mAdminCmdSite.AddCommand(mAdminCmd);
            mAdminFormCmdSites.Add(mAdminCmdSite);

            return mAdminFormCmdSites;
        }

        private void mAdminCmd_Execute(object sender, CommandItemEventArgs e)
        {
            Autodesk.Connectivity.WebServices.Permis[] mAllPermisObjects = e.Context.Application.Connection.WebServiceManager.AdminService.GetPermissionsByUserId(e.Context.Application.Connection.UserID);
            List<long> mAllPermissions = new List<long>();
            foreach (var item in mAllPermisObjects)
            {
                mAllPermissions.Add(item.Id);
            }
            if (mAllPermissions.Contains(76) && mAllPermissions.Contains(77)) //76 = Vault Set Options; 77 = Vault Get Options
            {
                mConfigPerm = true;
                VdsSampleAdminForm mAdminWindow = new VdsSampleAdminForm();

                mCurrentTheme = VDF.Forms.SkinUtils.WinFormsTheme.Instance.CurrentTheme.ToString();

                if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Light.ToString())
                {
                    mAdminWindow.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.LightThemeName);
                    mAdminWindow.IconOptions.Image = Properties.Resources.Open_Settings_16_Light;
                }
                if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Dark.ToString())
                {
                    mAdminWindow.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.DarkThemeName);
                    mAdminWindow.IconOptions.Image = Properties.Resources.Open_Settings_16_Dark;
                }
                if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Default.ToString())
                {
                    mAdminWindow.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.DefaultThemeName);
                }
                
                mAdminWindow.ShowDialog();
            }
            else
            {
                VDF.Currency.Restriction mAdminRestriction = new VDF.Currency.Restriction("VDS Sample Administration Settings", "Access denied", "Accessing Administration Settings requires the permissions 'Vault Get Options' and 'Vault Set Options'");
                VDF.Forms.Settings.ShowRestrictionsSettings showRestrictionsSettings = new VDF.Forms.Settings.ShowRestrictionsSettings("VDS-Sample-Administration", VDF.Forms.Settings.ShowRestrictionsSettings.IconType.Error);
                showRestrictionsSettings.AddRestriction(mAdminRestriction);
                showRestrictionsSettings.ShowDetailsArea = true;
                showRestrictionsSettings.RestrictionColumnCaption = "Restriction";
                showRestrictionsSettings.RestrictedObjectNameColumnCaption = "Object";
                showRestrictionsSettings.ReasonColumnCaption = "Restriction Reason";

                DialogResult result = VDF.Forms.Library.ShowRestrictions(showRestrictionsSettings);
                //MessageBox.Show("You do not have sufficient permissions to configure Vault behaviors. \n\r Contact your Vault Configuration Administrator.", "iLogic Job Administration.", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        IEnumerable<CustomEntityHandler> IExplorerExtension.CustomEntityHandlers()
        {
            return null;
        }

        IEnumerable<DetailPaneTab> IExplorerExtension.DetailTabs()
        {
            return null;
        }

        IEnumerable<string> IExplorerExtension.HiddenCommands()
        {
            return null;
        }

        void IExplorerExtension.OnLogOff(IApplication application)
        {
            //do nothing
        }

        void IExplorerExtension.OnLogOn(IApplication application)
        {
            mConnection = application.Connection;
        }

        void IExplorerExtension.OnShutdown(IApplication application)
        {
            //do nothing
        }

        void IExplorerExtension.OnStartup(IApplication application)
        {
            VDF.Library.Initialize();
            VDF.Forms.Library.Initialize();
        }

        public IEnumerable<DockPanel> DockPanels()
        {
            throw new NotImplementedException();
        }
    }
}
