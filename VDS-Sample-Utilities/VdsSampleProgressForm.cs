using System;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using VDF = Autodesk.DataManagement.Client.Framework;

namespace VdsSampleUtilities
{
    /// <summary>
    /// Themed dialog for progress feedback
    /// </summary>
    public partial class VdsSampleProgressForm : DevExpress.XtraEditors.XtraForm
    {

        private string mCurrentTheme;

        /// <summary>
        /// 
        /// </summary>
        public VdsSampleProgressForm()
        {
            InitializeComponent();

            mCurrentTheme = VDF.Forms.SkinUtils.WinFormsTheme.Instance.CurrentTheme.ToString();

            if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Light.ToString())
            {
                this.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.LightThemeName);
            }
            if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Dark.ToString())
            {
                this.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.DarkThemeName);
            }
            if (mCurrentTheme == VDF.Forms.SkinUtils.Theme.Default.ToString())
            {
                this.LookAndFeel.SetSkinStyle(VDF.Forms.SkinUtils.CustomThemeSkins.DefaultThemeName);
            }
        }

        /// <summary>
        /// Create a new asynchron dialog with marquee style progress bar.
        /// Call Thread.Abort() to terminated the dialog.
        /// </summary>
        /// <returns>Thread</returns>
        public Thread ShowProgress(string header)
        {
            VdsSampleProgressForm progressForm = new VdsSampleProgressForm();
            progressForm.lblProgress.Text = header;
            Thread t = new Thread(() => Application.Run(progressForm));
            t.Start();
            return t;
        }

    }
}
