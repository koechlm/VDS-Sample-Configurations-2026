
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
            this.btnSelectFromVault = new DevExpress.XtraEditors.SimpleButton();
            this.btnSelectItem = new DevExpress.XtraEditors.SimpleButton();
            this.SuspendLayout();
            // 
            // btnSelectFromVault
            // 
            this.btnSelectFromVault.Location = new System.Drawing.Point(12, 12);
            this.btnSelectFromVault.Name = "btnSelectFromVault";
            this.btnSelectFromVault.Size = new System.Drawing.Size(158, 23);
            this.btnSelectFromVault.TabIndex = 0;
            this.btnSelectFromVault.Text = "Select File(s)...";
            this.btnSelectFromVault.ToolTip = "Open Select from Vault Dialog to browse and search Vault.";
            this.btnSelectFromVault.ToolTipTitle = "Select Entity from Vault";
            this.btnSelectFromVault.Click += new System.EventHandler(this.btnSelectFromVault_Click);
            // 
            // btnSelectItem
            // 
            this.btnSelectItem.Location = new System.Drawing.Point(12, 41);
            this.btnSelectItem.Name = "btnSelectItem";
            this.btnSelectItem.Size = new System.Drawing.Size(158, 23);
            this.btnSelectItem.TabIndex = 1;
            this.btnSelectItem.Text = "Select Item(s)...";
            this.btnSelectItem.Click += new System.EventHandler(this.btnSelectItem_Click);
            // 
            // VdsSampleAdminForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(581, 356);
            this.Controls.Add(this.btnSelectItem);
            this.Controls.Add(this.btnSelectFromVault);
            this.IconOptions.Image = global::VdsSampleUtilities.Properties.Resources.Open_Settings_16_Light;
            this.LookAndFeel.UseDefaultLookAndFeel = false;
            this.Name = "VdsSampleAdminForm";
            this.Text = "VDS-Sample-Administration";
            this.ResumeLayout(false);

        }

        #endregion

        private DevExpress.XtraEditors.SimpleButton btnSelectFromVault;
        private DevExpress.XtraEditors.SimpleButton btnSelectItem;
    }
}