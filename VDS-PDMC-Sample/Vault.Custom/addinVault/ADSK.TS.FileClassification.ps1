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

# Helper function to sort property table alphabetically by property name (Key)
function mSortPropertyTable($propTable) {
	if ($null -eq $propTable -or $propTable.Count -eq 0) {
		return $propTable
	}
	
	# Convert hashtable to sorted array of custom objects for DataGrid binding
	# Sort alphabetically by Key (property name)
	$sortedArray = @($propTable.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
			[PSCustomObject]@{
				Key   = $_.Key
				Value = $_.Value
			}
		})
	
	# Force array return to prevent unwrapping single items (which crashes WPF DataGrid)
	return , $sortedArray
}

function mInitializeClassificationTab($ParentType, $file) {
	#$dsDiag.ShowLog()
	#$dsDiag.Clear()

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
			$UIString["Adsk.QS.ClsLevel_04"])
		$Global:mClassLevelCustentDefIds = ($Global:mCustentDefs | Where-Object { $_.DispName -in $mClsLevelNames }).Id

		$Global:mClsObjectNames = ($UIString["Adsk.QS.ClsObject"], $UIString["ClassTerms_00"])
		$Global:mClsObjectCustentDefIds = ($Global:mCustentDefs | Where-Object { $_.DispName -in $Global:mClsObjectNames }).Id

		$Global:mClsPropNames = (
			$UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
			$UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
			$UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["ClassTerms_12b"], $UIString["Adsk.QS.ClsLevelCode"], 
			$UIString["Comments"], $UIString["CommentsDE"] )
		$Global:mClsPropDefIds = ($Global:mAllCustentPropDefs | Where-Object { $_.DispName -in $Global:mClsPropNames }).Id	
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
			if ($Prop["_XLTN_CLSSTANDARD"].Value.Length -gt 0) {
				$dsWindow.FindName("txtClsStandard").Text = $Prop["_XLTN_CLSSTANDARD"].Value
			}

			$Global:mClsTabInitialized = $true
			$dsDiag.Trace("...Initialize UI Controls for Dialog finished")
		}
		default {
			#data sheet tab
			$dsDiag.Trace("Initialize Detail Tab Datasheet starts...")
			$Global:mFile = $file
			$Global:mClsTabInitialized = $true
			$dsDiag.Trace("...Initialize Detail Tab Datasheet finished")
		}
	}

	mGetFileClsValues -sendingCmb $null

}

function mGetFileClsValues($sendingCmb) {
	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	if ($dsWindow.Name -eq "FileWindow") {
		$dsWindow.FindName("txtLevel1").Visibility = "Collapsed"
		$dsWindow.FindName("txtLevel2").Visibility = "Collapsed"
		$dsWindow.FindName("txtLevel3").Visibility = "Collapsed"
		$dsWindow.FindName("txtLevel4").Visibility = "Collapsed"
	}

	#$mActiveClass = @()
	if ($AssignClsWindow) {
		$mActiveClass = mGetCustentiesByName($sendingCmb.SelectedValue.Name)
	}
	else {
		# Edit mode - check if file has a classification assigned
		if ([string]::IsNullOrEmpty($Prop["_XLTN_CLSOBJECT"].Value)) {
			return
		}
		
		# Read the standard from file properties and store it globally; the direct usage of _XLTN_CLSSTANDARD might not work, as this property adds only if a standard is assigned to the file
		$standardPropName = "_XLTN_" + $UIString["Adsk.QS.ClsStandard"].ToUpper()
		if (-not [string]::IsNullOrEmpty($Prop[$standardPropName].Value)) {
			$global:mActiveStandard = $Prop[$standardPropName].Value
			
			# Populate txtClsStandard if it exists
			$txtStandard = $dsWindow.FindName("txtClsStandard")
			if ($txtStandard) {
				$txtStandard.Text = $global:mActiveStandard
			}
		}
		
		$mActiveClass = mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value)
	}

	# Check if we found a valid class object
	if (-not $mActiveClass -or $mActiveClass.Count -eq 0) {
		return
	}

	#region get Property Ids and Displaynames for this class
	$Global:mActvClsPrpNames = mGetClsPrpNames($mActiveClass[0].Id)
	$mClsPropTable = @{}
		
	#get the file's class property values
	$mFileClassProps = $vault.PropertyService.GetProperties("FILE", @($mFile.Id), $Global:mActvClsPrpNames.Keys)
		
	# Get ALL properties from class entity (including Level 1-4 for display in txtLevel textboxes)
	# We need to retrieve more than just mActvClsPrpNames because those are filtered
	$allClassEntityProps = $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($mActiveClass[0].Id))
	$dsDiag.Trace("   Retrieved $($allClassEntityProps.Count) total properties from class entity")
		
	# Create a lookup dictionary for all class entity properties by PropDefId
	$mClassPropsLookup = @{}
	foreach ($prop in $allClassEntityProps) {
		$mClassPropsLookup[$prop.PropDefId] = $prop
	}
		
	$mClassProps = $vault.PropertyService.GetProperties("CUSTENT", @($mActiveClass[0].Id), $Global:mActvClsPrpNames.Keys)
		
	$dsDiag.Trace(">> mGetFileClsValues: Retrieved $($mFileClassProps.Count) file properties and $($mClassProps.Count) class entity properties")
	$dsDiag.Trace("   Window name: $($dsWindow.Name)")
	$dsDiag.Trace("   Class object Id: $($mActiveClass[0].Id), Name: $($mActiveClass[0].Name)")
		
	# Debug: List all classification level names we're looking for
	$dsDiag.Trace("   Classification level names to match:")
	$dsDiag.Trace("     Level 1: '$($UIString["Adsk.QS.ClsLevel_01"])'")
	$dsDiag.Trace("     Level 2: '$($UIString["Adsk.QS.ClsLevel_02"])'")
	$dsDiag.Trace("     Level 3: '$($UIString["Adsk.QS.ClsLevel_03"])'")
	$dsDiag.Trace("     Level 4: '$($UIString["Adsk.QS.ClsLevel_04"])'")
	$dsDiag.Trace("     Standard: '$($UIString["Adsk.QS.ClsStandard"])'")
		
	# First, handle Level 1-4 and Standard properties from the complete property set
	if ($dsWindow.Name -eq "FileWindow") {
		# Find Level 1 property
		$level1PropDef = $Global:mCustentUdpDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsLevel_01"] }
		if ($level1PropDef -and $mClassPropsLookup.ContainsKey($level1PropDef.Id)) {
			$level1Value = $mClassPropsLookup[$level1PropDef.Id].Val
			$dsWindow.FindName("txtLevel1").Text = $level1Value
			$dsDiag.Trace("   SET txtLevel1 = '$level1Value' (from complete property set)")
			if ($level1Value -ne "") { 
				$dsWindow.FindName("txtLevel1").Visibility = "Visible"
			}
		}
			
		# Find Level 2 property
		$level2PropDef = $Global:mCustentUdpDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsLevel_02"] }
		if ($level2PropDef -and $mClassPropsLookup.ContainsKey($level2PropDef.Id)) {
			$level2Value = $mClassPropsLookup[$level2PropDef.Id].Val
			$dsWindow.FindName("txtLevel2").Text = $level2Value
			$dsDiag.Trace("   SET txtLevel2 = '$level2Value' (from complete property set)")
			if ($level2Value -ne "") { 
				$dsWindow.FindName("txtLevel2").Visibility = "Visible"
			}
		}
			
		# Find Level 3 property
		$level3PropDef = $Global:mCustentUdpDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsLevel_03"] }
		if ($level3PropDef -and $mClassPropsLookup.ContainsKey($level3PropDef.Id)) {
			$level3Value = $mClassPropsLookup[$level3PropDef.Id].Val
			$dsWindow.FindName("txtLevel3").Text = $level3Value
			$dsDiag.Trace("   SET txtLevel3 = '$level3Value' (from complete property set)")
			if ($level3Value -ne "") { 
				$dsWindow.FindName("txtLevel3").Visibility = "Visible"
			}
		}
			
		# Find Level 4 property
		$level4PropDef = $Global:mCustentUdpDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsLevel_04"] }
		if ($level4PropDef -and $mClassPropsLookup.ContainsKey($level4PropDef.Id)) {
			$level4Value = $mClassPropsLookup[$level4PropDef.Id].Val
			$dsWindow.FindName("txtLevel4").Text = $level4Value
			$dsDiag.Trace("   SET txtLevel4 = '$level4Value' (from complete property set)")
			if ($level4Value -ne "") { 
				$dsWindow.FindName("txtLevel4").Visibility = "Visible"
			}
		}
			
		# Find Standard property
		$standardPropDef = $Global:mCustentUdpDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsStandard"] }
		if ($standardPropDef -and $mClassPropsLookup.ContainsKey($standardPropDef.Id)) {
			$standardValue = $mClassPropsLookup[$standardPropDef.Id].Val
			$global:mActiveStandard = $standardValue
			$dsWindow.FindName("txtClsStandard").Text = $standardValue
			$dsDiag.Trace("   SET txtClsStandard = '$standardValue' (from complete property set)")
			if ($standardValue -ne "") { 
				$dsWindow.FindName("txtClsStandard").Visibility = "Visible"
			}
		}
	}
		
	# Now process the data properties for the grid
	Foreach ($mClsProp in $Global:mActvClsPrpNames.GetEnumerator()) {
		# Add property to display table (filter out only classification level names, keep all actual data properties)
		if ($mClsProp.Value -notin $Global:mClsLevelNames) {
			$filePropertyValue = ($mFileClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key) }).Val
			$mClsPropTable.Add($Global:mActvClsPrpNames[$mClsProp.Key], $filePropertyValue)
		}
	}
		
	#fill the grid either for edits or as preview before the class assignment
	if ($AssignClsWindow) {
		$AssignClsWindow.FindName("dtgrdClassProps").ItemsSource = mSortPropertyTable($mClsPropTable)
	}
	else {
		$dsWindow.FindName("dtgrdClassProps").ItemsSource = mSortPropertyTable($mClsPropTable)
	}
}

function mGetClsDfltValues($sendingCmb) {
	$dsDiag.Trace(">>Function mGetClsDfltValues starts...$($sendingCmb)")
    
	# Add defensive check
	if (-not $Global:AssignClsWindow) {
		$dsDiag.Trace("ERROR: AssignClsWindow is null in mGetClsDfltValues")
		return
	}
    
	# SelectedValue returns the Name string (not the object), so we need to search for it
	$mActiveClass = mGetCustentiesByName($sendingCmb.SelectedValue)
	if (-not $mActiveClass -or $mActiveClass.Count -eq 0) {
		$dsDiag.Trace("ERROR: No class object found with name '$($sendingCmb.SelectedValue)'")
		return
	}
    
	# Store property names and values globally for later use
	$Global:mActvClsPrpNames = mGetClsPrpNames($mActiveClass[0].Id)
	$Global:mClsPrpValues = mGetClsPrpValues($mActiveClass[0].Id)
	$mClsPropTable = @{}
    
	Foreach ($mClsProp in $Global:mActvClsPrpNames.GetEnumerator()) {
		if ($Global:mActvClsPrpNames[$mClsProp.Key] -notin $Global:mClsPropNames) {
			$mClsPropTable.Add($Global:mActvClsPrpNames[$mClsProp.Key], $Global:mClsPrpValues[$mClsProp.Key])
		}
	}

	$Global:AssignClsWindow.FindName("dtgrdClassProps").ItemsSource = mSortPropertyTable($mClsPropTable)

	# Enable btnSelectClass if either DataGrid has values
	mUpdateSelectClassButton

	$dsDiag.Trace("...Function mGetClsDfltValues finished.<<")
}

function mGetTermDfltValues($sendingCmb) {
	$dsDiag.Trace(">>Function mGetTermDfltValues starts...$($sendingCmb)")
    
	# Add defensive check
	if (-not $Global:AssignClsWindow) {
		$dsDiag.Trace("ERROR: AssignClsWindow is null in mGetTermDfltValues")
		return
	}
    
	# Check what we're getting from the ComboBox
	$dsDiag.Trace("  SelectedValue: $($sendingCmb.SelectedValue)")
	$dsDiag.Trace("  SelectedItem: $($sendingCmb.SelectedItem)")
	$dsDiag.Trace("  SelectedItem.Name: $($sendingCmb.SelectedItem.Name)")
    
	# Use SelectedItem.Name to get the actual name (SelectedValue should be Name, but let's be safe)
	$termName = if ($sendingCmb.SelectedValue) { $sendingCmb.SelectedValue } else { $sendingCmb.SelectedItem.Name }
	$dsDiag.Trace("  Searching for term: $termName")
    
	# SelectedValue returns the Name string (not the object), so we need to search for it
	$mActiveTerm = mGetCustentiesByName($termName)
	if (-not $mActiveTerm -or $mActiveTerm.Count -eq 0) {
		$dsDiag.Trace("ERROR: No term object found with name '$termName'")
		return
	}
    
	$dsDiag.Trace("  Found term object with Id: $($mActiveTerm[0].Id)")
    
	# Store property names and values globally for later use
	$Global:mActvTermPrpNames = mGetTermPrpNames($mActiveTerm[0].Id)
	$Global:mTermPrpValues = mGetTermPrpValues($mActiveTerm[0].Id)
	$mTermPropTable = @{}
    
	Foreach ($mTermProp in $Global:mActvTermPrpNames.GetEnumerator()) {
		# For Terms: only filter out the class level properties (Segment, Main Group, Group, Sub Group)
		# Keep all other properties including Class, Standard, Codes, Comments, etc.
		if ($Global:mActvTermPrpNames[$mTermProp.Key] -notin $Global:mClsLevelNames) {
			$mTermPropTable.Add($Global:mActvTermPrpNames[$mTermProp.Key], $Global:mTermPrpValues[$mTermProp.Key])
		}
	}

	$dsDiag.Trace("  Term property table has $($mTermPropTable.Count) entries")
	$Global:AssignClsWindow.FindName("dtgrdTermProps").ItemsSource = mSortPropertyTable($mTermPropTable)

	# Enable btnSelectClass if either DataGrid has values
	mUpdateSelectClassButton

	$dsDiag.Trace("...Function mGetTermDfltValues finished.<<")
}

function mUpdateSelectClassButton {
	# Helper function to enable btnSelectClass when either DataGrid has values
	if (-not $Global:AssignClsWindow) {
		return
	}
    
	$classProps = $Global:AssignClsWindow.FindName("dtgrdClassProps").ItemsSource
	$termProps = $Global:AssignClsWindow.FindName("dtgrdTermProps").ItemsSource
	$btnSelect = $Global:AssignClsWindow.FindName("btnSelectClass")
    
	if ($btnSelect) {
		$hasClassProps = $classProps -and ($classProps.Count -gt 0)
		$hasTermProps = $termProps -and ($termProps.Count -gt 0)
        
		$btnSelect.IsEnabled = $hasClassProps -or $hasTermProps
		$dsDiag.Trace("btnSelectClass enabled: $($btnSelect.IsEnabled) (ClassProps: $hasClassProps, TermProps: $hasTermProps)")
	}
}

function mGetTermPrpNames($TermId) {
 #get Properties added to this term - NO pre-filtering
	$global:mTermPropInsts = @()
	$global:mTermPropInsts += $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($TermId))
	$mActvTermPrpNames = @{}
	ForEach ($mPropInst in $mTermPropInsts) {
		#add ALL UDPs of the Term Object - don't filter out $Global:mClsPropDefIds
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mDispName = ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }).DispName
			$mActvTermPrpNames.Add($mPropInst.PropDefId, $mDispName)
		}
	}
	return $mActvTermPrpNames
}

function mGetTermPrpValues($TermId) {
 #get Property values for this term
	$mTermPropValues = @{}
	ForEach ($mPropInst in $global:mTermPropInsts) {
		#add ALL UDPs of the Term Object
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mTermPropValues.Add($mPropInst.PropDefId, $mPropInst.Val)
		}
	}
	return $mTermPropValues
}

function mGetClsPrpNames($ClassId) {
 #get Properties added to this class
	$global:mClsPropInsts = @()
	$global:mClsPropInsts += $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))
	$mActvClsPrpNames = @{}
	ForEach ($mPropInst in $mClsPropInsts) {
		#add UDPs of the Custom Object $UIString["Adsk.QS.ClsObject"] only, filter the properties describing the classification object, add the classification
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId -and $mPropInst.PropDefId -notin $Global:mClsPropDefIds }) {
			$mDispName = ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }).DispName
			$mActvClsPrpNames.Add($mPropInst.PropDefId, $mDispName)
		}
	}
	return $mActvClsPrpNames
}

function mGetAllClsPrpNames($ClassId) {
 #get ALL Properties from this class (no filtering) - used for removal
	$global:mClsPropInsts = @()
	$global:mClsPropInsts += $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))
	$mActvClsPrpNames = @{}
	ForEach ($mPropInst in $mClsPropInsts) {
		#add ALL UDPs of the Custom Object - NO FILTERING for removal
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mDispName = ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }).DispName
			$mActvClsPrpNames.Add($mPropInst.PropDefId, $mDispName)
		}
	}
	return $mActvClsPrpNames
}

function mGetClsPrpValues($ClassId) {
 #get Properties added to this class
	$mClsPropValues = @{}
	ForEach ($mPropInst in $global:mClsPropInsts) {
		If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }) {
			$mClsPropValues.Add($mPropInst.PropDefId, $mPropInst.Val)
		}
	}
	return $mClsPropValues
}

function mGetCustentiesByName([String]$Name) {
	$dsDiag.Trace(">>mGetCustentiesByName searching for: '$Name' with standard: '$global:mActiveStandard'")
	
	# Always search with both name AND standard when standard is available
	if (-not [string]::IsNullOrEmpty($global:mActiveStandard)) {
		# We have a standard - search with 2 conditions (name + standard) for precise match
		$srchConds = New-Object Autodesk.Connectivity.WebServices.SrchCond[] 2
		
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		$propDef = $Global:mAllCustentPropDefs | Where-Object { $_.SysName -eq "Name" }
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3 #Is exactly (or equals)
		$srchCond.SrchTxt = $Name
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond
		
		$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
		$srchCond2.PropDefId = ($Global:mAllCustentPropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.ClsStandard"] }).Id
		$srchCond2.SrchOper = 3 #Is exactly (or equals)
		$srchCond2.SrchTxt = $global:mActiveStandard
		$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[1] = $srchCond2
		
		$dsDiag.Trace("  Searching with name AND standard filter (precise match)")
	}
	else {
		# No standard set - search only by name (fallback for backward compatibility)
		$srchConds = New-Object Autodesk.Connectivity.WebServices.SrchCond[] 1
		
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		$propDef = $Global:mAllCustentPropDefs | Where-Object { $_.SysName -eq "Name" }
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3 #Is exactly (or equals)
		$srchCond.SrchTxt = $Name
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond
		
		$dsDiag.Trace("  Searching by name only (no standard available)")
	}

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
	# method to be called on click of btnSelectClass in AssignClassification-Dialog; it will set the selected class and term (if uniclass) to the file properties and update the main window display accordingly; it will also save the selected class object ID to a temp file for retrieval in post-close event to trigger the classification assignment
	$dsWindow.FindName("txtClsStandard").Text = $global:mActiveStandard
	$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
	$dsWindow.FindName("btnSelectClass").IsEnabled = $true

	# Find which TreeView ComboBox has a selected Class Object and set txtActiveClass
	$selectedClassObject = $null
	for ($i = 1; $i -le 4; $i++) {
		$cmbCls = $AssignClsWindow.FindName("cmbCls$i")
		if ($cmbCls -and $cmbCls.SelectedItem) {
			$selectedClassObject = $cmbCls.SelectedItem
			$dsWindow.FindName("txtActiveClass").Text = $selectedClassObject.Name
			$dsDiag.Trace("Set txtActiveClass = '$($selectedClassObject.Name)' from cmbCls$i")
			break
		}
	}
	
	# Uniclass Extension: If no Class Object selected but a Term is selected, treat Term as Class
	if (-not $selectedClassObject -and $global:mActiveStandard -eq "Uniclass") {
		$dsDiag.Trace("Uniclass mode: No Class Object selected, checking for Term selection...")
		for ($i = 1; $i -le 4; $i++) {
			$cmbTrm = $AssignClsWindow.FindName("cmbTrm$i")
			if ($cmbTrm -and $cmbTrm.SelectedItem) {
				$selectedClassObject = $cmbTrm.SelectedItem
				$dsWindow.FindName("txtActiveClass").Text = $selectedClassObject.Name
				$dsDiag.Trace("Uniclass: Set txtActiveClass = '$($selectedClassObject.Name)' from cmbTrm$i (treating Term as Class)")
				break
			}
		}
	}
	
	# Save the selected class object ID for post-close event
	if ($selectedClassObject) {
		$value = $selectedClassObject.Id
		$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mFileClassId.txt"
	}

	# Merge properties from both Class and Term DataGrids
	# Start with Class properties, then overlay Term properties (Term takes priority)
	$mMergedPropTable = @{}
	
	# First, add all Class properties
	$classProps = $AssignClsWindow.FindName("dtgrdClassProps").ItemsSource
	if ($classProps) {
		foreach ($entry in $classProps.GetEnumerator()) {
			$mMergedPropTable[$entry.Key] = $entry.Value
		}
		$dsDiag.Trace("Added $($classProps.Count) Class properties to merged table")
	}
	
	# Check if user wants to copy Term properties to Title properties
	$chckCopyTermToTitle = $AssignClsWindow.FindName("chckCopyTermToTitle")
	$copyTermToTitle = $chckCopyTermToTitle -and $chckCopyTermToTitle.IsChecked -eq $true
	
	# Then, add/override with Term properties (Term has priority)
	$termProps = $AssignClsWindow.FindName("dtgrdTermProps").ItemsSource
	if ($termProps) {
		foreach ($entry in $termProps.GetEnumerator()) {
			$propertyName = $entry.Key
			$propertyValue = $entry.Value
			
			# If checkbox is checked, map Term properties to Title properties
			if ($copyTermToTitle) {
				# Check if this is a Term language property and map it to Title
				if ($propertyName -eq "Term DE") {
					$propertyName = "Title DE"
					$dsDiag.Trace("Mapped 'Term DE' to 'Title DE'")
				}
				elseif ($propertyName -eq "Term EN") {
					$propertyName = "Title"  # Default Title property
					$dsDiag.Trace("Mapped 'Term EN' to 'Title'")
				}
				elseif ($propertyName -eq "Term FR") {
					$propertyName = "Title FR"
					$dsDiag.Trace("Mapped 'Term FR' to 'Title FR'")
				}
				elseif ($propertyName -eq "Term IT") {
					$propertyName = "Title IT"
					$dsDiag.Trace("Mapped 'Term IT' to 'Title IT'")
				}
				elseif ($propertyName -eq "Term ES") {
					$propertyName = "Title ES"
					$dsDiag.Trace("Mapped 'Term ES' to 'Title ES'")
				}
			}
			
			$mMergedPropTable[$propertyName] = $propertyValue
		}
		$dsDiag.Trace("Added/Overrode with $($termProps.Count) Term properties to merged table (CopyToTitle: $copyTermToTitle)")
	}
	
	$dsDiag.Trace("Final merged table has $($mMergedPropTable.Count) properties")
	
	# Assign the merged table to the main window's DataGrid (sorted alphabetically by property name)
	$dsWindow.FindName("dtgrdClassProps").ItemsSource = mSortPropertyTable($mMergedPropTable)
	
	# Update the 4 class level TextBoxes (txtLevel1, txtLevel2, txtLevel3, txtLevel4)
	# Get the breadcrumb wrapper to access the selected classification levels
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	
	# Initialize all TextBoxes as collapsed
	$dsWindow.FindName("txtLevel1").Visibility = "Collapsed"
	$dsWindow.FindName("txtLevel2").Visibility = "Collapsed"
	$dsWindow.FindName("txtLevel3").Visibility = "Collapsed"
	$dsWindow.FindName("txtLevel4").Visibility = "Collapsed"
	
	# Array of TextBox names corresponding to classification levels 1-4
	$txtBoxNames = @("txtLevel1", "txtLevel2", "txtLevel3", "txtLevel4")
	
	# Iterate through breadcrumb children and populate corresponding TextBoxes
	if ($mBreadCrumb -and $mBreadCrumb.Children.Count -gt 0) {
		for ($i = 0; $i -lt [Math]::Min($mBreadCrumb.Children.Count, 4); $i++) {
			$cmbBreadCrumb = $mBreadCrumb.Children[$i]
			$txtBox = $dsWindow.FindName($txtBoxNames[$i])
			
			if ($cmbBreadCrumb -and $cmbBreadCrumb.SelectedItem) {
				# Get the Name property from the selected item (CustEnt object)
				$txtBox.Text = $cmbBreadCrumb.SelectedItem.Name
				if (-not [string]::IsNullOrEmpty($txtBox.Text)) {
					$txtBox.Visibility = "Visible"
					$dsDiag.Trace("Set $($txtBoxNames[$i]) = '$($txtBox.Text)'")
				}
			}
			else {
				$txtBox.Text = ""
			}
		}
	}
	
	$AssignClsWindow.DialogResult = $true #"OK"
	$AssignClsWindow.Close()
}

function mApplyClassification() {
	# this method applies the selected classification to the file by adding the class/term properties to the file's property definitions and setting the "Class" property value to the selected class/term name; it is called in the post-close event of the Assign Classification dialog after a classification is selected, and also on the main window's Save event to apply any pending classification selection; it also updates the main window display with the assigned classification properties
	$dsDiag.Trace(">>Function mApplyClassification starts...")
	if ($Global:mFile) {
		#the function mFindCustent returns a generic list object
		$Prop["_XLTN_CLSOBJECT"].Value = $dsWindow.FindName("txtActiveClass").Text
		
		#get class object to apply
		$mActiveClass = mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value)
		
		# Check if the selected object is a Class Object or Term
		$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id
		$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject
		
		# Determine which function to use based on object type
		if ($isTerm -and $global:mActiveStandard -eq "Uniclass") {
			# For Uniclass Terms, use mGetTermPrpNames to get ALL properties (including metadata)
			$dsDiag.Trace("Uniclass: Applying Term as Class - using mGetTermPrpNames()")
			$mActvClsPrpNames = mGetTermPrpNames($mActiveClass[0].Id)
		}
		else {
			# For Class Objects and other standards, use mGetClsPrpNames (with filtering)
			$dsDiag.Trace("Applying Class Object - using mGetClsPrpNames()")
			$mActvClsPrpNames = mGetClsPrpNames($mActiveClass[0].Id)
		}
		
		$mPropsAdd = @()
		
		Foreach ($mClsProp in $mActvClsPrpNames.GetEnumerator()) {
			# For Uniclass Terms, filter out classification level names
			# For Class Objects, the filtering is already done in mGetClsPrpNames
			if ($mActvClsPrpNames[$mClsProp.Key] -notin $Global:mClsLevelNames) {
				$mPropsAdd += $mClsProp.Key
				$dsDiag.Trace("  Adding property: $($mActvClsPrpNames[$mClsProp.Key]) (ID: $($mClsProp.Key))")
			}
		}
		
		$dsDiag.Trace("Total properties to add: $($mPropsAdd.Count)")
		
		$mPropsRemove = @()
		$mAddRemoveComment = "Added classification"
		try {
			$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
			if ($mFileUpdated) {
				$dsDiag.Trace("File property definitions updated successfully.")				
			}
			else {
				$dsDiag.Trace("File property definitions update returned false, no changes applied.")
			}

			# update the values for create and edit mode (create = properties added, edit = properties exist, but values may have changed)
			mUpdateClsPropValues
			$dsDiag.Trace("Successfully applied classification with $($mPropsAdd.Count) properties")
		}
		catch {
			$dsDiag.Trace("AddClassification Error on UpdateFilePropertyDefinitions: $($_.Exception.Message)")
		}
	}
}

function mRemoveClassification() {
 #applies to $dsWindow
	#$dsDiag.Trace("Remove Class starts...")
	if ($Prop["_EditMode"]) {
		if ($Global:mFile) {
			$dsDiag.Trace("...remove class - file found")
			
			#get class object to remove
			$mActiveClass = mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value)
			
			# Check if the selected object is a Class Object or Term
			$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id
			$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject
			
			# Determine which function to use based on object type
			if ($isTerm) {
				# For Terms (Uniclass Term-as-Class), use mGetTermPrpNames to get ALL properties
				$dsDiag.Trace("Removing Uniclass Term-as-Class - using mGetTermPrpNames()")
				$mActvClsPrpNames = mGetTermPrpNames($mActiveClass[0].Id)
			}
			else {
				# For Class Objects, use mGetAllClsPrpNames to get ALL properties (including "Class" and other filtered properties)
				$dsDiag.Trace("Removing Class Object - using mGetAllClsPrpNames()")
				$mActvClsPrpNames = mGetAllClsPrpNames($mActiveClass[0].Id)
			}
			
			$mPropsRemove = @()
			
			Foreach ($mClsProp in $mActvClsPrpNames.GetEnumerator()) {
				$mPropsRemove += $mClsProp.Key
				$dsDiag.Trace("  Removing property: $($mClsProp.Value) (ID: $($mClsProp.Key))")
			}

			# EXPLICIT REMOVAL OF "Class" PROPERTY (CLSOBJECT)
			# The "Class" property is added to the FILE to store the assigned class/term name.
			# This property must ALWAYS be explicitly removed from the file, regardless of Class Object or Term.
			# NOTE: We do NOT clear $Prop["_XLTN_CLSOBJECT"].Value here because the Data Standard framework's
			# post-close event automatically adds properties with values back to the file. By leaving the value
			# as-is and only adding the property ID to the removal list, UpdateFilePropertyDefinitions will
			# remove the property definition, which automatically clears the value without triggering re-addition.
			try {
				$mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
				$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
				
				if ($mClassPropertyDef) {
					# Only add if not already in the removal list
					if ($mPropsRemove -notcontains $mClassPropertyDef.Id) {
						$mPropsRemove += $mClassPropertyDef.Id
						$dsDiag.Trace("  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: $($mClassPropertyDef.Id), Display Name: $($mClassPropertyDef.DispName)")
					}
					else {
						$dsDiag.Trace("  [INFO] 'Class' property (CLSOBJECT) already in removal list - ID: $($mClassPropertyDef.Id)")
					}
				}
				else {
					$dsDiag.Trace("  [WARNING] 'Class' property (CLSOBJECT) not found in FILE property definitions")
				}
			}
			catch {
				$dsDiag.Trace("  [ERROR] Failed to find/add Class property for removal: $($_.Exception.Message)")
			}
			
			$dsDiag.Trace("Total properties to remove: $($mPropsRemove.Count)")
			
			$mMsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning(($UIString["Adsk.QS.Classification_11"] -f "`n"), "VDS Sample Configuration", "YesNo")
			if ($mMsgResult -eq "No") { return }

			$mAddRemoveComment = "removed classification"
			$mPropsAdd = @()
			try {
				$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
				if ($mFileUpdated) {
					$dsDiag.Trace("File property definitions updated successfully.")
				}
				else {
					$dsDiag.Trace("File property definitions update returned false, no changes applied.")
				}
				$dsDiag.Trace("Successfully removed $($mPropsRemove.Count) classification properties")
			}
			catch {
				$dsDiag.Trace("Error removing classification: $($_.Exception.Message)")
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
	$dsDiag.Trace("Childrens: " + $children.GetEnumerator)
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	
	# Defensive check: Ensure global variables are initialized
	if (-not $Global:mClassLevelCustentDefIds) {
		$dsDiag.Trace("ERROR: Global mClassLevelCustentDefIds is null - classification system not initialized")
		return
	}
	if (-not $Global:mClassCustentDef) {
		$dsDiag.Trace("ERROR: Global mClassCustentDef is null - classification system not initialized")
		return
	}
	if (-not $Global:mClsObjectCustentDefIds) {
		$dsDiag.Trace("ERROR: Global mClsObjectCustentDefIds is null - classification system not initialized")
		return
	}
	
	# Determine which breadcrumb level was just selected (this is the level we populate TreeView for)
	# Children.Count - 1 = index of the breadcrumb that was just selected
	$currentLevel = $mBreadCrumb.Children.Count - 1  # 0=Level1, 1=Level2, 2=Level3, 3=Level4
	
	$dsDiag.Trace("Processing breadcrumb level $($currentLevel + 1) selection, Children.Count = $($mBreadCrumb.Children.Count)")
	
	# Filter classification levels, class objects, and term objects using the new bucket system
	# Breadcrumb: Use mClassLevelCustentDefIds (Class Levels 1-4 only)
	$mClassLevelObjects = @() #filtered list for the next class level (for breadcrumb)
	$mClassLevelObjects += $children | Where-Object { 
		$_.CustEntDefId -in $Global:mClassLevelCustentDefIds
	}
	
	# TreeView: Use mClsObjectCustentDefIds (Class Objects and Terms only)
	# Need to separate Class Objects from Terms by checking against the specific Class Object definition
	$mClassObjects = @() #filtered list for class objects (for TreeView cmbCls*)
	$mClassObjects += $children | Where-Object { 
		$_.CustEntDefId -eq $Global:mClassCustentDef.Id
	}
	
	$mTermObjects = @() #filtered list for term objects (for TreeView cmbTrm*)
	# Terms are anything in mClsObjectCustentDefIds that is NOT a Class Object
	$mTermObjects += $children | Where-Object { 
		($_.CustEntDefId -in $Global:mClsObjectCustentDefIds) -and
		($_.CustEntDefId -ne $Global:mClassCustentDef.Id)
	}

	$dsDiag.Trace("Filtered children: ClassLevels=$($mClassLevelObjects.Count), ClassObjects=$($mClassObjects.Count), Terms=$($mTermObjects.Count)")

	# Populate the appropriate TreeView ComboBoxes based on which breadcrumb level was selected
	$cmbClsTarget = $null
	$cmbTrmTarget = $null
	switch ($currentLevel) {
		0 { 
			$cmbClsTarget = $AssignClsWindow.FindName("cmbCls1")
			$cmbTrmTarget = $AssignClsWindow.FindName("cmbTrm1")
			$dsDiag.Trace("Populating TreeView Level 1 (cmbCls1/cmbTrm1)")
		}
		1 { 
			$cmbClsTarget = $AssignClsWindow.FindName("cmbCls2")
			$cmbTrmTarget = $AssignClsWindow.FindName("cmbTrm2")
			$dsDiag.Trace("Populating TreeView Level 2 (cmbCls2/cmbTrm2)")
		}
		2 { 
			$cmbClsTarget = $AssignClsWindow.FindName("cmbCls3")
			$cmbTrmTarget = $AssignClsWindow.FindName("cmbTrm3")
			$dsDiag.Trace("Populating TreeView Level 3 (cmbCls3/cmbTrm3)")
		}
		3 { 
			$cmbClsTarget = $AssignClsWindow.FindName("cmbCls4")
			$cmbTrmTarget = $AssignClsWindow.FindName("cmbTrm4")
			$dsDiag.Trace("Populating TreeView Level 4 (cmbCls4/cmbTrm4)")
		}
	}

	# Populate TreeView Class Objects ComboBox
	if ($null -ne $cmbClsTarget -and $mClassObjects.Count -gt 0) {
		$cmbClsTarget.ItemsSource = $mClassObjects
		$cmbClsTarget.DisplayMemberPath = "Name"
		$cmbClsTarget.SelectedValuePath = "Name"
		$cmbClsTarget.SelectedIndex = 0
		$cmbClsTarget.IsEnabled = $true
	}
	else {
		if ($null -ne $cmbClsTarget) {
			$cmbClsTarget.ItemsSource = $null
			$cmbClsTarget.IsEnabled = $false
		}
	}
	
	# Populate TreeView Term Objects ComboBox
	if ($null -ne $cmbTrmTarget -and $mTermObjects.Count -gt 0) {
		$cmbTrmTarget.ItemsSource = $mTermObjects
		$cmbTrmTarget.DisplayMemberPath = "Name"
		$cmbTrmTarget.SelectedValuePath = "Name"
		$cmbTrmTarget.SelectedIndex = 0
		$cmbTrmTarget.IsEnabled = $true
	}
	else {
		if ($null -ne $cmbTrmTarget) {
			$cmbTrmTarget.ItemsSource = $null
			$cmbTrmTarget.IsEnabled = $false
		}
	}

	# Add next level breadcrumb ComboBox ONLY if:
	# 1. We have class level objects for the next level
	# 2. We haven't exceeded 4 levels (Children.Count will be 0,1,2,3 for levels 1-4)
	# 3. Don't add if we're at the 4th breadcrumb already (Children.Count = 3 means 4th level selected)
	if ($mClassLevelObjects.Count -gt 0 -and $mBreadCrumb.Children.Count -lt 4) {
		$cmb = New-Object System.Windows.Controls.ComboBox
		$cmb.Name = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString()
		$cmb.DisplayMemberPath = "Name"
		$cmb.BorderThickness = "0,0,1,0"
		$cmb.HorizontalContentAlignment = "Center"
		$cmb.MinWidth = 140
		$cmb.Height = 26

		$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
		$mBreadCrumb.Children.Add($cmb)
		$cmb.ItemsSource = @($mClassLevelObjects)
		
		# enforce selection changed for single items; auto-open dropdown if only one item available
		if ($mClassLevelObjects.Count -eq 1) { 
			$cmb.SelectedIndex = 0
			mClsLevelCmbSelectionChanged($cmb)
		}
		else {
			$cmb.IsDropDownOpen = $true 
		}

		$cmb.add_SelectionChanged({
				param($mSender, $e)
				$dsDiag.Trace("Breadcrumb SelectionChanged: $($mSender.Name)")
				mClsLevelCmbSelectionChanged($mSender)
			})
		
		$dsDiag.Trace("Added breadcrumb level $($mBreadCrumb.Children.Count) with $($mClassLevelObjects.Count) class level objects")
	}
	else {
		if ($mClassLevelObjects.Count -eq 0) {
			$dsDiag.Trace("No more class level objects found - end of hierarchy")
		}
		if ($mBreadCrumb.Children.Count -ge 4) {
			$dsDiag.Trace("Maximum 4 breadcrumb levels reached - not adding more")
		}
	}

	$AssignClsWindow.FindName("btnResetClsLevels").IsEnabled = $true
} #mAddClsLevelCmbChild

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
				$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_12"]
				$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
			}
			If ($mResultPage.Count -ne 0) {
				$mResultAll.AddRange($mResultPage)
			}
			else { 
				$MsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("Could not find any " + $ClassLevelName, "VDS Sample -- Classification", "OK")
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
		$_Parent = $mBreadCrumb.Children[$_i].SelectedValue
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

	# reset subsequent comboboxes if the new selection does no longer has children.
	mAvlblClsReset
	# add the next combo with the children of the selected item.
	mAddClsLevelCmbChild($mSender.SelectedItem) #-mSender $mSender.SelectedItem
}

function mResetClassSelection {
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	
	# Clear all existing ComboBoxes from the WrapPanel
	while ($mBreadCrumb.Children.Count -gt 0) {
		$cmb = $mBreadCrumb.Children[0]
		if ($cmb.Name) {
			$mBreadCrumb.UnregisterName($cmb.Name)
		}
		$mBreadCrumb.Children.RemoveAt(0)
	}
	
	# Get Level 1 classification objects
	$children = @()
	$children += mGetCustentClsLevelList($UIString["Adsk.QS.ClsLevel_01"]) #-ClassLevelName $UIString["Adsk.QS.ClsLevel_01"]
	if ($children.Count -eq 0) {
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Could not initialize the classification root - probably your base classes do not match the selected Standard", "VDS Sample -- Classification")
		return
	}
	
	# Create and add the first ComboBox to the WrapPanel
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClsBrdCrmb_0"
	$cmb.DisplayMemberPath = "Name"
	$cmb.MinWidth = 140
	$cmb.Height = 26
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "0,0,1,0"
	
	$mBreadCrumb.RegisterName($cmb.Name, $cmb)
	$mBreadCrumb.Children.Add($cmb)
	
	# Now populate the first ComboBox
	$cmb.ItemsSource = $children 
	$cmb.SelectedIndex = -1
	
	# Add selection changed event handler
	$cmb.add_SelectionChanged({
			param($mSender, $e)
			mClsLevelCmbSelectionChanged($mSender)
		})
	
	# Reset all TreeView ComboBoxes (Class Objects and Terms for levels 1-4)
	for ($i = 1; $i -le 4; $i++) {
		$cmbCls = $AssignClsWindow.FindName("cmbCls$i")
		$cmbTrm = $AssignClsWindow.FindName("cmbTrm$i")
		
		if ($cmbCls) {
			$cmbCls.ItemsSource = $null
			$cmbCls.SelectedIndex = -1
			$cmbCls.IsEnabled = $false
		}
		
		if ($cmbTrm) {
			$cmbTrm.ItemsSource = $null
			$cmbTrm.SelectedIndex = -1
			$cmbTrm.IsEnabled = $false
		}
	}
	
	$AssignClsWindow.FindName("btnResetClsLevels").IsEnabled = $false
	$AssignClsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	$AssignClsWindow.FindName("dtgrdTermProps").ItemsSource = $null
}

function mAvlblClsReset {
	# Get current breadcrumb position to determine which TreeView levels to reset
	$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
	$currentLevel = $mBreadCrumb.Children.Count - 1  # 0=Level1, 1=Level2, 2=Level3, 3=Level4
	
	# Reset TreeView ComboBoxes for levels AFTER the current selection
	# If currentLevel=1 (Level 2 selected), reset cmbCls3, cmbCls4, cmbTrm3, cmbTrm4
	for ($i = $currentLevel + 2; $i -le 4; $i++) {
		$cmbCls = $AssignClsWindow.FindName("cmbCls$i")
		$cmbTrm = $AssignClsWindow.FindName("cmbTrm$i")
		
		if ($cmbCls) {
			$cmbCls.ItemsSource = $null
			$cmbCls.SelectedIndex = -1
			$cmbCls.IsEnabled = $false
		}
		
		if ($cmbTrm) {
			$cmbTrm.ItemsSource = $null
			$cmbTrm.SelectedIndex = -1
			$cmbTrm.IsEnabled = $false
		}
	}
	
	# Clear active class display
	if ($null -ne $dsWindow.FindName("txtActiveClass")) {
		$dsWindow.FindName("txtActiveClass").Text = ""
	}
	if ($null -ne $dsWindow.FindName("dtgrdClassProps")) {
		$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	}
	
	# Clear both DataGrids in the AssignClsWindow
	$AssignClsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	$AssignClsWindow.FindName("dtgrdTermProps").ItemsSource = $null
	
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

	# changing the standard initializes/resets the hierarchy selection
	$AssignClsWindow.FindName("cmb_ClsStd").add_SelectionChanged({
			param ($mSender, $e)
			$global:mActiveStandard = $AssignClsWindow.FindName("cmb_ClsStd").SelectedItem.Content
			mInitializeCompClassification
		})

	# selection of treeview combobox items displays the class/term objects data in the grid
	$cmbCls1 = $AssignClsWindow.FindName("cmbCls1")
	$cmbTrm1 = $AssignClsWindow.FindName("cmbTrm1")
	$cmbCls2 = $AssignClsWindow.FindName("cmbCls2")
	$cmbTrm2 = $AssignClsWindow.FindName("cmbTrm2")
	$cmbCls3 = $AssignClsWindow.FindName("cmbCls3")
	$cmbTrm3 = $AssignClsWindow.FindName("cmbTrm3")
	$cmbCls4 = $AssignClsWindow.FindName("cmbCls4")
	$cmbTrm4 = $AssignClsWindow.FindName("cmbTrm4")

	$cmbCls1.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			# Clear other level selections without retriggering events
			$cmbCls2.SelectedIndex = -1
			$cmbCls3.SelectedIndex = -1
			$cmbCls4.SelectedIndex = -1
		
			# preview the properties and default values for this class
			mGetFileClsValues -sendingCmb $mSender
			mGetClsDfltValues -sendingCmb $mSender
		})
	$cmbTrm1.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbTrm2.SelectedIndex = -1
			$cmbTrm3.SelectedIndex = -1
			$cmbTrm4.SelectedIndex = -1
		
			# preview the properties and default values for this term
			mGetTermDfltValues -sendingCmb $mSender
		})
	$cmbCls2.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbCls1.SelectedIndex = -1
			$cmbCls3.SelectedIndex = -1
			$cmbCls4.SelectedIndex = -1

			# preview the properties and default values for this class
			mGetFileClsValues -sendingCmb $mSender
			mGetClsDfltValues -sendingCmb $mSender
		})
	$cmbTrm2.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbTrm1.SelectedIndex = -1
			$cmbTrm3.SelectedIndex = -1
			$cmbTrm4.SelectedIndex = -1
		
			# preview the properties and default values for this term
			mGetTermDfltValues -sendingCmb $mSender
		})
	$cmbCls3.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbCls1.SelectedIndex = -1
			$cmbCls2.SelectedIndex = -1
			$cmbCls4.SelectedIndex = -1

			# preview the properties and default values for this class
			mGetFileClsValues -sendingCmb $mSender
			mGetClsDfltValues -sendingCmb $mSender
		})
	$cmbTrm3.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbTrm1.SelectedIndex = -1
			$cmbTrm2.SelectedIndex = -1
			$cmbTrm4.SelectedIndex = -1
		
			# preview the properties and default values for this term
			mGetTermDfltValues -sendingCmb $mSender
		})
	$cmbCls4.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbCls1.SelectedIndex = -1
			$cmbCls2.SelectedIndex = -1
			$cmbCls3.SelectedIndex = -1

			# preview the properties and default values for this class
			mGetFileClsValues -sendingCmb $mSender
			mGetClsDfltValues -sendingCmb $mSender
		})
	$cmbTrm4.add_SelectionChanged({
			param ($mSender, $e)
			if ($mSender.SelectedIndex -lt 0) { return }  # Skip if clearing selection
		
			$cmbTrm1.SelectedIndex = -1
			$cmbTrm2.SelectedIndex = -1
			$cmbTrm3.SelectedIndex = -1
		
			# preview the properties and default values for this term
			mGetTermDfltValues -sendingCmb $mSender
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
			$global:AssignClsWindow = $null
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
		
		$dsDiag.Trace("Initializing classification breadcrumb with Level 1")
		
		# Initialize the WrapPanel breadcrumb with Level 1 class level entities
		# The breadcrumb will dynamically add ComboBoxes for navigation (max 4 levels)
		# TreeView cmbCls*/cmbTrm* will be populated by mAddClsLevelCmbChild when breadcrumb selection changes
		if ($AssignClsWindow.FindName("wrpClassification2")) {
			$mBreadCrumb = $AssignClsWindow.FindName("wrpClassification2")
			
			if ($mBreadCrumb.Children.Count -lt 1) {
				# Add the first breadcrumb ComboBox for Level 1 navigation
				mAddClsLevelCombo($UIString["Adsk.QS.ClsLevel_01"])
			}
		}
		
		$global:mCompClsInitialized = $true
	}
	else {
		# If already initialized, just reset the selection
		mResetClassSelection
	}
}

function mUpdateClsPropValues() {
	# Update the $Prop values based on the current values in the dtgrdClassProps DataGrid, otherwise VDS would override with old values on close since the property definitions are not updated until after the dialog closes and triggers the post-close event
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