# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.

# PowerShell 7.2 compatible assembly loading for WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

function mInitializeClassificationTab($ParentType, $file) {
	$dsDiag.ShowLog()
	$dsDiag.Clear()

	$dsWindow.FindName("txtClassificationStatus").Visibility = "Collapsed"
	$Global:mClsTabInitialized = $false

	if ($Global:mClsTabInitialized -ne $true) {
		$dsDiag.Trace("...not intialized yet -> Initialize classification tab.")
		#variables, that we need in any case; limit number of server calls

		$Global:mAllCustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$Global:mCustentUdpDefs = $Global:mAllCustentPropDefs | Where-Object { $_.IsSys -eq $false }
		$Global:mCustentDefs = $vault.CustomEntityService.GetAllCustomEntityDefinitions()
		$Global:mClassCustentDef = $Global:mCustentDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsObject"] }
		if (-not $Global:mClassCustentDef) {
			$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_13"]
			$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
		}
		#configuration info - the custom object names used for the classification structure may vary. Align Custent names of your Vault in UIStrings ADSK.QS.ClassLevel_*
		$Global:mClsLevelNames = ($UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
			$UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
			$UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["Adsk.QS.ClsCode"], $UIString["Adsk.QS.ClsLevelCode"], 
			$UIString["Adsk.QS.Classification_00"], $UIString["Comments"], $UIString["CommentsDE"] )
		$Global:mClassLevelCustentDefIds = ($Global:mCustentDefs | Where-Object { $_.DispName -in $mClsLevelNames }).Id		
	}

	Switch ($ParentType) {
		"Dialog" {
			$dsDiag.Trace("Initialize UI Controls for Dialog starts...")

			$Global:mFile = mGetFileObject

			$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
			$dsWindow.FindName("btnSelectClass").IsEnabled = $false
			if ($Prop["_XLTN_CLSOBJECT"].Value.Length -lt 1 -and $Prop["_ReadOnly"].Value -eq $false) { 
				$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
				$dsWindow.FindName("btnSelectClass").IsEnabled = $true
			}
			if ($Prop["_XLTN_CLSOBJECT"].Value.Length -gt 0 -and $Prop["_ReadOnly"].Value -eq $false) { 	
				$dsWindow.FindName("btnRemoveClass").IsEnabled = $true
				$dsWindow.FindName("btnSelectClass").IsEnabled = $false
			}

			if ($Prop["_XLTN_CLSOBJECT"]) {
				$dsWindow.FindName("txtActiveClass").Text = $Prop["_XLTN_CLSOBJECT"].Value
			}

			$Global:mClsTabInitialized = $true
			$dsDiag.Trace("...Initialize UI Controls for Dialog finished")
		}
		default { #data sheet tab
			$dsDiag.Trace("Initialize Detail Tab Datasheet starts...")
			$Global:mFile = $file
			$Global:mClsTabInitialized = $true
			$dsDiag.Trace("...Initialize Detail Tab Datasheet finished")
		}
	}

	mGetFileClsValues

}

function mGetFileClsValues {
	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	if ($dsWindow.Name -eq "FileWindow") {
		$dsWindow.FindName("txtSegment").Visibility = "Collapsed"
		$dsWindow.FindName("txtMainGroup").Visibility = "Collapsed"
		$dsWindow.FindName("txtGroup").Visibility = "Collapsed"
		$dsWindow.FindName("txtSubGroup").Visibility = "Collapsed"
	}

	$mActiveClass = @()
	if ($AssignClsWindow) {
		$mActiveClass += mGetCustentiesByName($AssignClsWindow.FindName("cmbCls1").SelectedValue) #-Name $AssignClsWindow.FindName("cmbAvailableClasses").SelectedValue
	}
	else {
		$mActiveClass += mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value) #-Name $Prop["_XLTN_CLSOBJECT"].Value #Note - custom object names are not unique, only its Number, and we need to handle returning more than one.
	}

	if ($mActiveClass.Count -eq 1) {
		#region get Property Ids and Displaynames for this class
		$dsDiag.Trace("	...class object for file class property value found.")
		$mClsPropNames = mGetClsPrpNames($mActiveClass[0].Id) #-ClassId $mActiveClass[0].Id
		$mClsPropTable = @{}
		
		#get the file's class property values
		$mFileClassProps = $vault.PropertyService.GetProperties("FILE", @($mFile.Id), $mClsPropNames.Keys)
		$mClassProps = $vault.PropertyService.GetProperties("CUSTENT", @($mActiveClass[0].Id), $mClsPropNames.Keys)
		Foreach ($mClsProp in $mClsPropNames.GetEnumerator()) {
			#filter the classification property, add all others
			if ($mClsProp.Value -notin $mClsLevelNames) {
				$mClsPropTable.Add($mClsPropNames[$mClsProp.Key], (($mFileClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val))
			}
			if ($dsWindow.Name -eq "FileWindow") {
				if ($mClsPropNames[$mClsProp.Key] -eq $UIString["Adsk.QS.ClsLevel_01"]) { 
					$dsWindow.FindName("txtSegment").Text = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					if ($dsWindow.FindName("txtSegment").Text -ne "") { $dsWindow.FindName("txtSegment").Visibility = "Visible" }
				}
				
				if ($mClsPropNames[$mClsProp.Key] -eq $UIString["Adsk.QS.ClsLevel_02"]) { 
					$dsWindow.FindName("txtMainGroup").Text = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					if ($dsWindow.FindName("txtMainGroup").Text -ne "") { $dsWindow.FindName("txtMainGroup").Visibility = "Visible" }
				}
				
				if ($mClsPropNames[$mClsProp.Key] -eq $UIString["Adsk.QS.ClsLevel_03"]) { 
					$dsWindow.FindName("txtGroup").Text = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					if ($dsWindow.FindName("txtGroup").Text -ne "") { $dsWindow.FindName("txtGroup").Visibility = "Visible" }
				}
				if ($mClsPropNames[$mClsProp.Key] -eq $UIString["Adsk.QS.ClsLevel_04"]) { 
					$dsWindow.FindName("txtSubGroup").Text = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					if ($dsWindow.FindName("txtSubGroup").Text -ne "") { $dsWindow.FindName("txtSubGroup").Visibility = "Visible" }
				}				
				if ($mClsPropNames[$mClsProp.Key] -eq $UIString["Adsk.QS.ClsStandard"]) { 
					$global:mActiveStandard = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					$dsWindow.FindName("txtClsStandard").Text = ($mClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
					if ($dsWindow.FindName("txtClsStandard").Text -ne "") { $dsWindow.FindName("txtClsStandard").Visibility = "Visible" }
				}
			}

		}
		#fill the grid either for edits or as preview before the class assignment
		if ($AssignClsWindow) {
			$AssignClsWindow.FindName("dtgrdClsObjProps").ItemsSource = $mClsPropTable
			$AssignClsWindow.FindName("dtgrdClsObjProps").IsEnabled = $false
		}
		else {
			$dsWindow.FindName("dtgrdClsObjProps").ItemsSource = $mClsPropTable		
		}
	}
	if ($mActiveClass.Count -gt 1) {
		$dsDiag.Trace("	...multiple class objects for given name found.")
	}
}

function mGetClsDfltValues {
	#$dsDiag.Trace(">>Function mGetClsDfltValues starts...")
	$mActiveClass = @()
	$mActiveClass += mGetCustentiesByName($AssignClsWindow.FindName("cmbCls1").SelectedValue) #-Name $AssignClsWindow.FindName("cmbAvailableClasses").SelectedValue
	$mClsPropNames = mGetClsPrpNames($mActiveClass[0].Id) #-ClassId $mActiveClass[0].Id
	$mClsPrpValues = mGetClsPrpValues($mActiveClass[0].Id) #-ClassId $mActiveClass[0].Id
	$mClsPropTable = @{}
	
	if ($mActiveClass.Count -eq 1) {
		Foreach ($mClsProp in $mClsPropNames.GetEnumerator()) {
			#filter the all classification level properties but add all class' properties
			if ($mClsPropNames[$mClsProp.Key] -notin $mClsLevelNames) { $mClsPropTable.Add($mClsPropNames[$mClsProp.Key], $mClsPrpValues[$mClsProp.Key]) }
		}
	}

	$AssignClsWindow.FindName("dtgrdClsObjProps").ItemsSource = $mClsPropTable

	#$dsDiag.Trace("...Function mGetClsDfltValues finsihed.<<")
}

function mGetClsPrpNames($ClassId) { #get Properties added to this class
	$global:mClsPropInsts = @()
	$global:mClsPropInsts += $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))
	$mClsPropNames = @{}
	ForEach ($mPropInst in $mClsPropInsts) {
		#add UDPs of the Custom Object $UIString["Adsk.QS.ClsObject"] only
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mDispName = ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }).DispName
			$mClsPropNames.Add($mPropInst.PropDefId, $mDispName)
		}
	}
	return $mClsPropNames
}

function mGetClsPrpValues($ClassId) { #get Properties added to this class
	$mClsPropValues = @{}
	ForEach ($mPropInst in $global:mClsPropInsts) {
		#add UDPs of the Custom Object $UIString["Adsk.QS.ClsObject"] only
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mClsPropValues.Add($mPropInst.PropDefId, $mPropInst.Val)
		}
	}
	return $mClsPropValues
}

function mGetCustentiesByName([String]$Name) {
	$srchConds = New-Object Autodesk.Connectivity.WebServices.SrchCond[] 2 #we search for name and standard
	
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDef = $Global:mAllCustentPropDefs | Where-Object { $_.SysName -eq "Name" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3 #Is exactly (or equals)
	$srchCond.SrchTxt = $Name
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchConds[0] = $srchCond
	
	$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
	$srchCond2.PropDefId = ($Global:mAllCustentPropDefs | Where-Object { $_.DispName -eq $Prop["_XLTN_CLSSTANDARD"].Name }).Id
	$srchCond2.SrchOper = 3 #Is exactly (or equals)
	if (-not $global:mActiveStandard) {
		$srchCond2.SrchTxt = "*"
	}
	else {
		$srchCond2.SrchTxt = $global:mActiveStandard		
	}
	$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchConds[1] = $srchCond2

	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

	while (($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits)) {
		try {
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds, @($srchSort), [ref]$bookmark, [ref]$searchStatus)
		}
		catch {
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Unhandled Exception in function mGetCustentiesByName", "VDS Sample -- Classification")
		}
		If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent") {
			#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
			$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_12"]
			$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
		}
		if ($mResultPage.Count -ne 0) {
			$mResultAll.AddRange($mResultPage)
		}
		else { break; }
		$dsWindow.FindName("txtClassificationStatus").Visibility = "Collapsed"
		
		#break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
	}
	return $mResultAll
}

function mGetFileObject() {
	$result = FindFile -fileName ($Prop["_FileName"].Value + $Prop["_FileExt"].Value)
	foreach ($fileresult in $result) {
		if ($Prop["_FilePath"].Value -eq ($vault.DocumentService.GetFolderById($fileresult.FolderId)).FullName) {
			$file = $fileresult
			return $file
		}
	}
	return $null
}

function mSelectClassification() {
	$dsWindow.FindName("txtActiveClass").Text = $AssignClsWindow.FindName("cmbCls1").SelectedValue
	$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
	$dsWindow.FindName("btnSelectClass").IsEnabled = $true

	$value = $AssignClsWindow.FindName("cmbCls1").SelectedItem.Id
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mFileClassId.txt"

	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $AssignClsWindow.FindName("dtgrdClsObjProps").ItemsSource
	
	$AssignClsWindow.DialogResult = $true #"OK"
	$AssignClsWindow.Close()
}

function mApplyClassification() {
	if ($Global:mFile) {
		#the function mFindCustent returns a generic list object
		$Prop["_XLTN_CLSOBJECT"].Value = $dsWindow.FindName("txtActiveClass").Text
		$mActiveClass = @()
		$mActiveClass += mFindCustent -CustentName $dsWindow.FindName("txtActiveClass").Text -Category $UIString["Adsk.QS.ClsObject"] #custom object names should be unique per category
		If ($mActiveClass.Count -eq 1) {
			#$mClsLevelNames = ($Prop["_XLTN_CLSLEVEL1"].Name, $Prop["_XLTN_CLSLEVEL2"].Name, $Prop["_XLTN_CLSLEVEL3"].Name, $Prop["_XLTN_CLSLEVEL4"].Name, $Prop["_XLTN_CLSOBJECT"].Name, $Prop["_XLTN_CLSSTANDARD"].Name, $Prop["_XLTN_TERM-DE"].Name, $Prop["_XLTN_TERM-EN"].Name, $Prop["_XLTN_TERM-FR"].Name, $Prop["_XLTN_TERM-IT"].Name, $Prop["_XLTN_CLSCODE"].Name, $Prop["_XLTN_COMMENTS"].Name, $Prop["_XLTN_COMMENTS-DE"].Name)
			$mClsPropNames = mGetClsPrpNames -ClassId $mActiveClass.Id
			$mPropsAdd = @()
			Foreach ($mClsProp in $mClsPropNames.GetEnumerator()) {
				#filter the all classification level properties but add all class' properties
				if ($mClsProp.Value -notin $mClsLevelNames) { $mPropsAdd += $mClsProp.Key }
			}
		}
		else {
			return
		}
		If ($mActiveClass.Count -gt 1) {
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($UIString["Adsk.QS.Classification_10"], "VDS Sample Configuration")
			return
		}
		$mPropsRemove = @()
		$mAddRemoveComment = "Added classification"
		try {
			$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
			mUpdateClsPropValues
		}
		catch {
			$dsDiag.Trace("AddClassification Error on UpdateFilePropertyDefinitions")
		}
	}
}

function mRemoveClassification() { #applies to $dsWindow
	#$dsDiag.Trace("Remove Class starts...")
	if ($Prop["_EditMode"]) {
		if ($Global:mFile) {
			$dsDiag.Trace("...remove class - file found")
			$mActiveClass = @()
			$mActiveClass += mFindCustent -CustentName $Prop["_XLTN_CLSOBJECT"].Value -Category $UIString["Adsk.QS.ClsObject"] #custom object names should be unique within a category, only its Number
			If ($mActiveClass.Count -eq 1) {
				$mClsPropNames = mGetClsPrpNames($mActiveClass.Id) #-ClassId $mActiveClass.Id
				$mPropsRemove = @()
				$mPropsRemove += $mClsPropNames.Keys
			}
			Else {
				[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($UIString["Adsk.QS.Classification_10"], "VDS Sample Configuration")
				return
			}
			$mMsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning(($UIString["Adsk.QS.Classification_11"] -f "`n"), "VDS Sample Configuration", "YesNo")
			if ($mMsgResult -eq "No") { return }

			$mAddRemoveComment = "removed classification"
			try {
				$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
			}
			catch {
				[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Error removing or updating classification", "VDS Sample Configuration")
			}
		}
	}

	
	#write the highest level Custent Id to a text file for post-close event
	$value = -1
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mFileClassId.txt"

	$dsWindow.CloseWindowCommand.Execute($this)
	#$dsDiag.Trace("...remove classification finished.")
}


#region classification breadcrumb
function mAddClsLevelCombo ([String] $ClassLevelName, $ClsLvls) {
	$children = mGetCustentClsLevelList($ClassLevelName) # -ClassLevelName $ClassLevelName
	if ($null -eq $children) { return }
	# sort the children by Name, case sensitiv
	$children = $children | Sort-Object -Property Name -CaseSensitive #-Descending -Unique -Stable
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString()
	$cmb.DisplayMemberPath = "Name"
	$cmb.MinWidth = 140
	$cmb.Height = 26
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "0,0,1,0"

	# Add the ComboBox to the visual tree first
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) # Register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb)

	# Set the ItemsSource after adding to the visual tree
	$cmb.ItemsSource = $children

	<# if ($AssignClsWindow.FindName("cmbCls1").Items.Count -gt 1) {
        $AssignClsWindow.FindName("cmbCls1").IsDropDownOpen = $true
    }
    if ($AssignClsWindow.FindName("cmbCls1").Items.Count -eq 0 -and $Prop["_XLTN_CLSOBJECT"].Value -eq "") {
        $cmb.IsDropDownOpen = $true
    } #>

	$cmb.add_SelectionChanged({
			param($mSender, $e)
			mClsLevelCmbSelectionChanged($mSender) # -mSender $mSender
		})
}

function mAddClsLevelCmbChild ($data) {
	$children = mGetCustentClsLevelUsesList($data) #-mSender $data
	if ($null -eq $children) { return }
	# sort the children by Name, case sensitive
	$children = $children | Sort-Object -Property Name -CaseSensitive #-Descending -Unique -Stable
	#Filter classification levels and classes
	#mAvlblClsReset
	$mClassLevelObjects = @() #filtered list for the 4 levels
	$mClassLevelObjects += $children | Where-Object { $_.CustEntDefId -in $Global:mClassLevelCustentDefIds }
	$mClassObjects = @() #filtered list for the class object only
	$mClassObjects += $children | Where-Object { $_.CustEntDefId -eq $Global:mClassCustentDef.Id }

	if ($mClassObjects.Count -gt 0) {
		$AssignClsWindow.FindName("cmbCls1").ItemsSource = $mClassObjects
		$AssignClsWindow.FindName("cmbCls1").SelectedIndex = 0
		$AssignClsWindow.FindName("cmbCls1").IsEnabled = $true
	}
	if ($mClassObjects.Count -eq 0) {
		mAvlblClsReset
	}
	$children = $mClassLevelObjects
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";

	$cmb.BorderThickness = "0,0,1,0"
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.MinWidth = 140
	$cmb.Height = 26

	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb)
	$cmb.ItemsSource = @($children)

	if ($AssignClsWindow.FindName("cmbCls1").Items.Count -gt 1) {
		$AssignClsWindow.FindName("cmbCls1").IsDropDownOpen = $true
	}
	if ($AssignClsWindow.FindName("cmbCls1").Items.Count -eq 0) { $cmb.IsDropDownOpen = $true }

	$cmb.add_SelectionChanged({
			param($mSender, $e)
			$dsDiag.Trace("next. SelectionChanged, mSender = $mSender")
			mClsLevelCmbSelectionChanged($mSender)# -mSender $mSender
		});

	$AssignClsWindow.FindName("btnResetClsLevels").IsEnabled = $true
} #addCoComboChild

function mGetCustentClsLevelList ([String] $ClassLevelName) {
	try {
		#$dsDiag.Trace(">> mGetCustentClsLevelList started")
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 2
		
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		$srchCond.PropDefId = ($Global:mAllCustentPropDefs | Where-Object { $_.SysName -eq "CustomEntityName" }).Id
		$srchCond.SrchOper = 3 #equals
		$srchCond.SrchTxt = $ClassLevelName
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond

		$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
		$srchCond2.PropDefId = ($Global:mAllCustentPropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsStandard"] }).Id
		$srchCond2.SrchOper = 3 #equals
		$srchCond2.SrchTxt = $global:mActiveStandard
		$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[1] = $srchCond2

		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

		while (($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits)) {
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds, @($srchSort), [ref]$bookmark, [ref]$searchStatus)
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent") {
				#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
				<# $dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_12"]
				$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible" #>
			}
			If ($mResultPage.Count -ne 0) {
				$mResultAll.AddRange($mResultPage)
			}
			else { 
				#$MsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("Could not find any " + $ClassLevelName, "VDS Sample -- Classification", "OK")
				break;
			}
		}
		return $mResultAll
	}
	catch {
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Unhandled Exception in function mGetCustentClsLevelList", "VDS Sample -- Classification")
	}
}

function mGetCustentClsLevelUsesList ($mSender) {
	try {
		#$dsDiag.Trace(">> mGetCustentClsLevelUsesList started")
		$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
		$_i = $mBreadCrumb.Children.Count - 1
		$_CurrentCmbName = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClass = $mBreadCrumb.Children[$_i].SelectedValue.Name
		#[System.Windows.MessageBox]::Show("Currentclass: $_CurrentClass and Level# is $_i")
		switch ($_i) {
			0 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_01"] }
			1 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_02"] }
			2 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_03"] }
			3 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_04"] }
			default { $mSearchFilter = "*" }
		}
		$_customObjects = mGetCustentClsLevelList -ClassLevelName $mSearchFilter
		$_Parent = $_customObjects | Where-Object { $_.Name -eq $_CurrentClass }

		try {
			$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id), @("CUSTENT"))
			$linkIds = @()
			$links | ForEach-Object { $linkIds += $_.ToEntId }
			$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds)
			#$dsDiag.Trace(".. mGetCustentClsLevelUsesList finished - returns $mLinkedCustObjects <<")
			return $mLinkedCustObjects #$global:_Groups
		}
		catch {
			$dsDiag.Trace("!! no links of Parent Co !!")
			return $null
		}
	}
	catch { $dsDiag.Trace("!! Error in mAddCoComboChild !!") }
}

function mClsLevelCmbSelectionChanged($mSender) {
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")	
	[int]$position = $mSender.Name.Split('_')[1]
	$children = $mBreadCrumb.Children.Count - 1
	while ($children -gt $position ) {
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children]);
		$children--;
	}
	Try {
		# $Prop["_XLTN_CLSLEVEL1"].Value = $mBreadCrumb.Children[1].SelectedItem.Name
		# $Prop["_XLTN_CLSLEVEL2"].Value = $mBreadCrumb.Children[2].SelectedItem.Name
		# $Prop["_XLTN_CLSLEVEL3"].Value = $mBreadCrumb.Children[3].SelectedItem.Name
		# $Prop["_XLTN_CLSLEVEL4"].Value = $mBreadCrumb.Children[4].SelectedItem.Name
	}
	catch {}

	mAvlblClsReset

	mAddClsLevelCmbChild($mSender.SelectedItem) #-mSender $mSender.SelectedItem
}

function mResetClassSelection {
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	$children = @()
	$children += mGetCustentClsLevelList($UIString["Adsk.QS.ClsLevel_01"]) #-ClassLevelName $UIString["Adsk.QS.ClsLevel_01"]
	if ($children.Count -eq 0) {
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Could not initialize the classification root - probably your base classes do not match the selected Standard", "VDS Sample -- Classification")
		return
	}
	$mBreadCrumb.Children[0].ItemsSource = $children 
	$mBreadCrumb.Children[0].SelectedIndex = -1
	$AssignClsWindow.FindName("btnResetClsLevels").IsEnabled = $false
	$AssignClsWindow.FindName("dtgrdClsObjProps").ItemsSource = $null
}

function mAvlblClsReset {
	if ($null -ne $AssignClsWindow.FindName("cmbCls1")) {
		$dsWindow.FindName("txtActiveClass").Text = ""
		$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
		$AssignClsWindow.FindName("cmbCls1").ItemsSource = $null
		$AssignClsWindow.FindName("cmbCls1").SelectedIndex = -1
		$AssignClsWindow.FindName("cmbCls1").IsEnabled = $false
	}
	$AssignClsWindow.FindName("btnSelectClass").IsEnabled = $false
}
#endregion classification breadcrumb

function mInitializeAssignClsDlg {
	# PowerShell 7.2 compatible XAML loading with proper namespace resolution
	try {
		$AssignClsXamlContent = Get-Content("C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.TS.SelectClassification.xaml") -Raw
        
		# Create ParserContext for proper XAML namespace resolution
		$xamlReader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($AssignClsXamlContent))
		$Global:AssignClsWindow = [Windows.Markup.XamlReader]::Load($xamlReader)
		$xamlReader.Close()
		# share the parent default VDS's window data context for property bindings and other shared resources
		$AssignClsWindow.DataContext = $dsWindow.DataContext
	}
	catch {        
		$dsDiag.Trace("Inner Exception: $($_.Exception.InnerException)")
		throw "Failed to load classification dialog: $($_.Exception.Message)"
	}

	# Activate the UI tab according to the classification standard
	#mAssignClsGrdReset($AssignClsWindow.FindName("cmb_ClsStd")) #-ComboBox $AssignClsWindow.FindName("cmb_ClsStd")

	if (-not $global:mActiveStandard) {
		$global:mActiveStandard = $AssignClsWindow.FindName("cmb_ClsStd").SelectedItem.Content
	}

	mInitializeCompClassification

	$AssignClsWindow.FindName("cmb_ClsStd").add_SelectionChanged({
			param ($mSender, $e)
			# Update environment according to the classification standard
			mAssignClsGrdReset -ComboBox $AssignClsWindow.FindName("cmb_ClsStd")
			$global:mActiveStandard = $AssignClsWindow.FindName("cmb_ClsStd").SelectedItem.Content
			mInitializeCompClassification
		})

	# Show the dialog and handle the result
	try {
		$AssignClsWindow.Owner = $dsWindow
		$result = $AssignClsWindow.ShowDialog()
		if ($result -eq $true) {
			# Grab all the values to return
			$global:AssignClsWindow = $null
			return
		}
		else {
			return $null
		}
	}
	catch {
		$dsDiag.Trace("Inner Exception: $($_.Exception.InnerException)")
		throw "Failed to load classification dialog: $($_.Exception.Message)"
	}

}

function mInitializeCompClassification {

	if ($global:mCompClsInitialized -ne $true) {
		# Verify AssignClsWindow is properly initialized
		if ($null -eq $AssignClsWindow) {
			$dsDiag.Trace("ERROR: AssignClsWindow is null")
			return
		}
		
		$cmbCls1 = $AssignClsWindow.FindName("cmbCls1") # Try to find the ComboBox control for classification levels
		$cmbCls1.add_SelectionChanged({
				If ($Prop["_ReadOnly"].Value -eq $false -and $cmbCls1.SelectedIndex -gt -1) {
					$AssignClsWindow.FindName("btnSelectClass").IsEnabled = $true
					#preview the properties of the class
					mGetFileClsValues
					mGetClsDfltValues
				}
				Else { $AssignClsWindow.FindName("btnSelectClass").IsEnabled = $false }
			})
		
		mAvlblClsReset #reset cmbAvailableClasses

		if ($AssignClsWindow.FindName("wrpClassification2")) {
			
			if ($AssignClsWindow.FindName("wrpClassification2").Children.Count -lt 1) {
				#activate command should not add another combo row, if already classe(s) are selected
				mAddClsLevelCombo($UIString["Adsk.QS.ClsLevel_01"])
			}
		}
	}
	
	mResetClassSelection #reset wrap panel
	$global:mCompClsInitialized = $true
}

function mAssignClsGrdReset ($ComboBox) {
	# if ($ComboBox.SelectedIndex -eq "0"){
	# 		$AssignClsWindow.FindName("grdIEC61355").Visibility = "Visible"
	# 		$AssignClsWindow.FindName("grdClassification").Visibility = "Collapsed"
	# 	}
	# 	Else{
	#$AssignClsWindow.FindName("grdIEC61355").Visibility = "Collapsed"
	#$AssignClsWindow.FindName("grdClassification").Visibility = "Visible"
	#reset the combobox wrap panel
			
	# 	}
}

function mUpdateClsPropValues() {
	try {
		Foreach ($row in $dsWindow.FindName("dtgrdClassProps").Items) {
			$Prop[$row.Key].Value = $row.Value
		}
	}	
	catch {
		$dsDiag.Trace("Error writing class properties to file properties")
	}
}

function mApplyClsAndCloseFileWindow() {
	if ($dsWindow.FindName("txtActiveClass").Text -ne "") {
		mApplyClassification
	}
	$dsWindow.CloseWindowCommand.Execute($this)
}