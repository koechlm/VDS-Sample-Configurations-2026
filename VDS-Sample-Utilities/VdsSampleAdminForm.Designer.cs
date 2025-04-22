
namespace VdsSampleUtilities
{
    partial class VdsSampleAdminForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(VdsSampleAdminForm));
            btnSelectFromVault = new DevExpress.XtraEditors.SimpleButton();
            btnSelectItem = new DevExpress.XtraEditors.SimpleButton();
            SuspendLayout();
            // 
            // btnSelectFromVault
            // 
            btnSelectFromVault.Location = new Point(12, 12);
            btnSelectFromVault.Name = "btnSelectFromVault";
            btnSelectFromVault.Size = new Size(158, 23);
            btnSelectFromVault.TabIndex = 0;
            btnSelectFromVault.Text = "Select File(s)...";
            btnSelectFromVault.ToolTip = "Open Select from Vault Dialog to browse and search Vault.";
            btnSelectFromVault.ToolTipTitle = "Select Entity from Vault";
            btnSelectFromVault.Visible = false;
            btnSelectFromVault.Click += btnSelectFromVault_Click;
            // 
            // btnSelectItem
            // 
            btnSelectItem.Location = new Point(12, 41);
            btnSelectItem.Name = "btnSelectItem";
            btnSelectItem.Size = new Size(158, 23);
            btnSelectItem.TabIndex = 1;
            btnSelectItem.Text = "Select Item(s)...";
            btnSelectItem.Visible = false;
            btnSelectItem.Click += btnSelectItem_Click;
            // 
            // VdsSampleAdminForm
            // 
            AutoScaleDimensions = new SizeF(6F, 13F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(581, 356);
            Controls.Add(btnSelectItem);
            Controls.Add(btnSelectFromVault);
            IconOptions.Icon = (Icon)resources.GetObject("VdsSampleAdminForm.IconOptions.Icon");
            LookAndFeel.UseDefaultLookAndFeel = false;
            Name = "VdsSampleAdminForm";
            Text = "VDS-Sample-Administration";
            ResumeLayout(false);

        }

        #endregion

        private DevExpress.XtraEditors.SimpleButton btnSelectFromVault;
        private DevExpress.XtraEditors.SimpleButton btnSelectItem;
    }
}