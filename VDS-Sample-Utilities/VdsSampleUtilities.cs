//using System.Drawing;
using Autodesk.Connectivity.WebServices;
using Autodesk.Connectivity.WebServicesTools;
using Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities;
using Autodesk.DataManagement.Client.Framework.Vault.Currency.Connections;
using Autodesk.DataManagement.Client.Framework.Vault.Currency.PersistentId;
using VDF = Autodesk.DataManagement.Client.Framework;
using ACET = Autodesk.Connectivity.Explorer.ExtensibilityTools;
using Inventor;
using AcInterop = Autodesk.AutoCAD.Interop;
using AcInteropCom = Autodesk.AutoCAD.Interop.Common;
using Autodesk.DataManagement.Client.Framework.Vault.Currency.Properties;

using System.Windows.Media.Imaging;
using ACW = Autodesk.Connectivity.WebServices;
using System.IO;


namespace VdsSampleUtilities
{
    /// <summary>
    /// Provide System.Text.Encoding not in VDS PowerShell 2026 runtime
    /// </summary>
    public class TextEncoding
    {
        /// <summary>
        /// Return the byte value using Systems.Text.Encoding.UTF8
        /// </summary>
        /// <param name="String"></param>
        /// <returns></returns>
        public byte[] UTF8GetBytes(string String)
        {
            // use the system.text.encoding ASCII.GetByte() method
            if (string.IsNullOrEmpty(String))
                throw new ArgumentException("Input string cannot be null or empty.", nameof(String));

            // Convert string to UTF8 bytes
            byte[] bytes = System.Text.Encoding.UTF8.GetBytes(String);

            // Return the first byte (or handle as needed)
            return bytes;
        }
        /// <summary>
        /// Return the byte value using Systems.Text.Encoding.ASCII
        /// </summary>
        /// <param name="String"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public byte[] ASCIIGetBytes(string String)
        {
            // use the system.text.encoding ASCII.GetByte() method
            if (string.IsNullOrEmpty(String))
                throw new ArgumentException("Input string cannot be null or empty.", nameof(String));

            // Convert string to ASCII bytes
            byte[] bytes = System.Text.Encoding.ASCII.GetBytes(String);

            // Return the first byte (or handle as needed)
            return bytes;
        }

        // create similare mothods for string to integer and integer to string conversions
        /// <summary>
        /// Return the string value using Systems.Text.Encoding.UTF8
        /// </summary>
        /// <param name="bytes"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public string UTF8GetString(byte[] bytes)
        {
            // use the system.text.encoding ASCII.GetString() method
            if (bytes == null || bytes.Length == 0)
                throw new ArgumentException("Input byte array cannot be null or empty.", nameof(bytes));
            // Convert bytes to UTF8 string
            string result = System.Text.Encoding.UTF8.GetString(bytes);
            // Return the resulting string
            return result;
        }

        /// <summary>
        /// Return the string value using Systems.Text.Encoding.ASCII
        /// </summary>
        /// <param name="bytes"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public string ASCIIGetString(byte[] bytes)
        {
            // use the system.text.encoding ASCII.GetString() method
            if (bytes == null || bytes.Length == 0)
                throw new ArgumentException("Input byte array cannot be null or empty.", nameof(bytes));
            // Convert bytes to ASCII string
            string result = System.Text.Encoding.ASCII.GetString(bytes);
            // Return the resulting string
            return result;
        }
    }


    /// <summary>
    /// Provides methods for converting between different data types.
    /// </summary>
    public class Convert
    {
        /// <summary>
        /// Convert integer to string
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public int ToInt32(string value)
        {
            return System.Convert.ToInt32(value);
        }

        /// <summary>
        /// Convert string to integer
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public string Int32ToString(int value)
        {
            return System.Convert.ToString(value);
        }

        /// <summary>
        /// Convert string to long integer
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public long ToInt64(string value)
        {
            return System.Convert.ToInt64(value);
        }

        /// <summary>
        /// Convert long integer to string
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public string Int64ToString(long value)
        {
            return System.Convert.ToString(value);
        }

        /// <summary>
        /// Convert string to double
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public double ToDouble(string value)
        {
            return System.Convert.ToDouble(value);
        }

        /// <summary>
        /// Convert double to string
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public string DoubleToString(double value)
        {
            return System.Convert.ToString(value);
        }

        /// <summary>
        /// Convert byte array to Base64 string 
        /// </summary>
        /// <param name="byteArray"></param>
        /// <returns></returns>
        public string ToBase64String(byte[] byteArray)
        {
            return System.Convert.ToBase64String(byteArray);
        }

        /// <summary>
        /// Convert Base64 string to byte array
        /// </summary>
        /// <param name="s"></param>
        /// <returns></returns>
        public byte[] FromBase64String(string s)
        {
            return System.Convert.FromBase64String(s);
        }
    }

    /// <summary>
    /// Class representing a node in the tree structure of file dependencies.
    /// </summary>
    public class TreeNode
    {
        private Connection? _con;
        private Autodesk.Connectivity.WebServices.File? _file;
        private WebServiceManager? _svc => _con?.WebServiceManager;

        /// <summary>
        /// Initializes a new instance of the <see cref="TreeNode"/> class.
        /// </summary>
        /// <param name="file">The file to be represented by this node.</param>
        /// <param name="con">The connection to the Vault.</param>
        public TreeNode(Autodesk.Connectivity.WebServices.File file, Connection con)
        {
            _con = con;
            _file = file;
        }

        /// <summary>
        /// Gets the name of the file represented by this node.
        /// </summary>
        public string? Name => _file?.Name;

        /// <summary>
        /// Retrieve the children of the current file. The children are the files that are dependent on this file.
        /// </summary>
        public List<TreeNode> Children
        {
            get
            {
                if (_svc == null || _file == null)
                {
                    throw new InvalidOperationException("WebServiceManager or File is null.");
                }

                List<TreeNode> children = new List<TreeNode>();
                FileAssocArray[] fileAssociations = _svc.DocumentService.GetLatestFileAssociationsByMasterIds(
                    new long[] { _file.MasterId },
                    FileAssociationTypeEnum.None,
                    false,
                    FileAssociationTypeEnum.Dependency,
                    false,
                    false,
                    false,
                    false);

                if (fileAssociations.FirstOrDefault()?.FileAssocs != null)
                {
                    foreach (var fileAssociation in fileAssociations.First().FileAssocs)
                    {
                        children.Add(new TreeNode(fileAssociation.CldFile, _con));
                    }
                }
                return children;
            }
        }

        /// <summary>
        /// Retrieve the parent of the current file. The parent is the file that is dependent on this file.
        /// </summary>
        public List<TreeNode> Parents
        {
            get
            {
                if (_svc == null || _file == null)
                {
                    throw new InvalidOperationException("WebServiceManager or File is null.");
                }

                List<TreeNode> parents = new List<TreeNode>();
                FileAssocArray[] fileAssociations = _svc.DocumentService.GetLatestFileAssociationsByMasterIds(
                    new long[] { _file.MasterId },
                    FileAssociationTypeEnum.Dependency,
                    false,
                    FileAssociationTypeEnum.None,
                    false,
                    false,
                    false,
                    false);

                if (fileAssociations.FirstOrDefault()?.FileAssocs != null)
                {
                    foreach (var fileAssociation in fileAssociations.First().FileAssocs)
                    {
                        parents.Add(new TreeNode(fileAssociation.ParFile, _con));
                    }
                }
                return parents;
            }
        }

        /// <summary>
        /// Get the file type's icon as a bitmap image.
        /// </summary>
        public BitmapImage? Icon
        {
            get
            {
                PropertyDefinitionDictionary props = _con.PropertyManager.GetPropertyDefinitions("FILE", null, PropertyDefinitionFilter.IncludeAll);
                var def = props["EntityIcon"];
                object fileIter = new FileIteration(_con, _file);
                ImageInfo? prop = _con.PropertyManager.GetPropertyValue((IEntity)fileIter, def, null) as ImageInfo;
                if (prop != null)
                {
                    System.IO.MemoryStream ms = new System.IO.MemoryStream();
                    // Save the memory stream as a PNG file
                    prop.GetImage().Save(ms, System.Drawing.Imaging.ImageFormat.Png);
                    prop.Dispose();
                    System.Windows.Media.Imaging.BitmapImage bImg = new System.Windows.Media.Imaging.BitmapImage();
                    bImg.BeginInit();
                    bImg.StreamSource = ms;// new System.IO.MemoryStream(ms.ToArray());
                    bImg.EndInit();
                    return bImg;
                }
                return null;
            }
        }
    }

    /// <summary>
    /// Class extending VDS Vault scripts
    /// </summary>
    public class VltHelpers
    {
        private byte[]? _virtualCompThumbnail;
        private IEnumerable<object>? occurrences;

        /// <summary>
        /// Gets an image resource as a byte array in PNG format
        /// </summary>
        /// <param name="resourceName">The name of the image resource (e.g., "VirtualComp_32")</param>
        /// <returns>Byte array containing the image in PNG format, or an empty array if the resource cannot be loaded</returns>
        private static byte[] GetImageResourceAsByteArray(string resourceName)
        {
            try
            {
                var resourceManager = new System.Resources.ResourceManager(
                    "VDSSampleUtilities.Properties.Resources",
                    typeof(VltHelpers).Assembly);

                using (var bitmap = resourceManager.GetObject(resourceName) as System.Drawing.Bitmap)
                {
                    if (bitmap != null)
                    {
                        using (var ms = new MemoryStream())
                        {
                            bitmap.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
                            return ms.ToArray();
                        }
                    }
                }
            }
            catch
            {
                // If resource loading fails, return empty array
            }

            return Array.Empty<byte>();
        }

        /// <summary>
        /// Gets an image from a local file as a byte array in PNG format
        /// </summary>
        /// <param name="filePath">The full path and filename of the image file</param>
        /// <param name="isFilePath">Must be set to true to indicate this is a file path (used to differentiate overloads)</param>
        /// <returns>Byte array containing the image in PNG format, or an empty array if the file cannot be loaded</returns>
        private static byte[] GetImageResourceAsByteArray(string filePath, bool isFilePath)
        {
            if (!isFilePath)
            {
                return GetImageResourceAsByteArray(filePath);
            }

            try
            {
                if (!System.IO.File.Exists(filePath))
                {
                    return Array.Empty<byte>();
                }

                using (var bitmap = new System.Drawing.Bitmap(filePath))
                {
                    using (var ms = new MemoryStream())
                    {
                        bitmap.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
                        return ms.ToArray();
                    }
                }
            }
            catch
            {
                // If file loading fails, return empty array
            }

            return Array.Empty<byte>();
        }

        /// <summary>
        /// Creates user credentials for connecting to a Vault server.
        /// </summary>
        /// <param name="server">The IP address or DNS name of the ADMS server.</param>
        /// <param name="vault">The name of the Vault to connect to.</param>
        /// <param name="user">The username for authentication.</param>
        /// <param name="pw">The password for authentication.</param>
        /// <returns>A <see cref="Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials"/> object for the specified server and Vault.</returns>
        public static Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials UserCredentials1(string server, string vault, string user, string pw)
        {
            // Simplify object initialization and ensure platform compatibility
            var mServer = new ServerIdentities
            {
                DataServer = server,
                FileServer = server
            };

            return new Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials(mServer, vault, user, pw);
        }

        /// <summary>
        /// UserCredentials1 and UserCredentials2 differentiate overloads as powershell can't handle
        /// UserCredentials2 returns readonly loginuser object
        /// </summary>
        /// <param name="server">IP Address or DNS Name of ADMS Server</param>
        /// <param name="vault">Name of vault to connect to</param>
        /// <param name="user">User name</param>
        /// <param name="pw">Password</param>
        /// <param name="rw">Set to "True" to allow Read/Write access</param>
        /// <returns></returns>
        public Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials UserCredentials2(string server, string vault, string user, string pw, bool rw = true)
        {
            // Simplify object initialization and ensure platform compatibility
            var mServer = new ServerIdentities
            {
                DataServer = server,
                FileServer = server
            };

            return new Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials(mServer, vault, user, pw, rw);
        }

        /// <summary>
        /// Deprecated - no longer required, as the overload is removed in 2017 API
        /// </summary>
        /// <param name="svc"></param>
        /// <param name="FldIds"></param>
        /// <param name="m_PropArray"></param>
        /// <returns></returns>
        public Boolean UpdateFolderProp2(WebServiceManager svc, long[] FldIds, PropInstParamArray[] m_PropArray)
        {
            try
            {
                svc.DocumentServiceExtensions.UpdateFolderProperties(FldIds, m_PropArray);
                return true;
            }
            catch
            {
                return false;
            }
        }


        /// <summary>
        /// LinkManager.GetLinkedChildren has an override list; the input is of type IEntity. 
        /// This wrapper allows to input commonly known object types, like Ids and entity names instead.
        /// </summary>
        /// <param name="con">The utility dll is not connected to Vault; 
        /// we need to leverage the established connection to call LinkManager methods</param>
        /// <param name="mId">The parent entity's id to get linked children of</param>
        /// <param name="mClsId">The parent entity's class name; allowed values are FILE FLDR and CUSTENT. 
        /// CO and ITEM cannot have linked children, as they use specific links to related child objects.</param>
        /// <param name="mFilter">Limit the search on links to a particular class; providing an empty value "" will result in a search on all types</param>
        /// <returns>List of entity Ids</returns>
        public List<long>? mGetLinkedChildren1(Connection con, long mId, string mClsId, string mFilter)
        {
            IEnumerable<PersistableIdEntInfo> mEntInfo = new PersistableIdEntInfo[] { new PersistableIdEntInfo(mClsId, mId, true, false) };
            IDictionary<PersistableIdEntInfo, IEntity> mIEnts = con.EntityOperations.ConvertEntInfosToIEntities(mEntInfo);
            IEntity? mIEnt = null;
            try
            {
                foreach (var item in mIEnts)
                {
                    mIEnt = item.Value;
                }
                IEnumerable<IEntity> mLinkedChldrn = con.LinkManager.GetLinkedChildren(mIEnt, mFilter);
                //return mLinkedChldrn;
                List<long> mLinkedIds = new List<long>();
                foreach (var item in mLinkedChldrn)
                {
                    mLinkedIds.Add(item.EntityIterationId);
                }
                return mLinkedIds;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Evaluation of overload 2; see mGetLinkedchildren1 for detailed description
        /// </summary>
        /// <param name="con"></param>
        /// <param name="mParEntIds"></param>
        /// <param name="mClsIds"></param>
        /// <returns></returns>
        private static IEnumerable<IEntity>? GetLinkedChildren2(Connection con, long[] mParEntIds, string[] mClsIds)
        {
            List<PersistableIdEntInfo> mEntInfo = new List<PersistableIdEntInfo>();
            for (int i = 0; i < mParEntIds.Length; i++)
            {
                mEntInfo.Add(new PersistableIdEntInfo("CUSTENT", mParEntIds[i], true, false));
            }

            IDictionary<PersistableIdEntInfo, IEntity> mIEnts = con.EntityOperations.ConvertEntInfosToIEntities(mEntInfo.AsEnumerable());
            List<IEntity> mIEnt = new List<IEntity>();
            try
            {
                foreach (var item in mIEnts)
                {
                    mIEnt.Add(item.Value);
                }
                IEnumerable<IEntity> mLinkedChldrn = con.LinkManager.GetLinkedChildren(mIEnt.AsEnumerable(), mClsIds.AsEnumerable());
                return mLinkedChldrn;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Update file properties
        /// </summary>
        /// <param name="conn"></param>
        /// <param name="mFile"></param>
        /// <param name="mPropDictonary"></param>
        /// <returns>True if updated successfully</returns>
        public bool mUpdateFileProperties(VDF.Vault.Currency.Connections.Connection conn,
            Autodesk.Connectivity.WebServices.File mFile, Dictionary<Autodesk.Connectivity.WebServices.PropDef, object> mPropDictonary)
        {
            try
            {
                ACET.IExplorerUtil mExplUtil = Autodesk.Connectivity.Explorer.ExtensibilityTools.ExplorerLoader.LoadExplorerUtil(
                                            conn.Server, conn.Vault, conn.UserID, conn.Ticket);

                mExplUtil.UpdateFileProperties(mFile, mPropDictonary);
                return true;
            }
            catch
            {
                return false;
            }

        }

        /// <summary>
        /// Downloads Vault file using full file path, e.g. "$/Designs/Base.ipt". Returns full file name in local working folder (download enforces override, if local file exists),
        /// returns "FileNotFound if file does not exist at indicated location.
        /// Preset Options: Download Children (recursively) = Enabled, Enforce Overwrite = True
        /// </summary>
        /// <param name="conn">Current Vault Connection</param>
        /// <param name="VaultFullFileName">FullFilePath</param>
        /// <param name="CheckOut">Optional. File downloaded does NOT check-out as default.</param>
        /// <returns>Local path/filename or error statement "FileNotFound"</returns>
        public string mGetFileByFullFileName(VDF.Vault.Currency.Connections.Connection conn, string VaultFullFileName, bool CheckOut = false)
        {
            List<string> mFiles = new List<string>();
            mFiles.Add(VaultFullFileName);
            Autodesk.Connectivity.WebServices.File[] wsFiles = conn.WebServiceManager.DocumentService.FindLatestFilesByPaths(mFiles.ToArray());
            VDF.Vault.Currency.Entities.FileIteration mFileIt = new VDF.Vault.Currency.Entities.FileIteration(conn, (wsFiles[0]));

            VDF.Vault.Settings.AcquireFilesSettings settings = new VDF.Vault.Settings.AcquireFilesSettings(conn);
            if (CheckOut)
            {
                settings.DefaultAcquisitionOption = VDF.Vault.Settings.AcquireFilesSettings.AcquisitionOption.Checkout;
            }
            else
            {
                settings.DefaultAcquisitionOption = VDF.Vault.Settings.AcquireFilesSettings.AcquisitionOption.Download;
            }
            settings.OptionsRelationshipGathering.FileRelationshipSettings.IncludeChildren = true;
            settings.OptionsRelationshipGathering.FileRelationshipSettings.RecurseChildren = true;
            settings.OptionsRelationshipGathering.FileRelationshipSettings.VersionGatheringOption = VDF.Vault.Currency.VersionGatheringOption.Latest;
            settings.OptionsRelationshipGathering.IncludeLinksSettings.IncludeLinks = false;
            VDF.Vault.Settings.AcquireFilesSettings.AcquireFileResolutionOptions mResOpt = new VDF.Vault.Settings.AcquireFilesSettings.AcquireFileResolutionOptions();
            mResOpt.OverwriteOption = VDF.Vault.Settings.AcquireFilesSettings.AcquireFileResolutionOptions.OverwriteOptions.ForceOverwriteAll;
            mResOpt.SyncWithRemoteSiteSetting = VDF.Vault.Settings.AcquireFilesSettings.SyncWithRemoteSite.Always;
            settings.AddFileToAcquire(mFileIt, settings.DefaultAcquisitionOption);
            VDF.Vault.Results.AcquireFilesResults results = conn.FileManager.AcquireFiles(settings);
            if (results != null)
            {
                try
                {
                    VDF.Vault.Results.FileAcquisitionResult mFilesDownloaded = results.FileResults.Last();
                    return mFilesDownloaded.LocalPath.FullPath.ToString();
                }
                catch (Exception)
                {
                    return "FileFoundButDownloadFailed";
                }
            }
            return "FileNotFound";
        }


        /// <summary>
        /// Get the file iteration's properties with Display Names and Values
        /// </summary>
        /// <param name="conn">Current Vault connection ($VaultConnection)</param>
        /// <param name="FileId">File iteration Id</param>
        /// <param name="FileProperties">Name-Value map of Display Name and Values. All Values return as text.</param>
        public void GetFileProps(Connection conn, long FileId, ref Dictionary<string, string> FileProperties)
        {
            PropDef[]? mPropDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE");
            PropInst[]? mSourcePropInsts = conn.WebServiceManager.PropertyService.GetPropertiesByEntityIds("FILE", new long[] { FileId });
            string mPropDispName;
            string mPropVal;
            string mThumbnailDispName = mPropDefs.FirstOrDefault(n => n.SysName == "Thumbnail").DispName;
            foreach (PropInst mFilePropInst in mSourcePropInsts)
            {
                mPropDispName = mPropDefs.FirstOrDefault(n => n.Id == mFilePropInst.PropDefId).DispName;
                //filter thumbnail property
                if (mPropDispName != mThumbnailDispName)
                {
                    if (mFilePropInst.Val == null)
                    {
                        mPropVal = "";
                    }
                    else
                    {
                        mPropVal = mFilePropInst.Val.ToString();
                    }
                    FileProperties.Add(mPropDispName, mPropVal);
                }
            }
        }

        /// <summary>
        /// Get Folder properties with Display Names and Values
        /// </summary>
        /// <param name="conn">Current Vault connection ($VaultConnection)</param>
        /// <param name="FolderId">Folder Id</param>
        /// <param name="FolderProperties">Name-Value map of Display Name and Values. All Values return as text.</param>        
        public void GetFolderProps(Connection conn, long FolderId, ref Dictionary<string, string> FolderProperties)
        {
            PropDef[] mPropDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR");
            PropInst[] mSourcePropInsts = conn.WebServiceManager.PropertyService.GetPropertiesByEntityIds("FLDR", new long[] { FolderId });
            string mPropDispName;
            string mPropVal;

            foreach (PropInst mFilePropInst in mSourcePropInsts)
            {
                mPropDispName = mPropDefs.Where(n => n.Id == mFilePropInst.PropDefId).FirstOrDefault().DispName;

                if (mFilePropInst.Val == null)
                {
                    mPropVal = "";
                }
                else
                {
                    mPropVal = mFilePropInst.Val.ToString();
                }
                FolderProperties.Add(mPropDispName, mPropVal);
            }
        }


        /// <summary>
        /// Get Item properties with Display Names and Values
        /// </summary>
        /// <param name="conn">Current Vault connection ($VaultConnection)</param>
        /// <param name="ItemId">Item Id</param>
        /// <param name="ItemProperties">Name-Value map of Display Name and Values. All Values return as text.</param>
        public void GetItemProps(Connection conn, long ItemId, ref Dictionary<string, string> ItemProperties)
        {
            PropDef[] mPropDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM");
            PropInst[] mSourcePropInsts = conn.WebServiceManager.PropertyService.GetPropertiesByEntityIds("ITEM", new long[] { ItemId });
            string mPropDispName;
            string mPropVal;
            string mThumbnailDispName = mPropDefs.Where(n => n.SysName == "Thumbnail").FirstOrDefault().DispName;
            foreach (PropInst mFilePropInst in mSourcePropInsts)
            {
                mPropDispName = mPropDefs.Where(n => n.Id == mFilePropInst.PropDefId).FirstOrDefault().DispName;
                //filter thumbnail property
                if (mPropDispName != mThumbnailDispName)
                {
                    if (mFilePropInst.Val == null)
                    {
                        mPropVal = "";
                    }
                    else
                    {
                        mPropVal = mFilePropInst.Val.ToString();
                    }
                    ItemProperties.Add(mPropDispName, mPropVal);
                }
            }
        }

        /// <summary>
        /// Get Custom Object properties with Display Names and Values
        /// </summary>
        /// <param name="conn">Current Vault connection ($VaultConnection)</param>
        /// <param name="CustentId">Custom Object Id</param>
        /// <param name="CustentProperties">Name-Value map of Display Name and Values. All Values return as text.</param>

        public void GetCustentProps(Connection conn, long CustentId, ref Dictionary<string, string> CustentProperties)
        {
            PropDef[] mPropDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT");
            PropInst[] mSourcePropInsts = conn.WebServiceManager.PropertyService.GetPropertiesByEntityIds("CUSTENT", new long[] { CustentId });
            string mPropDispName;
            string mPropVal;
            string mThumbnailDispName = mPropDefs.Where(n => n.SysName == "Thumbnail").FirstOrDefault().DispName;
            foreach (PropInst mFilePropInst in mSourcePropInsts)
            {
                mPropDispName = mPropDefs.Where(n => n.Id == mFilePropInst.PropDefId).FirstOrDefault().DispName;
                //filter thumbnail property, as iLogic RuleArguments will fail reading it.
                if (mPropDispName != mThumbnailDispName)
                {
                    if (mFilePropInst.Val == null)
                    {
                        mPropVal = "";
                    }
                    else
                    {
                        mPropVal = mFilePropInst.Val.ToString();
                    }
                    CustentProperties.Add(mPropDispName, mPropVal);
                }
            }
        }

        #region CAD-BOM methods
        /// <summary>
        /// Represents a single row in a Bill of Materials (BOM)
        /// </summary>
        public class BomRow
        {
            public int Position { get; set; }
            public string? PartNumber { get; set; }
            public string? ComponentType { get; set; }
            public float Quantity { get; set; }
            public string? Name { get; set; }
            public byte[]? Thumbnail { get; set; }
            public string? Title { get; set; }
            public string? Description { get; set; }
            public string? Material { get; set; }
            public string? FunctionalDesignation { get; set; }
        }

        /// <summary>
        /// Represents a Bill of Materials containing multiple BOM items
        /// </summary>
        public class Bom
        {
            public List<BomRow> BOMItems { get; set; } = new List<BomRow>();
        }

        /// <summary>
        /// Get model states or configurations from a file's BOM structure
        /// </summary>
        /// <param name="conn">Vault connection</param>
        /// <param name="fileId">File ID to get model states from</param>
        /// <returns>Dictionary of model state names and their IDs</returns>
        public Dictionary<string, long> GetModelStates(Connection conn, long fileId)
        {
            var mFileBOM = conn.WebServiceManager.DocumentService.GetBOMByFileId(fileId);
            var mFile = conn.WebServiceManager.DocumentService.GetFileById(fileId);

            var propDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE");
            var providerPropDef = propDefs.FirstOrDefault(n => n.SysName == "Provider");

            string mCadProvider = "Unknown";
            if (providerPropDef != null)
            {
                var providerProp = conn.WebServiceManager.PropertyService.GetProperties("FILE", new long[] { fileId }, new long[] { providerPropDef.Id })[0];
                var providerValue = providerProp.Val?.ToString();

                if (providerValue?.Contains("Inventor") == true)
                {
                    mCadProvider = "Inventor";
                }
                else if (providerValue?.Contains("SolidWorks") == true)
                {
                    mCadProvider = "SolidWorks";
                }
            }

            var msArray = new List<BOMComp>();

            if (mCadProvider == "SolidWorks")
            {
                msArray = mFileBOM.CompArray.Where(c =>
                    c.XRefId == -1 &&
                    c.UniqueId != null &&
                    c.UniqueId.Contains("@")
                ).ToList();
            }
            else if (mCadProvider == "Inventor")
            {
                msArray = mFileBOM.CompArray.Where(c =>
                    c.XRefId == -1 && (
                        (c.UniqueId != null && c.UniqueId.StartsWith("MS:")) ||
                        (c.Name != null && System.Text.RegularExpressions.Regex.IsMatch(c.Name, @"\[.*\]"))
                    )
                ).ToList();

                // Add the first component as [Primary] if it's not already in the list
                if (mFileBOM.CompArray.Length > 0)
                {
                    var firstComp = mFileBOM.CompArray[0];
                    if (firstComp.XRefId == -1 && !msArray.Contains(firstComp))
                    {
                        msArray.Insert(0, firstComp);
                    }
                }
            }

            var mMdlStates = new Dictionary<string, long>();

            if (msArray.Count > 1)
            {
                foreach (var comp in msArray)
                {
                    string mName = "";

                    if (mCadProvider == "SolidWorks")
                    {
                        if (comp.Name != null)
                        {
                            var nameParts = comp.Name.Split('@');
                            if (nameParts.Length == 2 && nameParts[1] == mFile.Name)
                            {
                                mName = nameParts[0];
                            }
                            else
                            {
                                mName = comp.Name;
                            }
                        }
                    }
                    else if (mCadProvider == "Inventor")
                    {
                        if (comp.Name != null && comp.Name.Contains(" (") && comp.Name.Contains(")"))
                        {
                            int startIndex = comp.Name.IndexOf(" (");
                            int endIndex = comp.Name.IndexOf(")");
                            if (startIndex >= 0 && endIndex > startIndex)
                            {
                                mName = comp.Name.Substring(startIndex + 2, endIndex - startIndex - 2);
                            }
                        }
                        else
                        {
                            mName = "[Primary]";
                        }
                    }

                    if (!string.IsNullOrEmpty(mName) && !mMdlStates.ContainsKey(mName))
                    {
                        mMdlStates.Add(mName, comp.Id);
                    }
                }
            }

            return mMdlStates;
        }

        /// <summary>
        /// Get the BOM structure for a file
        /// </summary>
        /// <param name="conn">Vault connection</param>
        /// <param name="fileId">File ID</param>
        /// <param name="bomCompId">BOM Component ID (use root component or model state ID)</param>
        /// <param name="returnMessage"></param>
        /// <returns>List of BOM items</returns>
        public List<BomRow> GetFileBOM(Connection conn, long fileId, long bomCompId, ref string returnMessage)
        {
            var bomItems = new List<BomRow>();
            ACW.BOM? mFileBom = null;
            try
            {
                mFileBom = conn.WebServiceManager.DocumentService.GetBOMByFileId(fileId);
            }
            catch (Exception)
            {
                // unhandled are changes in the BOM scheme, a new check-in of the file will resolve it in most cases
                returnMessage = "Could not read item data of the file. For legacy files, a new check-in of the file might resolve the issue.";
                return bomItems;
            }

            // return a message if the BOM is empty
            if (mFileBom == null)
            {
                returnMessage = "The file does not contain item data; use 'Extract Item Data' to update." +
                    "\n\nNote - iAssembly Factories don't display BOM data; select a member file instead.";
                return bomItems;
            }

            // return a message if the BOM exists without any active BOM rows
            if (mFileBom.InstArray.Length == 0)
            {
                returnMessage = "The file does not have active BOM rows." +
                    "\n\nNote - iAssembly Factories don't display BOM data; select a member file instead.";
                return bomItems;
            }

            // check for structured BOM scheme and process it; if not found try to process the Model BOM scheme
            BOMSchm? schm = null;
            if (mFileBom.SchmArray != null)
            {
                try
                {
                    schm = mFileBom.SchmArray.FirstOrDefault(s => s.SchmTyp == SchemeTypeEnum.Structured && s.RootCompId == bomCompId);
                }
                catch (Exception) { }

                // if a structured BOM scheme is found for the given component ID, read the structured BOM (Inventor BOM: Structured = Enabled)
                ReadStructuredBom(conn, mFileBom, schm, bomItems);

            }
            else
            {
                // if no structured scheme is found, attempt to read the Model BOM structure (Inventor BOM: Model)
                ReadModelBom(conn, mFileBom, bomItems);
            }

            // reset previously used variable to prevent unintended reuse
            occurrences = null;

            return bomItems.OrderBy(b => b.Position).ToList();
        }


        /// <summary>
        /// Read the model BOM structure (non-structured BOM data)
        /// Replicates the functionality of FileBOM.ps1:GetFileBOM
        /// </summary>
        /// <param name="conn">Vault connection</param>
        /// <param name="fileBom">BOM object retrieved from DocumentService.GetBOMByFileId</param>
        /// <param name="bomItems">List to populate with BOM items</param>
        private void ReadModelBom(Connection conn, ACW.BOM fileBom, List<BomRow> bomItems)
        {
            var propDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE");
            var thumbnailPropDef = propDefs.FirstOrDefault(n => n.SysName == "Thumbnail");

            var cldIds = new List<long>();

            // Get child IDs from instances where ParId equals 0
            var topLevelInsts = fileBom.InstArray?.Where(i => i.ParId == 0).ToList();
            if (topLevelInsts == null || !topLevelInsts.Any())
            {
                return;
            }

            foreach (var inst in topLevelInsts)
            {
                var comp = fileBom.CompArray?.FirstOrDefault(c => c.Id == inst.CldId);
                if (comp != null && comp.XRefId != -1)
                {
                    cldIds.Add(comp.XRefId);
                }
            }

            if (cldIds.Count == 0)
            {
                return;
            }

            ACW.BOM[]? cldBoms = conn.WebServiceManager.DocumentService.GetBOMByFileIds(cldIds.ToArray());
            var schm = fileBom.SchmArray?.FirstOrDefault(s => s.SchmTyp == SchemeTypeEnum.Structured && s.RootCompId == 0);

            int cldBomCounter = 0;

            foreach (var inst in topLevelInsts)
            {
                var bomItem = new BomRow();
                long cldId = inst.CldId;

                bomItem.Quantity = (float)(inst.QuantOverde == -1 ? inst.Quant : inst.QuantOverde);

                var comp = fileBom.CompArray?.FirstOrDefault(c => c.Id == cldId);
                if (comp == null) continue;

                if (schm != null)
                {
                    var occur = fileBom.SchmOccArray?.FirstOrDefault(o => o.SchmId == schm.Id && o.CompId == cldId);
                    if (occur != null)
                    {
                        bomItem.Position = int.TryParse(occur.DtlId, out int pos) ? pos : (int)occur.Id;
                    }
                }
                else
                {
                    bomItem.Position = cldBomCounter + 1;
                }

                ACW.BOM cldBom;
                if (comp.XRefId == -1)
                {
                    cldBom = fileBom;
                }
                else
                {
                    if (cldBoms != null && cldBomCounter < cldBoms.Length)
                    {
                        cldBom = cldBoms[cldBomCounter++];
                    }
                    else
                    {
                        continue;
                    }
                }

                string uniqueId = comp.UniqueId;
                var cldComp = cldBom.CompArray?.FirstOrDefault(c => c.UniqueId == uniqueId && c.XRefId == -1);
                if (cldComp == null && cldBom.CompArray != null && cldBom.CompArray.Length > 0)
                {
                    cldComp = cldBom.CompArray[0];
                }

                if (cldComp != null)
                {
                    bomItem.Name = cldComp.Name;
                    bomItem.ComponentType = cldComp.CompTyp.ToString();

                    var cldCompAttrArray = cldBom.CompAttrArray.Where(ca => ca.CompId == cldComp.Id).ToArray();
                    if (cldCompAttrArray.Length == 0)
                    {
                        cldCompAttrArray = cldBom.CompAttrArray;
                    }

                    if (cldCompAttrArray != null)
                    {
                        var propPartNumber = cldBom.PropArray?.FirstOrDefault(p => p.DispName == "Part Number");
                        if (propPartNumber != null)
                        {
                            var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == propPartNumber.Id);
                            if (prop != null)
                            {
                                bomItem.PartNumber = prop.Val;
                            }
                        }

                        if (cldComp.CompTyp != ComponentTypeEnum.Virtual)
                        {
                            propDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE");
                            thumbnailPropDef = propDefs.FirstOrDefault(n => n.SysName == "Thumbnail");

                            if (thumbnailPropDef != null && comp.XRefId != -1 && cldBomCounter > 0 && cldBomCounter <= cldIds.Count)
                            {
                                var thumbnailProp = conn.WebServiceManager.PropertyService.GetProperties("FILE",
                                    new long[] { cldIds[cldBomCounter - 1] },
                                    new long[] { thumbnailPropDef.Id })[0];
                                bomItem.Thumbnail = thumbnailProp.Val as byte[];
                            }
                        }
                        else
                        {
                            // Load virtual component thumbnail from embedded resource
                            if (_virtualCompThumbnail == null)
                            {
                                _virtualCompThumbnail = GetImageResourceAsByteArray("VirtualComp_32");
                            }

                            bomItem.Thumbnail = _virtualCompThumbnail;
                        }

                        var titleProp = cldBom.PropArray?.FirstOrDefault(p => p.DispName == "Title");
                        if (titleProp != null)
                        {
                            var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == titleProp.Id);
                            if (prop != null)
                            {
                                bomItem.Title = prop.Val;
                            }
                        }

                        var descProp = cldBom.PropArray?.FirstOrDefault(p => p.DispName == "Description");
                        if (descProp != null)
                        {
                            var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == descProp.Id);
                            if (prop != null)
                            {
                                bomItem.Description = prop.Val;
                            }
                        }

                        var matProp = cldBom.PropArray?.FirstOrDefault(p => p.DispName == "Material");
                        if (matProp != null)
                        {
                            var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == matProp.Id);
                            if (prop != null)
                            {
                                bomItem.Material = prop.Val;
                            }
                        }
                    }
                }

                bomItems.Add(bomItem);
            }
        }


        /// <summary>
        /// Process a BOM level (recursively if needed in future)
        /// </summary>
        private void ReadStructuredBom(Connection conn, ACW.BOM parentBom, ACW.BOMSchm schm, List<BomRow> bomItems)
        {
            // read the occurrences for the current level; filter on ParOccurId = -1 to get only the top-level occurrences for the given component or model state
            try
            {
                occurrences = parentBom.SchmOccArray.Where(o => o.SchmId == schm.Id && o.ParOccurId == -1).ToList();
                // return if no occurrences are found for the given BOM scheme
                if (occurrences == null || !occurrences.Any())
                {
                    return;
                }
            }
            catch (Exception)
            {
                return;
            }

            var cldIds = new List<long>();
            foreach (BOMSchmOccur occur in occurrences)
            {
                var comp = parentBom.CompArray.FirstOrDefault(c => c.Id == occur.CompId);
                if (comp != null && comp.XRefId != -1)
                {
                    cldIds.Add(comp.XRefId);
                }
            }

            ACW.BOM[]? cldBoms = null;
            if (cldIds.Count > 0)
            {
                cldBoms = conn.WebServiceManager.DocumentService.GetBOMByFileIds(cldIds.ToArray());
            }

            int cldBomCounter = 0;

            foreach (BOMSchmOccur occur in occurrences)
            {
                var comp = parentBom.CompArray.FirstOrDefault(c => c.Id == occur.CompId);
                if (comp == null) continue;

                var inst = parentBom.InstArray.FirstOrDefault(i => i.CldId == occur.CompId);
                if (inst == null) continue;

                ACW.BOM cldBom;
                if (comp.XRefId == -1)
                {
                    cldBom = parentBom;
                }
                else
                {
                    if (cldBoms != null && cldBomCounter < cldBoms.Length)
                    {
                        cldBom = cldBoms[cldBomCounter++];
                    }
                    else
                    {
                        continue;
                    }
                }

                var bomItem = new BomRow();

                bomItem.Quantity = (float)(inst.QuantOverde == -1 ? inst.Quant : inst.QuantOverde);

                if (int.TryParse(occur.DtlId, out int position))
                {
                    bomItem.Position = position;
                }
                else
                {
                    bomItem.Position = (int)occur.Id;
                }

                string uniqueId = comp.UniqueId;
                var cldComp = cldBom.CompArray.FirstOrDefault(c => c.UniqueId == uniqueId && c.XRefId == -1);
                if (cldComp == null && cldBom.CompArray.Length > 0)
                {
                    cldComp = cldBom.CompArray[0];
                }

                if (cldComp != null)
                {
                    bomItem.Name = cldComp.Name;
                    bomItem.ComponentType = cldComp.CompTyp.ToString();

                    var cldCompAttrArray = cldBom.CompAttrArray.Where(ca => ca.CompId == cldComp.Id).ToArray();
                    if (cldCompAttrArray.Length == 0)
                    {
                        cldCompAttrArray = cldBom.CompAttrArray;
                    }

                    var propPartNumber = cldBom.PropArray.FirstOrDefault(p => p.DispName == "Part Number");
                    if (propPartNumber != null)
                    {
                        var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == propPartNumber.Id);
                        if (prop != null)
                        {
                            bomItem.PartNumber = prop.Val;
                        }
                    }

                    if (cldComp.CompTyp != ComponentTypeEnum.Virtual)
                    {
                        var propDefs = conn.WebServiceManager.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE");
                        var thumbnailPropDef = propDefs.FirstOrDefault(n => n.SysName == "Thumbnail");

                        if (thumbnailPropDef != null && comp.XRefId != -1 && cldBomCounter > 0 && cldBomCounter <= cldIds.Count)
                        {
                            var thumbnailProp = conn.WebServiceManager.PropertyService.GetProperties("FILE",
                                new long[] { cldIds[cldBomCounter - 1] },
                                new long[] { thumbnailPropDef.Id })[0];
                            bomItem.Thumbnail = thumbnailProp.Val as byte[];
                        }
                    }
                    else
                    {
                        // Load virtual component thumbnail from embedded resource
                        if (_virtualCompThumbnail == null)
                        {
                            _virtualCompThumbnail = GetImageResourceAsByteArray("VirtualComp_32");
                        }

                        bomItem.Thumbnail = _virtualCompThumbnail;
                    }

                    var titleProp = cldBom.PropArray.FirstOrDefault(p => p.DispName == "Title");
                    if (titleProp != null)
                    {
                        var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == titleProp.Id);
                        if (prop != null)
                        {
                            bomItem.Title = prop.Val;
                        }
                    }

                    var descProp = cldBom.PropArray.FirstOrDefault(p => p.DispName == "Description");
                    if (descProp != null)
                    {
                        var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == descProp.Id);
                        if (prop != null)
                        {
                            bomItem.Description = prop.Val;
                        }
                    }

                    var matProp = cldBom.PropArray.FirstOrDefault(p => p.DispName == "Material");
                    if (matProp != null)
                    {
                        var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == matProp.Id);
                        if (prop != null)
                        {
                            bomItem.Material = prop.Val;
                        }
                    }

                    // Function Designation is a bom row property in Vault, and optionally an instance property in Inventor; we need to to handle both cases to get the value if it exists
                    var funcProp = parentBom.PropArray.FirstOrDefault(p => p.DispName == "Functional Designation");
                    if (funcProp != null)
                    {
                        var instProp = parentBom.InstPropArray.FirstOrDefault(i => i.InstId == occur.Id);
                        if (instProp != null)
                        {
                            bomItem.FunctionalDesignation = instProp.Val;
                        }
                        else // no instance property, check for a component property
                        {
                            var compProp = cldBom.PropArray.FirstOrDefault(p => p.DispName == "Functional Designation");
                            if (compProp != null)
                            {
                                var prop = cldCompAttrArray.FirstOrDefault(ca => ca.PropId == compProp.Id);
                                if (prop != null)
                                {
                                    bomItem.FunctionalDesignation = prop.Val;
                                }
                            }
                        }
                    }

                    // Check if we need to process nested BOM structure
                    // Add criteria here to determine if we should iterate cldBom occurrences
                    if (ShouldProcessNestedBOM(cldComp, cldBom))
                    {
                        var nestedSchm = cldBom.SchmArray.FirstOrDefault(s => s.SchmTyp == SchemeTypeEnum.Structured && s.RootCompId == cldComp.Id);
                        if (nestedSchm != null)
                        {
                            ReadStructuredBom(conn, cldBom, nestedSchm, bomItems);
                        }
                    }
                }

                bomItems.Add(bomItem);
            }
        }

        /// <summary>
        /// Determines if a nested BOM should be processed
        /// </summary>
        private bool ShouldProcessNestedBOM(ACW.BOMComp component, ACW.BOM bom)
        {
            // Add your criteria here to determine if nested iteration is needed
            // Example criteria:
            // - Component type check
            // - Specific property values
            // - Number of child components

            // Default: don't process nested BOMs
            return false;
        }

        #endregion CAD-BOM methods

    }

    /// <summary>
    /// Class sharing options to interact with hosting Inventor session
    /// </summary>
    public class InvHelpers
    {
        Inventor.Application m_Inv = null;
        Inventor.Document m_Doc = null;
        Inventor.DrawingDocument m_DrawDoc = null;
        Inventor.PresentationDocument m_IpnDoc = null;
        String m_ModelPath = null;
        Inventor.CommandManager m_InvCmdMgr = null;

        [System.Runtime.InteropServices.DllImport("User32.dll", SetLastError = true)]
        static extern void SwitchToThisWindow(IntPtr hWnd, bool fAltTab);

        /// <summary>
        /// Retrieve property value of main view referenced model
        /// </summary>
        /// <param name="m_InvApp">Connect to the hosting instance of the VDS dialog</param>
        /// <param name="m_ViewModelFullName"></param>
        /// <param name="m_PropName">Display Name</param>
        /// <returns></returns>
        public object m_GetMainViewModelPropValue(object m_InvApp, String m_ViewModelFullName, String m_PropName)
        {
            try
            {
                m_Inv = (Inventor.Application)m_InvApp;
                m_Doc = m_Inv.Documents.Open(m_ViewModelFullName, false);
                foreach (PropertySet m_PropSet in m_Doc.PropertySets)
                {
                    foreach (Property m_Prop in m_PropSet)
                    {
                        if (m_Prop.Name == m_PropName)
                        {
                            return m_Prop.Value;
                        }
                    }
                }
            }
            catch (Exception)
            {
                throw;
            }
            return null;
        }

        /// <summary>
        /// Gets the 3D model (ipt/iam/ipn) linked to the main view of the current (active) drawing.
        /// Gets the 3D model (iam) linked to the main view of the current (active) presentation.
        /// </summary>
        /// <param name="m_InvApp">Running host (instance of Inventor) of calling VDS Dialog.</param>
        /// <returns>Returns the fullfilename (path and filename incl. extension) of the referenced model as string.</returns>
        public String m_GetMainViewModelPath(object m_InvApp)
        {
            try
            {
                m_Inv = (Inventor.Application)m_InvApp;

                if (m_Inv.ActiveDocumentType == DocumentTypeEnum.kDrawingDocumentObject)
                {
                    m_DrawDoc = (DrawingDocument)m_Inv.ActiveDocument;
                    Sheet m_Sheet = m_DrawDoc.ActiveSheet;
                    DrawingView m_DrwView = m_Sheet.DrawingViews[1];
                    if (!(m_DrwView is null))
                    {
                        m_ModelPath = m_DrwView.ReferencedFile.FullFileName;
                        return m_ModelPath;
                    }
                }

                if (m_Inv.ActiveDocumentType == DocumentTypeEnum.kPresentationDocumentObject)
                {
                    m_IpnDoc = (PresentationDocument)m_Inv.ActiveDocument;
                    if (m_IpnDoc.ReferencedDocuments.Count >= 1)
                    {
                        m_ModelPath = m_IpnDoc.ReferencedDocuments[1].FullDocumentName;
                        return m_ModelPath;
                    }
                }
                return null;
            }
            catch (Exception)
            {
                return null;
            }
        }

        /// <summary>
        /// Delete orphaned drawing sheets. Sheet format consuming workflows likely cause an unused sheet1
        /// </summary>
        /// <param name="m_InvApp">Inventor Application ($Application)</param>
        /// <returns>false on unhandled errors, else true</returns>
        public bool m_RemoveOrphanedSheets(object m_InvApp)
        {
            try
            {
                m_Inv = (Inventor.Application)m_InvApp;

                if (m_Inv.ActiveDocumentType == DocumentTypeEnum.kDrawingDocumentObject)
                {
                    m_DrawDoc = (DrawingDocument)m_Inv.ActiveDocument;
                    foreach (Sheet sheet in m_DrawDoc.Sheets)
                    {
                        if (sheet.DrawingViews.Count == 0 && sheet != m_DrawDoc.ActiveSheet)
                        {
                            sheet.Delete(false);
                        }
                    }
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Return running Inventor application
        /// </summary>
        /// <returns></returns>
        public Inventor.Application? m_InventorApplication()
        {
            // Try to get an active instance of Inventor
            try
            {
                return MarshalCore.GetActiveObject("Inventor.Application") as Inventor.Application;
            }
            catch
            {
                return null;
            }
        }


        /// <summary>
        /// Return active Inventor document
        /// </summary>
        /// <param name="m_InvApp">Inventor Application ($Application)</param>
        /// <returns></returns>
        public string m_ActiveDocFullFileName(object m_InvApp)
        {
            m_Inv = (Inventor.Application)m_InvApp;
            if (m_Inv.ActiveDocument != null)
            {
                return m_Inv.ActiveDocument.FullFileName;
            }
            else
            {
                return null;
            }

        }


        /// <summary>
        /// Place component in active Inventor assembly document; deprecated: VDS includes 'Insert to CAD' as a default.
        /// </summary>
        /// <param name="m_InvApp"></param>
        /// <param name="m_CompFullFileName"></param>
        public void m_PlaceComponent(object m_InvApp, String m_CompFullFileName)
        {
            m_Inv = (Inventor.Application)m_InvApp;
            if (m_Inv.ActiveDocumentType == DocumentTypeEnum.kAssemblyDocumentObject)
            {
                try
                {
                    m_InvCmdMgr = m_Inv.CommandManager;
                    m_InvCmdMgr.PostPrivateEvent(PrivateEventTypeEnum.kFileNameEvent, m_CompFullFileName);
                    Inventor.ControlDefinition m_InvCtrlDef = (ControlDefinition)m_InvCmdMgr.ControlDefinitions["AssemblyPlaceComponentCmd"];
                    //bring Inventor to front
                    IntPtr mWinPt = (IntPtr)m_Inv.MainFrameHWND;
                    SwitchToThisWindow(mWinPt, true);
                    m_InvCtrlDef.Execute();
                }
                catch
                {

                }
            }
        }


        /// <summary>
        /// validate active Factory Design Utility AddIn
        /// </summary>
        /// <param name="mInvApp">Inventor Application ($Application)</param>
        /// <returns></returns>
        public bool m_FDUActive(object mInvApp)
        {
            m_Inv = (Inventor.Application)mInvApp;
            try
            {
                ApplicationAddIn mFDUAddIn = m_Inv.ApplicationAddIns.get_ItemById("{031C8B05-13C0-4C6C-B8FD-5A19DACCB64F}");
                if (mFDUAddIn != null)
                {
                    if (mFDUAddIn.Activated)
                    {
                        return true;
                    }
                }
                return false;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Return FDU key/value pairs to identify Factory Layout or Factory Asset files
        /// </summary>
        /// <param name="m_InvApp">Inventor Application ($Application)</param>
        /// <param name="mFdsKeys">empty dictonary</param>
        /// <returns></returns>
        public Dictionary<string, string> m_GetFdsKeys(object m_InvApp, Dictionary<string, string> mFdsKeys)
        {
            try
            {
                m_Inv = (Inventor.Application)m_InvApp;
                m_Doc = m_Inv.ActiveDocument;
                if (m_Doc != null)
                {
                    if (m_Doc.DocumentInterests.HasInterest("factory.filetype.factory_layout_template"))
                    {
                        //FDS Type
                        mFdsKeys.Add("FdsType", "FDS-Layout");

                        //FDS Property Set exists for syncronized layouts
                        foreach (PropertySet m_PropSet in m_Doc.PropertySets)
                        {
                            if (m_PropSet.Name == "autodesk.factory.inventor.DwgInv")
                            {
                                foreach (Property m_Prop in m_PropSet)
                                {
                                    mFdsKeys.Add(m_Prop.Name, (string)m_Prop.Value);
                                }
                                //Get Fullname set by synchronization, to avoid save to other location
                                mFdsKeys.Add("FdsNewFullFileName", m_Doc.File.FullFileName);
                                System.IO.FileInfo mFdsFileInfo = new System.IO.FileInfo(m_Doc.File.FullFileName);
                                string mFdsPath = mFdsFileInfo.Directory.FullName;
                                mFdsKeys.Add("FdsNewPath", mFdsPath);
                            }
                        }
                    }
                    if (m_Doc.DocumentInterests.HasInterest("factory.filetype.factory_asset"))
                    {
                        mFdsKeys.Add("FdsType", "FDS-Asset");
                    }
                }
            }
            catch (Exception)
            {
                throw;
            }
            return mFdsKeys;
        }

        /// <summary>
        /// Return custom iPropertyset for AutoCAD files handled by Inventor FDU
        /// </summary>
        /// <param name="m_InvApp">Inventor Application ($Application)</param>
        /// <param name="mFdsKeys">empty Dictonary of String, String</param>
        /// <returns></returns>
        public Dictionary<string, string> m_GetFdsAcadProps(object m_InvApp, Dictionary<string, string> mFdsKeys)
        {
            Inventor.Document mDwgSource = null;
            DefaultNonInventorDWGFileOpenBehaviorEnum mUserOpenOpt = DefaultNonInventorDWGFileOpenBehaviorEnum.kRegularOpenNonInventorDWGFile;

            try
            {
                m_Inv = (Inventor.Application)m_InvApp;
                m_Doc = m_Inv.ActiveDocument;
                if (m_Doc.DocumentInterests.HasInterest("factory.filetype.factory_layout_template"))
                {
                    //FDS Type
                    mFdsKeys.Add("FdsType", "FDS-Layout");

                    //FDS Property Set exists for syncronized layouts
                    foreach (PropertySet m_PropSet in m_Doc.PropertySets)
                    {
                        if (m_PropSet.Name == "autodesk.factory.inventor.DwgInv")
                        {
                            foreach (Property m_Prop in m_PropSet)
                            {
                                mFdsKeys.Add(m_Prop.Name, (string)m_Prop.Value);
                            }

                            //Get Fullname set by synchronization, to avoid save to other location
                            mFdsKeys.Add("FdsNewFullFileName", m_Doc.File.FullFileName);
                            System.IO.FileInfo mFdsFileInfo = new System.IO.FileInfo(m_Doc.File.FullFileName);
                            string mFdsPath = mFdsFileInfo.Directory.FullName;
                            mFdsKeys.Add("FdsNewPath", mFdsPath);

                            if (m_Doc.FileSaveCounter >= 0) //if save counter = 0, the file is currently in the sync process; we must not open the sync source then.
                            {
                                //Open the source DWG to read properties;
                                try
                                {
                                    string mFdsSourceFullFileName = mFdsPath + "\\" + mFdsKeys["DwgFileName"];
                                    //read inventor application option to reset later
                                    mUserOpenOpt = m_Inv.DrawingOptions.DefaultNonInventorDWGFileOpenBehavior;
                                    m_Inv.DrawingOptions.DefaultNonInventorDWGFileOpenBehavior = DefaultNonInventorDWGFileOpenBehaviorEnum.kRegularOpenNonInventorDWGFile;
                                    mDwgSource = m_Inv.Documents.Open(mFdsSourceFullFileName, false);
                                    //Read the properties and add to dictionary if a value exists
                                    foreach (PropertySet m_TempPropSet in mDwgSource.PropertySets)
                                    {
                                        if (m_TempPropSet.DisplayName.Contains("Summary") || m_TempPropSet.DisplayName == "User Defined Properties")
                                        {
                                            foreach (Property m_TempProp in m_TempPropSet)
                                            {
                                                if (!string.IsNullOrEmpty((string)m_TempProp.Value))
                                                {
                                                    mFdsKeys.Add(m_TempProp.Name, (string)m_TempProp.Value);
                                                }
                                            }
                                        }
                                    }

                                }
                                catch (Exception)
                                {
                                    //throw;
                                }
                                finally
                                {
                                    mDwgSource.Close(true);
                                    //reset application option
                                    m_Inv.DrawingOptions.DefaultNonInventorDWGFileOpenBehavior = mUserOpenOpt;
                                }
                            }
                            else
                            {
                                mFdsKeys.Add("FdsAcadProps", "We can't retrieve properties before the calling file is saved.");
                            }
                        }
                    }
                }
                if (m_Doc.DocumentInterests.HasInterest("factory.filetype.factory_asset"))
                {
                    mFdsKeys.Add("FdsType", "FDS-Asset");
                }
            }
            catch (Exception)
            {
                throw;
            }
            return mFdsKeys;
        }

    }

    /// <summary>
    /// /// Class sharing options to interact with hosting AutoCAD session
    /// </summary>
    public class AcadHelpers
    {
        AcInterop.AcadApplication? mAcad = null;
        private const string progID = "AutoCAD.Application";
        AcInterop.AcadDocument? mAcDoc = null;

        [System.Runtime.InteropServices.DllImport("User32.dll", SetLastError = true)]
        static extern void SwitchToThisWindow(IntPtr hWnd, bool fAltTab);

        /// <summary>
        /// Get AutoCAD session hosting; deprecated as VDS >2017 dialogs share the hosting application object
        /// </summary>
        /// <returns></returns>
        private Boolean m_ConnectAcad()
        {
            try
            {
                mAcad = MarshalCore.GetActiveObject("AutoCAD.Application") as AcInterop.AcadApplication;
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Check for FDS Blocks in AutoCAD drawings
        /// </summary>
        /// <param name="m_AcadApp">AutoCAD Application ($Application)</param>
        /// <returns>True for Blocknames containing "FDS"</returns>
        public Boolean mFdsDrawing(object m_AcadApp)
        {
            mAcad = (AcInterop.AcadApplication)m_AcadApp;
            mAcDoc = mAcad.ActiveDocument;
            AcInteropCom.AcadDatabase m_AcDB = (dynamic)mAcDoc.Database;
            AcInteropCom.AcadSummaryInfo m_AcSummInfo = m_AcDB.SummaryInfo;
            foreach (AcInteropCom.AcadBlock mBlock in mAcDoc.Blocks)
            {
                if (mBlock.Name.Contains("FDS"))
                {
                    return true;
                }
                ;
            }
            return false;
        }


        private Boolean mFdsDict(object m_AcadApp)
        {
            mAcad = (AcInterop.AcadApplication)m_AcadApp;
            mAcDoc = mAcad.ActiveDocument;
            AcInteropCom.AcadDatabase m_AcDB = mAcDoc.Database;

            return false;
        }


        /// <summary>
        /// Switch running AutoCAD application
        /// </summary>
        /// <param name="m_AcadApp">AutoCAD Application ($Application)</param>
        private void m_GoToAcad(object m_AcadApp)
        {
            try
            {
                mAcad = (AcInterop.AcadApplication)m_AcadApp;
                mAcDoc = mAcad.ActiveDocument;
                IntPtr mWinPt = (IntPtr)mAcad.HWND;
                SwitchToThisWindow(mWinPt, true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex.Message);
            }

        }
    }
}

