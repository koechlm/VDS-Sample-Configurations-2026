# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


#region BreadCrumb ClassSelection

# Function to update ClsCode based on current breadcrumb selections
# Call this after breadcrumb initialization in edit mode or when ClsLevelCode changes
function mUpdateClsCode {
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	
	if (-not $mBreadCrumb) {
		$dsDiag.Trace("Warning: wrpClassification breadcrumb not found")
		return
	}
	
	# Initialize the level maps hashtable if not exists
	if (-not $Global:_BreadcrumbLevelMaps) {
		$Global:_BreadcrumbLevelMaps = @{}
	}
	
	# Build level maps for all currently selected breadcrumb levels
	for ($i = 1; $i -le 4; $i++) {
		if ($mBreadCrumb.Children[$i] -and $mBreadCrumb.Children[$i].ItemsSource) {
			# Only rebuild if not already cached
			if (-not $Global:_BreadcrumbLevelMaps.ContainsKey($i)) {
				$Global:_BreadcrumbLevelMaps[$i] = mGetCustEntsPropNameValMaps $mBreadCrumb.Children[$i].ItemsSource
			}
		}
	}
	
	# Build and set the concatenated ClsCode
	$concatenatedCode = mBuildClsCode $mBreadCrumb $Global:_BreadcrumbLevelMaps
	$Prop[$UIString["Adsk.QS.ClsCode"]].Value = $concatenatedCode
	
	$dsDiag.Trace("ClsCode initialized/updated to: $concatenatedCode")
}

function mAddCoCombo ([String] $_CoName, $_Standard, $_classes) {	
	$children = mGetCustomEntityList $_CoName $_Standard #-_CoName $_CoName
	If ($null-eq $children) { return }
	# sort the children by Name, case sensitive
	$children = $children | Sort-Object -Property Name -CaseSensitive #-Descending -Unique -Stable

	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $mBreadCrumb.Children.Count.ToString()
	$cmb.DisplayMemberPath = $UIString["LBL19"]
	$cmb.Tooltip = $UIString["ClassTerms_TT01"]
	#If (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
	$cmb.MinWidth = 140
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.Margin = "1,0,0,1"
	#register the name to activate later via indexed name
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) 
	$mBreadCrumb.Children.Add($cmb);
	$cmb.ItemsSource = @($children)

	$mWindowName = $dsWindow.Name
	switch ($mWindowName) {
		"CustomObjectClassifiedWindow" {
			#If (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
		}
		default {
			$cmb.IsDropDownOpen = $false
		}
	}
	$cmb.add_SelectionChanged({
			param($sender, $e)
			#$dsDiag.Trace("1. SelectionChanged, Sender = $sender, $e")
			$dsWindow.FindName("cmb_ClsStd").IsEnabled = $false
			$dsWindow.FindName("cmb_ClsStd").Tooltip = "Reset (X) the classification if you need to switch the standard."
			mCoComboSelectionChanged($sender) #-sender $sender
		});

	#region EditMode CustomObjectTerm or CustomObjectClass Window
	If ($dsWindow.Name -eq "CustomObjectClassifiedWindow") {
		If ($Prop["_EditMode"].Value -eq $true) {
			$_cmbNames = @()
			Foreach ($_cmbItem in $cmb.Items) {
				#$dsDiag.Trace("---$_cmbItem---")
				$_cmbNames += $_cmbItem.Name
			}
			$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
			If ($_classes[0]) { #avoid activation of null ;)
				$_CurrentName = $_classes[0]
				#$dsDiag.Trace("Current Name: $_CurrentName ")
				#get the index of name in array
				$i = 0
				Foreach ($_Name in $_cmbNames) {
					$_1 = $_cmbNames.count
					$_2 = $_cmbNames[$i]
					#$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
					If ($_cmbNames[$i] -eq $_CurrentName) {
						$_IndexToActivate = $i
					}
					$i += 1
				}
				#$dsDiag.Trace("Index of current name: $_IndexToActivate ")
				$cmb.SelectedIndex = $_IndexToActivate			
			} #end If classes[0]
			
		}
	}
	#endregion
} # addCoCombo

function mAddCoComboChild ($data) {
	$children = @()
	$children = mGetCustomEntityUsesList($data) #-sender $data
	If ($children.count -eq 0) { return }
		
	#Filter classification levels and classes
	if (-not $Global:mClassLevelCustentDefIds) {
		$Global:mAllCustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$Global:mCustentUdpDefs = $Global:mAllCustentPropDefs | Where-Object { $_.IsSys -eq $false }
		$Global:mCustentDefs = $vault.CustomEntityService.GetAllCustomEntityDefinitions()
		#configuration info - the custom object names used for the classification structure may vary. Align Custent names of your Vault in UIStrings ADSK.WS.ClassLEver_*
		$Global:mClsLevelNames = ($UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], $UIString["Adsk.QS.ClsLevel_04"])
		$Global:mClassLevelCustentDefIds = ($Global:mCustentDefs | Where-Object { $_.DispName -in $mClsLevelNames }).Id
	}

	$mClassLevelObjects = @() #filtered list for the 4 levels
	$mClassLevelObjects += $children | Where-Object { $_.CustEntDefId -in $Global:mClassLevelCustentDefIds }
	$children = $mClassLevelObjects
	
	If ($children.count -eq 0) { return }

	# sort the children by Name, case sensitive
	$children = $children | Sort-Object -Property Name -CaseSensitive #-Descending -Unique -Stable
	
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = $UIString["LBL19"]	
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.Margin = "1,0,0,1"
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.MinWidth = 140

	#register the name to activate later via indexed name
	$mBreadCrumb.RegisterName($cmb.Name, $cmb)
	$mBreadCrumb.Children.Add($cmb)
	$cmb.ItemsSource = @($children)

	$mWindowName = $dsWindow.Name
	switch ($mWindowName) {
		"CustomObjectClassifiedWindow" {
			If (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) { $cmb.IsDropDownOpen = $true }
		}
		default {
			$cmb.IsDropDownOpen = $true
		}
	}

	# create a global list of all level items' meta data
	#$Global:_breadCrumbMetaData = New-Object breadCrumbMetaData

	$cmb.add_SelectionChanged({
			param($sender, $e)
			$dsDiag.Trace("next. SelectionChanged, Sender = $sender")
			mCoComboSelectionChanged($sender) #-sender $sender
		});

	$_i = $mBreadCrumb.Children.Count
	$_Label = "lblGroup_" + $_i
	$dsDiag.Trace("Label to display: $_Label - but not longer used")
	# 	$dsWindow.FindName("$_Label").Visibility = "Visible"
	
	#region EditMode for CustomObjectTerm or CustomObjectClassWindow
	If ($dsWindow.Name -eq "CustomObjectClassifiedWindow") {
		If ($Prop["_EditMode"].Value -eq $true) {
			Try {
				$_cmbNames = @()
				Foreach ($_cmbItem in $cmb.Items) {
					#$dsDiag.Trace("---$_cmbItem---")
					$_cmbNames += $_cmbItem.Name
				}
				#$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
				#get the index of name in array
				If ($_classes[$_i - 2]) { #avoid activation of null ;)
					$_CurrentName = $_classes[$_i - 2] #remember the number of breadcrumb children is +2 (delete button, and the class start with index 0)
					#$dsDiag.Trace("Current Name: $_CurrentName ")
					$i = 0
					Foreach ($_Name in $_cmbNames) {
						$_1 = $_cmbNames.count
						$_2 = $_cmbNames[$i]
						#$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
						If ($_cmbNames[$i] -eq $_CurrentName) {
							$_IndexToActivate = $i
						}
						$i += 1
					}
					#$dsDiag.Trace("Index of current name: $_IndexToActivate ")
					$cmb.SelectedIndex = $_IndexToActivate
				} #end
							
			} #end try
			catch {
				$dsDiag.Trace("Error activating an existing index in edit mode.")
			}
		}
	}
	#endregion
} #addCoComboChild

function mGetCustomEntityList ([String] $_CoName, [String] $_Standard) {
	try {
		$dsDiag.Trace(">> mGetCustomEntityList started")		
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 2		
		$srchConds[0] = mCreateClsSearchCond "Category Name" $_CoName "AND" # note - for any reason, the "Category Name can't be replaced by a variable"
		$srchConds[1] = mCreateClsSearchCond $Prop["_XLTN_CLSSTANDARD"].Name $_Standard "AND"

		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

		while (($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits)) {
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds, @($srchSort), [ref]$bookmark, [ref]$searchStatus)
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent") {
				#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
				$dsWindow.FindName("txtTermStatusMsg").Text = $UIString["ClassTerms_MSG04"]
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
			}
			If ($mResultPage.Count -ne 0) {
				$mResultAll.AddRange($mResultPage)
			}
			else { 
				#$MsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("Could not find any " + $_CoName, "VDS Sample -- Classified Objects", "OK")
				break;
			}
		}
		#$dsDiag.Inspect("mResultAll")

		return $mResultAll
	}
	catch { 
		$dsDiag.Trace("!! Error in mGetCustomEntityList")
	}
}

function mGetCustomEntityUsesList ($sender) {
	try {
		$dsDiag.Trace(">> mGetCustomEntityUsesList started")
		$mBreadCrumb = $dsWindow.FindName("wrpClassification")
		$_i = $mBreadCrumb.Children.Count - 1
		$_CurrentCmbName = "cmbBreadCrumb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClass = $mBreadCrumb.Children[$_i].SelectedValue.Name
		#[System.Windows.MessageBox]::Show("Currentclass: $_CurrentClass and Level# is $_i")
		switch ($_i - 1) {
			0 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_01"] }
			1 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_02"] }
			2 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_03"] }
			3 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_04"] }
			4 { $mSearchFilter = $UIString["Adsk.QS.ClsObject"] }
			default { $mSearchFilter = "*" }
		}
		$_customObjects = mGetCustomEntityList($mSearchFilter) #-_CoName $mSearchFilter
		$_Parent = $_customObjects | Where-Object { $_.Name -eq $_CurrentClass }
		try {
			$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id), @("CUSTENT"))
			If ($links) {
				$linkIds = @()
				$links | ForEach-Object { $linkIds += $_.ToEntId }
				$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds);
				#todo: check that we need to filter the list returned
				$dsDiag.Trace(".. mgetCustomEntityUsesList finished - returns $mLinkedCustObjects <<")
				return $mLinkedCustObjects #$global:_Groups
			}
			Else { return }
		}
		catch {
			$dsDiag.Trace("!! Error getting links of Parent Co !!")
			return $null
		}
	}
	catch { $dsDiag.Trace("!! Error in mAddCoComboChild !!") }
}

# Helper function to build concatenated ClsCode from all selected breadcrumb levels
# PLUS the current object's own ClsLevelCode property value
function mBuildClsCode($mBreadCrumb, $levelMaps) {
	$codeParts = @()
	$clsLevelCodeKey = $UIString["Adsk.QS.ClsLevelCode"]
	
	# Iterate through breadcrumb children (skip index 0 which is the reset button)
	# These represent the PARENT hierarchy levels
	for ($i = 1; $i -le 4; $i++) {
		if ($mBreadCrumb.Children[$i] -and $mBreadCrumb.Children[$i].SelectedItem) {
			$selectedItem = $mBreadCrumb.Children[$i].SelectedItem
			$levelMap = $levelMaps[$i]
			
			if ($null -ne $levelMap -and $null -ne $selectedItem.Num) {
				$levelCode = $levelMap[$selectedItem.Num][$clsLevelCodeKey]
				
				# Only add non-empty level codes from parent hierarchy
				if (![string]::IsNullOrWhiteSpace($levelCode)) {
					$codeParts += $levelCode
				}
			}
		}
		else {
			# No more levels selected, stop building
			break
		}
	}
	
	# Add the CURRENT object's own ClsLevelCode property value at the end
	# This is the code for the object being edited/created
	if ($Prop[$clsLevelCodeKey]) {
		$currentObjCode = $Prop[$clsLevelCodeKey].Value
		if (![string]::IsNullOrWhiteSpace($currentObjCode)) {
			$codeParts += $currentObjCode
			$dsDiag.Trace("Added current object's ClsLevelCode: $currentObjCode")
		}
	}
	
	# Join all parts with underscore delimiter
	if ($codeParts.Count -gt 0) {
		$finalCode = $codeParts -join "_"
		$dsDiag.Trace("Built ClsCode from $($codeParts.Count) parts: $finalCode")
		return $finalCode
	}
	else {
		return $null
	}
}

function mCoComboSelectionChanged ($sender) {
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	[int]$position = $sender.Name.Split('_')[1]

	# Store property maps for each level in a hashtable for easy access
	if (-not $Global:_BreadcrumbLevelMaps) {
		$Global:_BreadcrumbLevelMaps = @{}
	}

	# Cache the property map for the current level
	switch ($position) {
		1 { $Global:_BreadcrumbLevelMaps[1] = mGetCustEntsPropNameValMaps $sender.ItemsSource }
		2 { $Global:_BreadcrumbLevelMaps[2] = mGetCustEntsPropNameValMaps $sender.ItemsSource }
		3 { $Global:_BreadcrumbLevelMaps[3] = mGetCustEntsPropNameValMaps $sender.ItemsSource }
		4 { $Global:_BreadcrumbLevelMaps[4] = mGetCustEntsPropNameValMaps $sender.ItemsSource }
		Default {}
	}
						
	# Remove all child combo boxes below the current selection
	$children = $mBreadCrumb.Children.Count - 1
	while ($children -gt $position ) {
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name)
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children])
		
		# Clear cached map for removed level
		if ($children -ge 1 -and $children -le 4) {
			$Global:_BreadcrumbLevelMaps.Remove($children)
		}
		$children--
	}

	Try {
		# Fill level name properties for each breadcrumb child
		if ($mBreadCrumb.Children[1]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_01"]].Value = $mBreadCrumb.Children[1].SelectedItem.Name
		}
		else {
			$Prop[$UIString["Adsk.QS.ClsLevel_01"]].Value = ""
		}
		
		if ($mBreadCrumb.Children[2]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_02"]].Value = $mBreadCrumb.Children[2].SelectedItem.Name
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_02"]].Value = ""
		}
		
		if ($mBreadCrumb.Children[3]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_03"]].Value = $mBreadCrumb.Children[3].SelectedItem.Name
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_03"]].Value = ""
		}
		
		if ($mBreadCrumb.Children[4]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_04"]].Value = $mBreadCrumb.Children[4].SelectedItem.Name
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_04"]].Value = ""
		}
		
		if ($mBreadCrumb.Children[5]) { 
			$Prop[$UIString["Adsk.QS.ClsObject"]].Value = $mBreadCrumb.Children[5].SelectedItem.Name
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsObject"]].Value = ""
		}

		# Build concatenated ClsCode from all selected levels using helper function
		$concatenatedCode = mBuildClsCode $mBreadCrumb $Global:_BreadcrumbLevelMaps
		$Prop[$UIString["Adsk.QS.ClsCode"]].Value = $concatenatedCode
		
		$dsDiag.Trace("ClsCode updated to: $concatenatedCode")

		# Write the highest level Custent Id to a text file for post-close event
		if ($mBreadCrumb.Children[$children] -and $mBreadCrumb.Children[$children].SelectedItem) {
			$value = $mBreadCrumb.Children[$children].SelectedItem.Id
			$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"
		}
	}
	catch {
		$dsDiag.Trace("Error in mCoComboSelectionChanged: $_")
	}
	
	$dsDiag.Trace("Combo selection changed at position $position")

	#don't continue adding children according the classification group level
	switch ($Prop["_Category"].Value) {
		$UIString["Adsk.QS.ClsLevel_02"] {
			$dsDiag.Trace("Main group is the object's level; don't add a child. Position $($position)")
			return
		}
		
		$UIString["Adsk.QS.ClsLevel_03"] {
			if ($position -eq 2) {
				return
			}
			else {
				mAddCoComboChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}
		
		$UIString["Adsk.QS.ClsLevel_04"] {
			if ($position -eq 3) {
				return
			}
			else {
				mAddCoComboChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}

		$UIString["Adsk.QS.ClsObject"] {
			if ($position -eq 4) {
				return
			}
			else {
				mAddCoComboChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}

		default {
			mAddCoComboChild($sender.SelectedItem) #-sender $sender.SelectedItem
		}
	}
}

function mResetClassFilter([Bool] $ShowWarning = $true) {
	$dsDiag.Trace(">> Reset Filter started...")
	$mWindowName = $dsWindow.Name
	switch ($mWindowName) {
		"CustomObjectClassifiedWindow" {
			If ($Prop["_CreateMode"].Value -eq $true)
			{
				$mBreadCrumb = $dsWindow.FindName("wrpClassification")
				$mBreadCrumb.Children[1].SelectedIndex = -1
				$dsWindow.FindName("cmb_ClsStd").IsEnabled = $true
				$dsWindow.FindName("cmb_ClsStd").Tooltip = $UIString["Adsk.QS.ClsTT_01"]
			}
			else {				
				$mBreadCrumb = $dsWindow.FindName("wrpClassification")
				$mBreadCrumb.Children[1].SelectedIndex = -1
				# don't allow to change the Standard - the breadcrump selection is bound to the assigned standard
				$dsWindow.FindName("cmb_ClsStd").IsEnabled = $false
			}

			#reset the class level driven property values
			$Global:mClsLevelNames | ForEach-Object {
				Try {
					$Prop[$_].Value = ""
				}
				catch {}
			}
			$Prop[$UIString["Adsk.QS.ClsCode"]].Value = ""
		}
		default {
			$mBreadCrumb = $dsWindow.FindName("wrpClassification")
			$mBreadCrumb.Children[1].SelectedIndex = -1
		}
	}

	$dsDiag.Trace("...Reset Filter finished <<")
}
#endregion BreadCrumb ClassSelection