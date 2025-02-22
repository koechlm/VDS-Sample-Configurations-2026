using DevExpress.XtraEditors;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using ACW = Autodesk.Connectivity.WebServices;
using VDF = Autodesk.DataManagement.Client.Framework;
using VDFV = Autodesk.DataManagement.Client.Framework.Vault;
using VDFVF = Autodesk.DataManagement.Client.Framework.Vault.Forms;
using VDFVFS = Autodesk.DataManagement.Client.Framework.Vault.Forms.Settings;

namespace VdsSampleUtilities
{
    /// <summary>
    /// User interface for administrators; supports themes
    /// </summary>
    public partial class VdsSampleAdminForm : DevExpress.XtraEditors.XtraForm
    {
        /// <summary>
        /// 
        /// </summary>
        public VdsSampleAdminForm()
        {
            InitializeComponent();
        }

        void searchFunc(IEnumerable<string> entityClassIds, bool multiSelect, Action<IEnumerable<VDFV.Currency.Entities.IEntity>> resultFunc)
        {
            List<VDFV.Currency.Entities.IEntity> searchResults = new List<VDFV.Currency.Entities.IEntity>();
            //do search
            ACW.ItemService itemService = VdsSampleAdmin.mConnection.WebServiceManager.ItemService;
            VDF.Vault.Currency.Entities.ItemRevision entity = new VDFV.Currency.Entities.ItemRevision(VdsSampleAdmin.mConnection, itemService.GetLatestItemByItemNumber("ADSK-103005"));
            searchResults.Add(entity);
            //report results
            resultFunc(searchResults);
        }

        VDFV.Currency.Entities.IEntity createFolder(VDFV.Currency.Entities.IEntity dir)
        {
            VDFV.Currency.Entities.Folder folder = dir as VDFV.Currency.Entities.Folder;
            MessageBox.Show(string.Format("You asked to create a folder in: {0}", folder.FullName));
            return folder;
        }

        private void btnSelectFromVault_Click(object sender, EventArgs e)
        {
            VDFVFS.SelectEntitySettings selectEntitySettings = new VDFVFS.SelectEntitySettings();
            VDFVFS.SelectEntitySettings.SelectEntityOptionsExtensibility selectEntityOptionsExtensibility = new VDFVFS.SelectEntitySettings.SelectEntityOptionsExtensibility();
            selectEntityOptionsExtensibility.DoSearch = searchFunc;
            VDF.Vault.Currency.Entities.IEntity entity = new VDFV.Currency.Entities.Folder(VdsSampleAdmin.mConnection, VdsSampleAdmin.mConnection.WebServiceManager.DocumentService.GetFolderRoot());
            selectEntityOptionsExtensibility.CreateFolder = createFolder;
            selectEntitySettings.ShowFolderView = true;
            //filter entities
            selectEntitySettings.ActionableEntityClassIds.Add("FILE");

            VDFVF.Results.SelectEntityResults selectEntityResults = VDFVF.Library.SelectEntity(VdsSampleAdmin.mConnection, selectEntitySettings);

        }

        private void btnSelectItem_Click(object sender, EventArgs e)
        {
            VDFVFS.SelectEntitySettings selectEntitySettings = new VDFVFS.SelectEntitySettings();

            VDFVF.Interfaces.ISelectEntityExtensionControl control = null;
            selectEntitySettings.SetSidebarControl(control);
            selectEntitySettings.ActionableEntityClassIds.Add("ITEM");
            selectEntitySettings.MultipleSelect = false;
            selectEntitySettings.DialogCaption = "Select Item...";
            selectEntitySettings.ShowFolderView = false;
            selectEntitySettings.ClearTextBoxOnNonActionableEntity = true;

            ACW.ItemService itemService = VdsSampleAdmin.mConnection.WebServiceManager.ItemService;
            VDF.Vault.Currency.Entities.ItemRevision entity = new VDFV.Currency.Entities.ItemRevision(VdsSampleAdmin.mConnection, itemService.GetLatestItemByItemNumber("ADSK-103006"));
            VDF.Vault.Currency.Entities.ItemRevision entity1 = new VDFV.Currency.Entities.ItemRevision(VdsSampleAdmin.mConnection, itemService.GetLatestItemByItemNumber("ADSK-103006"));

            VDFVFS.VaultNavigationPathSettings navigationPathSettings = new VDFVFS.VaultNavigationPathSettings();
            navigationPathSettings.TopLevelEntities.Append(entity);

            selectEntitySettings.NavigationPathSettings = navigationPathSettings;
            selectEntitySettings.NavigationPathSettings.TopLevelEntities.Append(entity1);
            selectEntitySettings.InitialBrowseLocation = entity;
            //selectEntitySettings.RestrictNavigation = true;
            selectEntitySettings.SelectionTextLabel = "Item(s):";
            selectEntitySettings.PersistenceKey = "SelectItemChildren";
            selectEntitySettings.ActionButtonNavigatesContainers = true;
            // search for Item entities.
            List<string> Entitylist = new List<string>();
            Entitylist.Add("ITEM"); 
            selectEntitySettings.OptionsExtensibility.DoSearch = (x, y, z) => searchFunc(Entitylist, false, z);

            VDFVF.Results.SelectEntityResults selectEntityResults = VDFVF.Library.SelectEntity(VdsSampleAdmin.mConnection, selectEntitySettings);
        }
    }
}