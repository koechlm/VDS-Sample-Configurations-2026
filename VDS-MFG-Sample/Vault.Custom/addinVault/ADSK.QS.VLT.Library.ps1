# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


# retrieve property value given by displayname from folder (ID)
# don't use repeatetly for multiple properties and use the mGetAllFolderProperties method instead
function mGetFolderPropValue ([Int64] $mFldID, [STRING] $mDispName)
{
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	} 
	$mPropDef = $propDefs | Where-Object { $_.DispName -eq $mDispName}
	$mEntIDs = @()
	$mEntIDs += $mFldID
	$mPropDefIDs = @()
	$mPropDefIDs += $mPropDef.Id
	$mProp = $vault.PropertyService.GetProperties("FLDR",$mEntIDs, $mPropDefIDs)
	$mProp | Where-Object { $mPropVal = $_.Val }
	Return $mPropVal
}

#Get parent folder object
function mGetParentFldrByCat ($Category)
{
	$mWindowName = $dsWindow.Name
	switch ($mWindowName) {
		"FileWindow" {
			$mPath = $Prop["_FilePath"].Value
		}
		"FolderWindow" {
			$mPath = $Prop["_FolderPath"].Value
		}
	}

	$mFld = $vault.DocumentService.GetFolderByPath($mPath)
	if ($mFld) {
		IF ($mFld.Cat.CatName -eq $Category) { $Global:mFldrFound = $true}
		ElseIf ($mPath -ne "$"){
			Do {
				$mParID = $mFld.ParID
				$mFld = $vault.DocumentService.GetFolderByID($mParID)
				IF ($mFld.Cat.CatName -eq $Category) { $Global:mFldrFound = $true}
			} Until (($mFld.Cat.CatName -eq $Category) -or ($mFld.FullName -eq "$"))
		}
	
		If ($mFldrFound -eq $true) {
			return $mFld
		}
		Else{
			return $null
		}
	}
	else{
		return $null
	}

}

#retrieve the definition ID for given property by displayname
function mGetFolderPropertyDefId ([STRING] $mDispName) {
	return mGetPropertyDefId $mDispName "FLDR"
}

# retrieve property value given by displayname from Custom Object (ID)
# don't use repeatetly for multiple properties and use the mGetAllCustentProperties method instead
function mGetCustentPropValue ([Int64] $mCentID, [STRING] $mDispName)
{
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	} 
	$mPropDef = $propDefs | Where-Object { $_.DispName -eq $mDispName}
	$mEntIDs = @()
	$mEntIDs += $mCentID
	$mPropDefIDs = @()
	$mPropDefIDs += $mPropDef.Id
	$mProp = $vault.PropertyService.GetProperties("CUSTENT",$mEntIDs, $mPropDefIDs)
	$mProp | Where-Object { $mPropVal = $_.Val }
	Return $mPropVal
}

#retrieve the definition ID for given property by displayname
function mGetCustentPropertyDefId ([STRING] $mDispName) {
	return mGetPropertyDefId $mDispName "CUSTENT"
}

function mGetCOPropertyDefId ([STRING] $mDispName) {
	Return mGetPropertyDefId $mDispName "CO"
}

#retrieve the definition ID for given property by displayname
function mGetPropertyDefId ([STRING] $mDispName,[STRING] $EntityClassId ) {
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("$EntityClassId")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	} 
	$mPropDef = $propDefs | Where-Object { $_.DispName -eq $mDispName}
	Return $mPropDef.Id
}

#retrieve Category definition ID by display name
function mGetCategoryDef ([String] $mEntType, [String] $mDispName)
{
	$mEntityCategories = $vault.CategoryService.GetCategoriesByEntityClassId($mEntTyp, $true)
	$mEntCatId = ($mEntityCategories | Where-Object {$_.Name -eq $mDispName }).ID
	return $mEntCatId
}

#update a folder property (single). Parameters: Folder ID, UDP display name and UDP value
function mUpdateFldrProperties([Long] $FldId, [String] $mDispName, [Object] $mVal)
{
	$ent_idsArray = @()
	$ent_idsArray += $FldId
	$propInstParam = New-Object Autodesk.Connectivity.WebServices.PropInstParam
	$propInstParamArray = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray
	$mPropDefId = mGetFolderPropertyDefId $mDispName
 	$propInstParam.PropDefId = $mPropDefId
	$propInstParam.Val = $mVal
	$propInstParamArray.Items += $propInstParam
	$propInstParamArrayArray += $propInstParamArray
	Try{
        $vault.DocumentServiceExtensions.UpdateFolderProperties($ent_idsArray, $propInstParamArrayArray)
	    return $true
    }
    catch { return $false}
}

# update a Custom Object (custent) property (single).
function mUpdateCustentProperties([Long] $CustentId, [String] $mDispName, [Object] $mVal)
{
	$ent_idsArray = @()
	$ent_idsArray += $CustentId
	$propInstParam = New-Object Autodesk.Connectivity.WebServices.PropInstParam
	$propInstParamArray = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray
	$mPropDefId = mGetCustentPropertyDefId $mDispName
 	$propInstParam.PropDefId = $mPropDefId
	$propInstParam.Val = $mVal
	$propInstParamArray.Items += $propInstParam
	$propInstParamArrayArray += $propInstParamArray
	Try{
		$vault.CustomEntityService.UpdateCustomEntityProperties($ent_idsArray, $propInstParamArrayArray)
	    return $true
	}
	catch { return $false}
}


#show current runspace ID as input parameter to be used in step by step debugging
function ShowRunspaceID
{
            $id = [runspace]::DefaultRunspace.Id
            $app = [System.Diagnostics.Process]::GetCurrentProcess()
            [System.Windows.Forms.MessageBox]::Show("application: $($app.name)"+[Environment]::NewLine+"runspace ID: $id")
}

#create folder structure based on seqential file numbering; 
# parameters: Filenumber (has to be number in string format) and number of files per folder as digit, e.g. 3 for max. 999 files.
function mGetFolderNumber($_FileNumber, $_nChar)
{
	#$_FileNumber = "1000000"
	$_l = $_FileNumber.Length
	#$_nChar = 3 # number of files per folder
	$_nO = [math]::Ceiling( $_FileNumber.Length/$_nChar)
	$_NumberArray = @()
	$_d = 0
	$_n = 0

	do{
	if ($_l-$_nChar -ge 0) { 
			$_NumberArray += $_FileNumber.Substring($_l-$_nChar,$_nChar)
		}
		else {
			if ($_d -gt 0) {
				$_NumberArray += $_FileNumber.Substring(0, $_d)
			}
		}
		$_l -= $_nChar
		$_d = $_FileNumber.Length-(($_n+1)*$_nChar)
		$_n +=1
	}
	while ($_n -le $_nO+1) 

	$_Folders = @()
	for ($_i = 1; $_i -lt $_NumberArray.Count; $_i++)
	{
		if ($_NumberArray[$_i] -eq "000") { $_Folder = 0 }
		else { [int16]$_Folder = $_NumberArray[$_i] }
		$_Folders += $_Folder
	}

	$_ItemFilePath = "$/xDMS/"
	for ($_i = 0; $_i -lt $_Folders.Count; $_i++) {
		$_ItemFilePath = $_ItemFilePath + $_Folders[$_i] + "/"
	}
	return $_ItemFilePath

} #end function mGetFolderNumber


# VDS Dialogs and Tabs share UIString according DSLanguage.xml override or default powerShell UI culture;
# VDS MenuCommand scripts don't read as a default; call this function in case $UIString[] key value pairs are needed
function mGetUIOverride
{
	[xml]$mDSLangFile = Get-Content "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault\DSLanguages.xml"
	$mUICodes = $mDSLangFile.SelectNodes("/DSLanguages/Language_Code")
	$mLCode = @{}
	Foreach ($xmlAttr in $mUICodes)
	{
		$mKey = $xmlAttr.ID
		$mValue = $xmlAttr.InnerXML
		$mLCode.Add($mKey, $mValue)
	}
	return $mLCode
}

# client and server (database) languages may differ; read the enforced language code to capture multilanguage labels
function mGetDBOverride
{
	[xml]$mDSLangFile = Get-Content "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault\DSLanguages.xml"
	$mUICodes = $mDSLangFile.SelectNodes("/DSLanguages/Language_Code")
	$mLCode = @{}
	Foreach ($xmlAttr in $mUICodes)
	{
		$mKey = $xmlAttr.ID
		$mValue = $xmlAttr.InnerXML
		$mLCode.Add($mKey, $mValue)
	}
	return $mLCode
}

# not all VDS powershell runspaces provide the multi-language labels $UIStrings
# call this function in case $UIStrings[] key value pairs are needed but not available
function mGetUIStrings
{
	# check language override settings of VDS
	$mLCode = @{}
	$mLCode += mGetUIOverride
	#If override exists, apply it, else continue with $PSUICulture
	If ($mLCode["UI"]){
		$mVdsUi = $mLCode["UI"]
	} 
	Else{$mVdsUi=$PSUICulture}
	[xml]$mUIStrFile = get-content ("C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\" + $mVdsUi + "\UIStrings.xml")
	$UIString = @{}
	$xmlUIStrs = $mUIStrFile.SelectNodes("/UIStrings/UIString")
	Foreach ($xmlAttr in $xmlUIStrs) {
		$mKey = $xmlAttr.ID
		$mValue = $xmlAttr.InnerXML
		try{
			$UIString.Add($mKey, $mValue)
		}
		catch{
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Failed adding this UIString $mKey; please check the source file for duplicate keys." , "Vault VDS Client")
		}
	}
	return $UIString
}

# VDS Dialogs and Tabs share property name translations $Prop[_XLTN_*] according DSLanguage.xml override or default powerShell UI culture;
# VDS MenuCommand scripts don't read as a default; call this function in case $PropertyTranslations[] key value pairs are needed
function mGetPropTranslations
{
	# check language override settings of VDS
	$mLCode = @{}
	$mLCode += mGetDBOverride
	#If override exists, apply it, else continue with $PSUICulture
	If ($mLCode["DB"]){
		$mVdsDb = $mLCode["DB"]
	} 
	Else{
		$mVdsDb=$PSUICulture
	}
	[xml]$mPrpTrnsltnFile = get-content ("C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\" + $mVdsDb + "\PropertyTranslations.xml")
	$mPrpTrnsltns = @{}
	$xmlPrpTrnsltns = $mPrpTrnsltnFile.SelectNodes("/PropertyTranslations/PropertyTranslation")
	Foreach ($xmlAttr in $xmlPrpTrnsltns) {
		$mKey = $xmlAttr.Name
		$mValue = $xmlAttr.InnerXML
		try {
			$mPrpTrnsltns.Add($mKey, $mValue)
		}
		catch{
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Failed adding the Property Translation $mKey; please check the source file for duplicate keys." , "Vault VDS Client")
		}		
	}
	return $mPrpTrnsltns
}

# create Thin Client Link for a file; VDS does not provide a file object in DataSheets but the full path in _EditMode
function Adsk.CreateTcFileLink([string]$FileFullVaultPath )
{
	$file = $vault.DocumentService.FindLatestFilesByPaths(@($FileFullVaultPath))[0]
	$serverUri = [System.Uri]$Vault.InformationService.Url			
	$TcFileMasterLink = "$($serverUri.Scheme)://$($VaultConnection.Server)/AutodeskTC/$($VaultConnection.Vault)/explore/file/$($file.MasterId)"
	return $TcFileMasterLink
}

# create Thin Client Link for a folder; VDS does not provide a folder object DataSheets but the full path in _EditMode
function Adsk.CreateTcFolderLink([string]$FolderFullVaultPath)
{
	$folder = $vault.DocumentService.GetFolderByPath($FolderFullVaultPath)
	$serverUri = [System.Uri]$Vault.InformationService.Url			
	$TcFolderLink = "$($serverUri.Scheme)://$($VaultConnection.Server)/AutodeskTC/$($VaultConnection.Vault)/explore/folder/$($folder.Id)"
	return $TcFolderLink
}

# create Thin Client Link for an item; 
function Adsk.CreateTcItemLink ([Long]$ItemMasterId)
{
	$serverUri = [System.Uri]$Vault.InformationService.Url
	$TcItemMasterLink = "$($serverUri.Scheme)://$($VaultConnection.Server)/AutodeskTC/$($VaultConnection.Vault)/items/item/$($ItemMasterId)"
	return $TcItemMasterLink
}

# create Thin Client Link for an item of a given file
function Adsk.CreateTcFileItemLink ([string]$FileFullVaultPath )
{
	$file = $vault.DocumentService.FindLatestFilesByPaths(@($FileFullVaultPath))[0]
	#get item of the file
	$item = $vault.ItemService.GetItemsByFileId($file.Id)[0]
	#create TC link
	$serverUri = [System.Uri]$Vault.InformationService.Url
	$TcFileItemMasterLink = "$($serverUri.Scheme)://$($VaultConnection.Server)/AutodeskTC/$($VaultConnection.Vault)/items/item/$($item.MasterId)"
	return $TcFileItemMasterLink
}

# create Thin Client Link for ECO of a given file
function Adsk.CreateTcFileEcoLink ([string]$FileFullVaultPath )
{
	$file = $vault.DocumentService.FindLatestFilesByPaths(@($FileFullVaultPath))[0]
	#get change order
	$changeOrder = $vault.ChangeOrderService.GetChangeOrderFilesByFileMasterId($file.MasterId)[0] 
	#create TC link of CO
	$serverUri = [System.Uri]$Vault.InformationService.Url
	$TcChangeOrderLink = "$($serverUri.Scheme)://$($VaultConnection.Server)/AutodeskTC/$($VaultConnection.Vault)/changeorders/changeorder/$($changeOrder.ChangeOrder.Id)"
	return $TcChangeOrderLink
}

#function to check that the current user is member of a named group; returns true or false
function Adsk.GroupMemberOf([STRING]$mGroupName)
{
	$mGroupInfo = New-Object Autodesk.Connectivity.WebServices.GroupInfo
	$mGroup = $vault.AdminService.GetGroupByName($mGroupName)
	$mGroupInfo = $vault.AdminService.GetGroupInfoByGroupId($mGroup.Id)
	foreach ($user in $mGroupInfo.Users)
	{
		if($vault.AdminService.Session.User.Id -eq $user.Id)
		{				
			return $true
		}
	}
	return $false
}

#function to check that the current user has a Vault behavior config permissions
function Adsk.CheckCfgAdminPermission()
{
	$mAllPermissions = $vault.AdminService.GetPermissionsByUserId($vault.AdminService.Session.User.Id)
	$mAllPermIds = @()
	foreach ($item in $mAllPermissions)
	{
		$mAllPermIds += $item.Id
	}
	if ($mAllPermIds -contains 77 -and $mAllPermIds -contains 76) #76 = Vault Set Options; 77 = Vault Get Options
	{
		return $true
	}
	return $false
}

function mSearchCustentOfCat([String]$mCatDispName)
{
	$mSearchString = $mCatDispName
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propDef = $propDefs | Where-Object { $_.SysName -eq "CategoryName" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3 
	$srchCond.SrchTxt = $mSearchString
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""     
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'
	
	while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
	{
		$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions(@($srchCond),@($srchSort),[ref]$bookmark,[ref]$searchStatus)			
		If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
		{
			#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
		}
		if($mResultPage.Count -ne 0)
		{
			$mResultAll.AddRange($mResultPage)
		}
		else { break;}

		return $mResultAll				
		break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
	}
}

# read a parent folder's (Id) properties and copy values to the current file's properties listed in the mapping table
function mInheritProperties ($Id, $MappingTable) {
	#read the source entity's properties
	$mFldProps = @{}
	$mFldProps += mGetAllFolderProperties($Id)
	
	#iterate the target properties and retrieve the value of the mapped source 
	$MappingTable.GetEnumerator() | ForEach-Object {
		$Prop[$_.Name].Value = $mFldProps[$_.Value]
	}	
}

# read all properties for a single folder
# returns a name/value map (dictionary) using the UDP's displayname as the key
function mGetAllFolderProperties ([long] $FolderId)
{
	$mResult = @{}
	if (!$global:mFldrPropDefs) {
		$global:mFldrPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
	}
	$propDefIds = @()
	$mFldrPropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}	
	$mEntIDs = @()
	$mEntIDs += $FolderId
	$mPropertyInstances = $vault.PropertyService.GetProperties("FLDR", $mEntIDs, $propDefIds)	
	Foreach($mPropInst in $mPropertyInstances){		
		$Name = ($mFldrPropDefs | Where-Object {$_.Id -eq $mPropInst.PropDefId}).DispName
		$mResult.Add($Name, $mPropInst.Val)
	}	
	Return $mResult
}

# read all properties for a single file (iteration)
# returns a name/value map (dictionary) using the UDP's displayname as the key
function mGetAllFileProperties ([long] $FileId)
{
	$mResult = @{}
	if (!$global:mFilePropDefs) {
		$global:mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	}
	$propDefIds = @()
	$mFilePropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}	
	$mEntIDs = @()
	$mEntIDs += $FileId
	$mPropertyInstances = $vault.PropertyService.GetProperties("FILE", $mEntIDs, $propDefIds)	
	Foreach($mPropInst in $mPropertyInstances){		
		$Name = ($mFilePropDefs | Where-Object {$_.Id -eq $mPropInst.PropDefId}).DispName
		$mResult.Add($Name, $mPropInst.Val)
	}	
	Return $mResult
}

# read all properties for a single item (iteration)
# returns a name/value map (dictionary) using the UDP's displayname as the key
function mGetAllItemProperties ([long] $ItemId)
{
	$mResult = @{}
	if (!$global:mItemPropDefs) {
		$global:mItemPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	}
	$propDefIds = @()
	$mItemPropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}	
	$mEntIDs = @()
	$mEntIDs += $ItemId
	$mPropertyInstances = $vault.PropertyService.GetProperties("ITEM", $mEntIDs, $propDefIds)	
	Foreach($mPropInst in $mPropertyInstances){		
		$Name = ($mItemPropDefs | Where-Object {$_.Id -eq $mPropInst.PropDefId}).DispName
		$mResult.Add($Name, $mPropInst.Val)
	}	
	Return $mResult
}

# read all properties for a single change order
# returns a name/value map (dictionary) using the UDP's displayname as the key
function mGetAllChangeOrderProperties ([long] $mChangeOrderId)
{
	$mResult = @{}
	if (!$global:mCoPropDefs) {
		$global:mCoPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CO")
	}
	$propDefIds = @()
	$mCoPropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}	
	$mEntIDs = @()
	$mEntIDs += $mChangeOrderId
	$mPropertyInstances = $vault.PropertyService.GetProperties("CO", $mEntIDs, $propDefIds)	
	Foreach($mPropInst in $mPropertyInstances){		
		$Name = ($mCoPropDefs | Where-Object {$_.Id -eq $mPropInst.PropDefId}).DispName
		$mResult.Add($Name, $mPropInst.Val)
	}	
	Return $mResult
}

# read all properties for a single custom object
# returns a name/value map (dictionary) using the UDP's displayname as the key
function mGetAllCustentProperties ([long] $CustentId)
{
	$mResult = @{}
	if (!$global:mCustentPropDefs) {
		$global:mCustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	}
	$propDefIds = @()
	$mCustentPropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}	
	$mEntIDs = @()
	$mEntIDs += $CustentId
	$mPropertyInstances = $vault.PropertyService.GetProperties("CUSTENT", $mEntIDs, $propDefIds)	
	Foreach($mPropInst in $mPropertyInstances){		
		$Name = ($mCustentPropDefs | Where-Object {$_.Id -eq $mPropInst.PropDefId}).DispName
		$mResult.Add($Name, $mPropInst.Val)
	}	
	Return $mResult
}


#create folder structure based on a template;
function mRecursivelyCreateFolders($sourceFolder, $targetFolder, $inclACL)
{
	If(-not $Global:FldPropDefs){
		$Global:FldPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
		$Global:FldPropDefIds = @()
		$Global:FldPropDefs| ForEach-Object {
			If($_.IsSys -eq $false)
			{
				$Global:FldPropDefIds += $_.Id
			}
		}
	}

    $sourceSubFolders = $vault.DocumentService.GetFoldersByParentId($sourceFolder.Id,$false)
	
		$mFldIdsArray = @() #collect the level's folder(s) Id(s)
		$propInstParamArrayArray = @()

		foreach ($folder in $sourceSubFolders) {
			$mSourceFldrProps = $vault.PropertyService.GetProperties("FLDR", @($folder.id) , $Global:FldPropDefIds)
		
			$mSourceUdpInstArray = @()
			$mSourceUdpInstArray += 	$mSourceFldrProps | Where-Object { $Global:FldPropDefIds -contains $_.PropDefId}	

			$newTargetSubFolder = $vault.DocumentServiceExtensions.AddFolderWithCategory($folder.Name, $targetFolder.Id, $folder.IsLibrary, $folder.Cat.CatId)
			$mFldIdsArray  += $newTargetSubFolder.Id
			
			$propInstParamArray = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray #collect the folder's property instance arrays
		
			Foreach($Inst in $mSourceUdpInstArray)
			{
				$propInstParam = New-Object Autodesk.Connectivity.WebServices.PropInstParam
				$propInstParam.PropDefId	= $Inst.PropDefId
				$propInstParam.Val = $Inst.Val
				$propInstParamArray.Items += $propInstParam
			}
						
			$propInstParamArrayArray += $propInstParamArray

			#copy Access Control List if user's permission include ACLRead, ACLWrite
			if($inclACL -eq $true)
			{
				$mCopiedACL = mCopyEntACL -SourceEnt  $folder -TargetEnt  $newTargetSubFolder
			}
			if ($null -eq $mCopiedACL) {
				<# Action to perform if the condition is true #>
			}
			#recursively iterate
			mrecursivelyCreateFolders -targetFolder $newTargetSubFolder -sourceFolder $folder -inclACL $inclACL

		 }
		
		#returning to the initial level we can update the level folder's properties
		Try{
				$vault.DocumentServiceExtensions.UpdateFolderProperties($mFldIdsArray, $propInstParamArrayArray)
			}
			catch {}
} #end function mRecursivelyCreateFolders


function mGetCUsPermissions
{
	$mUserId = $vault.AdminService.Session.User.Id
    $mAllPermisObjects = $vault.AdminService.GetPermissionsByUserId($mUserId) #allowed for the current logged in user's id, otherwise the AdminUserRead is required
    $mAllPermissions = @()

    Foreach($item in $mAllPermisObjects)
	{
		$mAllPermissions += $item.Id
	}
	return $mAllPermissions
}

function mCopyEntACL($SourceEnt, $TargetEnt)
{
	#read the Access Control Entries (ACE) of the source
	$mFldrAcls = New-Object Autodesk.Connectivity.WebServices.EntsAndACLs
	$mFldrACEs = @(New-Object Autodesk.Connectivity.WebServices.ACE)

	$mFldrAcls = $vault.SecurityService.GetEntACLsByEntityIds(@($SourceEnt.Id));
               
    #prefer the override if exists
    if ($mFldrAcls.EntACLArray[0].SysAclBeh -eq ([Autodesk.Connectivity.Webservices.SysAclBeh]::Override))
    {
        $mAclId = $mFldrAcls.EntACLArray[0].SysACLId;
    }
    else
    {
        $mAclId = $mFldrAcls.EntACLArray[0].ACLId;
    }

    $mFldrACEs = ($mFldrAcls.ACLArray | Where-Object { $_.Id -eq $mAclId})[0].ACEArray;
   
	#write the ACE to the new folder
	[Autodesk.Connectivity.Webservices.ACL]$mNewACL = $vault.SecurityService.UpdateACL($TargetEnt.Id, $mFldrACEs, [Autodesk.Connectivity.Webservices.PrpgType]::ReplacePermissions);

	return $mNewACL
}