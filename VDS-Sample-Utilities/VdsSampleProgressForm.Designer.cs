
namespace VdsSampleUtilities
{
    partial class VdsSampleProgressForm
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
            this.formAssistant1 = new DevExpress.XtraBars.FormAssistant();
            this.lblProgress = new DevExpress.XtraEditors.LabelControl();
            this.ProgressBarControl1 = new DevExpress.XtraEditors.MarqueeProgressBarControl();
            ((System.ComponentModel.ISupportInitialize)(this.ProgressBarControl1.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // lblProgress
            // 
            this.lblProgress.Location = new System.Drawing.Point(12, 12);
            this.lblProgress.Name = "lblProgress";
            this.lblProgress.Size = new System.Drawing.Size(54, 13);
            this.lblProgress.TabIndex = 1;
            this.lblProgress.Text = "Progress...";
            // 
            // ProgressBarControl1
            // 
            this.ProgressBarControl1.Location = new System.Drawing.Point(12, 31);
            this.ProgressBarControl1.Name = "ProgressBarControl1";
            this.ProgressBarControl1.Size = new System.Drawing.Size(423, 20);
            this.ProgressBarControl1.TabIndex = 2;
            // 
            // VdsSampleProgressForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(447, 63);
            this.Controls.Add(this.ProgressBarControl1);
            this.Controls.Add(this.lblProgress);
            this.IconOptions.Image = global::VdsSampleUtilities.Properties.Resources.Vault_Pro;
            this.Name = "VdsSampleProgressForm";
            this.Text = "VDS-Sample-Configuration";
            ((System.ComponentModel.ISupportInitialize)(this.ProgressBarControl1.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private DevExpress.XtraBars.FormAssistant formAssistant1;
        internal DevExpress.XtraEditors.LabelControl lblProgress;
        private DevExpress.XtraEditors.MarqueeProgressBarControl ProgressBarControl1;
    }
}