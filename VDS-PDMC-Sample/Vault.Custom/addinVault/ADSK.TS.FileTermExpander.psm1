# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


#region CatalogLookUp

class CatalogData {
	[string]$Term_DE
	[string]$Term_EN
	[string]$Term_FR
	[string]$Term_IT
	[string]$Term_ES
}

function mInitializeTermExpander {
     
	If ($dsWindow.FindName("expTermSearch")) {      							
		Try {
			Switch ($dsWindow.Name) {
				"AutoCADWindow" {
					If ($Prop["GEN-TITLE-DES1"]) { $dsWindow.FindName("mSearchTermText").text = $Prop["GEN-TITLE-DES1"].Value }
					If ($Prop["Title"]) { $dsWindow.FindName("mSearchTermText").text = $Prop["Title"].Value }
				}
				"InventorWindow" {
					$dsWindow.FindName("mSearchTermText").Text = $Prop["Title"].Value #Inventor has its default property localization
				}
				default {
					#applies to all Vault windows
					$dsWindow.FindName("mSearchTermText").Text = $Prop["_XLTN_TITLE"].Value
				}
			}
			
			# introduce a global variable for the active standard, set with cmb_ClsStd
			$dsWindow.FindName("cmb_ClsStd").SelectedIndex = 0 #reset to default standard
			$Global:mActiveStandard = $dsWindow.FindName("cmb_ClsStd").SelectedItem.Content
			
			If ($mTermCatalogInitialized -ne $true) {
				If (-not $UIString["Adsk.QS.ClsLevel_01"]) { $UIString = mGetUIStrings } #the psm library might not get the VDS default variable				
				mAddTrmClsCmb -_CoName $UIString["Adsk.QS.ClsLevel_01"] -_Standard $Global:mActiveStandard #enables classification filter for catalog of terms starting with segment

				$dsWindow.FindName("dataGrdTermsFound").add_SelectionChanged({
						param($sender, $SelectionChangedEventArgs)
						#$dsDiag.Trace(".. TermsFoundSelection")
						IF ($dsWindow.FindName("dataGrdTermsFound").SelectedItem) {
							$dsWindow.FindName("btnAdopt").IsEnabled = $true
							$dsWindow.FindName("btnAdopt").IsDefault = $true
						}
						Else {
							$dsWindow.FindName("btnAdopt").IsEnabled = $false
							$dsWindow.FindName("btnSearchTerm").IsDefault = $true
						}
					})

				$dsWindow.FindName("cmb_ClsStd").add_SelectionChanged({
						param($sender, $SelectionChangedEventArgs)
						#$dsDiag.Trace(".. ClsStandard Selection")

						# re-initialize the level selection for the new standard.
						$Global:mActiveStandard = $dsWindow.FindName("cmb_ClsStd").SelectedItem.Content

						# reset the current classification filter and apply the new one based on the standard selected;
						mResetTermClassFilter
					})
				
				#close the expander as another property is selected 
				$dsWindow.FindName("DSDynamicCategoryProperties").add_GotFocus({
						$dsWindow.FindName("expTermSearch").Visibility = "Collapsed"
						$dsWindow.FindName("expTermSearch").IsExpanded = $false
						$dsWindow.FindName("btnSearchTerm").IsDefault = $false
					})

				$Global:mTermCatalogInitialized = $true
			}
			
			$dsWindow.FindName("expTermSearch").Visibility = "Visible"
			$dsWindow.FindName("expTermSearch").IsExpanded = $true
			$dsWindow.FindName("btnSearchTerm").IsDefault = $true

		}	
		catch { 
			#$dsDiag.Trace("The expander TermCatalog is not present. Contact your VDS administrator.")
			$mErrorMsg = "The expander TermCatalog is not present or couldn't initialize. Contact your VDS administrator."
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($mErrorMsg, "VDS Sample Configuration")
		}
	}#if Term Catalog Expander exists
}

function mSearchTerms {
	Try {
		# Clear the status message
		If ($dsWindow.FindName("txtTermStatusMsg")) {
			$dsWindow.FindName("txtTermStatusMsg").Text = ""
			$dsWindow.FindName("txtTermStatusMsg").Visibility = "Collapsed"
			$dsDiag.Trace("Status message cleared")
		}

		# change the cursor to waiting state
		$dsWindow.Cursor = [System.Windows.Input.Cursors]::Wait

		#$dsDiag.Trace(">> search COs terms")
		$dsWindow.FindName("dataGrdTermsFound").ItemsSource = $null

		$mSearchText1 = $dsWindow.FindName("mSearchTermText").Text
		If (!$mSearchText1) { $mSearchText1 = "*" }

		# the search conditions depend on the filters set (4 groups, 4 languages; the number has to match
		$_NumConds = 3 #we have 3 conditions as minimum: category "term" + classification standard + search text
		$mBreadCrumb = $dsWindow.FindName("wrpClassification")
		$_t1 = $mBreadCrumb.Children[0].SelectedIndex
		If ($mBreadCrumb.Children[0].SelectedIndex -ge 0) { $_NumConds += 1 }
		If ($mBreadCrumb.Children[1].SelectedIndex -ge 0) { $_NumConds += 1 }
		If ($mBreadCrumb.Children[2].SelectedIndex -ge 0) { $_NumConds += 1 }
		If ($mBreadCrumb.Children[3].SelectedIndex -ge 0) { $_NumConds += 1 }

		# check the language columns/properties to search in
		If ($dsWindow.FindName("chkDE").IsChecked -eq $true) { $_NumConds += 1 } #default = not checked
		If ($dsWindow.FindName("chkEN").IsChecked -eq $true) { $_NumConds += 1 }

		If ($dsWindow.FindName("chkFR").IsChecked -eq $true) { $_NumConds += 1 }
		If ($dsWindow.FindName("chkIT").IsChecked -eq $true) { $_NumConds += 1 }
		If ($dsWindow.FindName("chkES").IsChecked -eq $true) { $_NumConds += 1 }

		# add all selected languages to search in; apply OR conditions
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] $_NumConds
		$_i = 0

		#the default search condition object type is custom object "term"
		$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["ClassTerms_08"] $UIString["ClassTerms_00"] "AND" #Search in "Category Name" AND "Term" 
		$_i += 1
		
		#add the active classification standard as a default search criteria
		if ($Global:mActiveStandard) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsStandard"] $Global:mActiveStandard "AND"
			$_i += 1
			$dsDiag.Trace("Classification Standard filter applied: $($Global:mActiveStandard)")
		}
		if ($_NumConds -gt 3) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["LBL19"] $mSearchText1 "OR" #Search in Names = main language $UIString["LBL19"]
			$_i += 1
		}
		Else {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["LBL19"] $mSearchText1 "AND" #Search in Names = main language $UIString["LBL19"]
			$_i += 1
		}
		
		#add other conditions by settings read from dialog
		If ($dsWindow.FindName("chkDE").IsChecked -eq $true) {
			$srchConds[$_i ] = mTerm_CreateClsSrchCond $UIString["ClassTerms_09"] $mSearchText1 "OR" #Term DE
			$_i += 1
		}
		If ($dsWindow.FindName("chkEN").IsChecked -eq $true) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["ClassTerms_10"] $mSearchText1 "OR"  #Term EN
			$_i += 1
		}
		If ($dsWindow.FindName("chkFR").IsChecked -eq $true) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["ClassTerms_11"] $mSearchText1 "OR"  #Term FR
			$_i += 1
		}
		If ($dsWindow.FindName("chkIT").IsChecked -eq $true) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["ClassTerms_12"] $mSearchText1 "OR"  #Term IT
			$_i += 1
		}
		If ($dsWindow.FindName("chkES").IsChecked -eq $true) {
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["ClassTerms_12a"] $mSearchText1 "OR"  #Term ES
			$_i += 1
		}

		# If filters are used limit the search to the classification groups. Apply AND conditions
		If ($mBreadCrumb.Children[0].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[0].Text
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsLevel_01"] $mSearchGroupName "AND"
			$_i += 1
		}
		If ($mBreadCrumb.Children[1].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[1].Text
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsLevel_02"] $mSearchGroupName "AND"
			$_i += 1
		}
		If ($mBreadCrumb.Children[2].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[2].Text
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsLevel_03"] $mSearchGroupName "AND"
			$_i += 1
		}
		If ($mBreadCrumb.Children[3].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[3].Text
			$srchConds[$_i] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsLevel_04"] $mSearchGroupName "AND"
			$_i += 1
		}
		$dsDiag.Trace(" search conditions build")

		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'
	
		# Determine if search criteria is too broad (no levels selected and wildcard search text)
		$hasLevelFilter = ($mBreadCrumb.Children[0].SelectedIndex -ge 0) -or 
		($mBreadCrumb.Children[1].SelectedIndex -ge 0) -or 
		($mBreadCrumb.Children[2].SelectedIndex -ge 0) -or 
		($mBreadCrumb.Children[3].SelectedIndex -ge 0)
		$hasSearchText = ($mSearchText1 -ne "*")
		$isBroadSearch = -not ($hasLevelFilter -or $hasSearchText)
		
		if ($isBroadSearch) {
			$dsDiag.Trace("Broad search detected (no levels, no search text). Limiting to single page.")
		}
		
		# Fetch results - either single page or all pages depending on search criteria
		if ($isBroadSearch) {
			# Limit to single page for broad searches
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds, @($srchSort), [ref]$bookmark, [ref]$searchStatus)
			
			# Check indexing status
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent") {
				$dsWindow.FindName("txtTermStatusMsg").Text = $UIString["Adsk.QS.Classification_12"]
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
			}
			
			# Check if results were found
			If ($mResultPage.Count -eq 0) {
				$dsWindow.FindName("txtTermStatusMsg").Text = $UIString["ClassTerms_MSG03"]
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
				$global:_SearchResult = $mResultAll
				$dsWindow.Cursor = [System.Windows.Input.Cursors]::Arrow
				Return
			}
			
			# Add first page results
			$mResultAll.AddRange($mResultPage)
			
			# Show warning about too many results
			If ($searchStatus.TotalHits -gt $mResultPage.Count) {
				$dsDiag.Trace("Too many results found. Total: $($searchStatus.TotalHits), Showing: $($mResultPage.Count)")
				$dsWindow.FindName("txtTermStatusMsg").Text = "Too many results ($($searchStatus.TotalHits) found). Showing first $($mResultPage.Count). Please refine your search criteria (select classification level or enter search text)."
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
			}
			Else {
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Collapsed"
			}
		}
		else {
			# Fetch all pages for refined searches, but only retrieve properties for first page
			while (($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits)) {
				$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds, @($srchSort), [ref]$bookmark, [ref]$searchStatus)
				
				# Check indexing status
				If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent") {
					$dsWindow.FindName("txtTermStatusMsg").Text = $UIString["Adsk.QS.Classification_12"]
					$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
				}
				
				If ($mResultPage.Count -ne 0) {
					$mResultAll.AddRange($mResultPage)
					
					# Stop after first page - we'll only process first page properties
					break
				}
				else {
					$dsWindow.FindName("txtTermStatusMsg").Text = $UIString["ClassTerms_MSG03"]
					$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
					break
				}
			}
			
			# Show warning if more results exist beyond first page
			If ($searchStatus.TotalHits -gt $mResultAll.Count) {
				$dsDiag.Trace("Multiple pages found. Total: $($searchStatus.TotalHits), Showing: $($mResultAll.Count)")
				$dsWindow.FindName("txtTermStatusMsg").Text = "Showing first $($mResultAll.Count) of $($searchStatus.TotalHits) results. Further refinement recommended."
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Visible"
			}
			Else {
				$dsWindow.FindName("txtTermStatusMsg").Visibility = "Collapsed"
			}
		}

		$global:_SearchResult = $mResultAll	
		If ($_SearchResult.Count -lt 1) {
			$dsWindow.Cursor = [System.Windows.Input.Cursors]::Arrow
			Return
		}
		# 	retrieve all properties of the COs found
		$_data = @()
	
		$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$_SearchResult | ForEach-Object {
			$dsDiag.Trace(" ---iterates search result for properties...")
			$properties = $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", $_.Id) #Properties attached to the CO
			$props = @{}

			foreach ($property in $properties) {
				$dsDiag.Trace("Iiterates properties to get DefIDs...")

				Try {
					$propDef = $propDefs | Where-Object { $_.Id -eq $property.PropDefId }
					$props[$propDef.DispName] = $property.Val
				} 
				catch { $dsDiag.Trace("ERROR ---iterates search result for properties failed !! ---") }
			}

			$dsDiag.Trace(" ---iterates search result for properties finished") 
			#create a row for the element and it's properties
			$row = New-Object CatalogData
			$row.Term_DE = $props[$UIString["ClassTerms_09"]]  # Term DE
			$row.Term_EN = $props[$UIString["ClassTerms_10"]]  # Term EN
			$row.Term_FR = $props[$UIString["ClassTerms_11"]]  # Term FR
			$row.Term_IT = $props[$UIString["ClassTerms_12"]]  # Term IT
			$row.Term_ES = $props[$UIString["ClassTerms_12a"]]  # Term ES
		
			$_data += $row
			$dsDiag.Trace("...iterates search result for properties finished.") 
		}
		$dsWindow.FindName("dataGrdTermsFound").ItemsSource = $_data 
	}
	catch {
		$dsDiag.Trace("ERROR --- in m_SearchTerms function") 
	}
	Finally {
		# reset the cursor to default state
		$dsWindow.Cursor = [System.Windows.Input.Cursors]::Arrow
	}
}

function mTerm_CreateClsSrchCond ([String] $PropName, [String] $mSearchTxt, [String] $AndOr) {
	$dsDiag.Trace("--SearchCond creation starts... for $PropName and $mSearchTxt ---")
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propNames = @($PropName) #$UIString["LBL6"]
	$propDefIds = @{}
	foreach ($name in $propNames) {
		$propDef = $propDefs | Where-Object { $_.dispName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 1
	$srchCond.SrchTxt = $mSearchTxt
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	
	If ($AndOr -eq "AND") {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	}
	Else {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::May
	}
	$dsDiag.Trace("--SearchCond creation finished. ---")
	return $srchCond
} 

function m_SelectTerm {
	$dsDiag.Trace("Term_DE selected to get value written to Title field")
	try {		
		$mSelectedItem = $dsWindow.FindName("dataGrdTermsFound").SelectedItem

		If ($dsWindow.Name -eq "AutoCADWindow") {
			# check language override settings of VDS
			$mLCode = @{}
			$mLCode += mGetDBOverride
			#If override exists, apply it, else continue with $PSUICulture
			If ($mLCode["UI"] -eq "de-DE") {
				If ($Prop["GEN-TITLE-DES1"]) { $Prop["GEN-TITLE-DES1"].Value = $mSelectedItem.Term_DE } #AutoCAD Mechanical Title Attribute Name
				If ($Prop["Title"]) { $Prop["Title"].Value = $mSelectedItem.Term_EN } #Vanilla AutoCAD Title Attribute Name
				Try {
					$Prop["Title DE"].Value = $mSelectedItem.Term_DE
				}
				catch { $dsDiag.Trace("Titel DE does not exist") }
			}
			Else {
				If ($Prop["GEN-TITLE-DES1"]) { $Prop["GEN-TITLE-DES1"].Value = $mSelectedItem.Term_EN } #AutoCAD Mechanical Title Attribute Name
				If ($Prop["Title"]) { $Prop["Title"].Value = $mSelectedItem.Term_EN } #Vanilla AutoCAD Title Attribute Name
				Try {
					$Prop["Title DE"].Value = $mSelectedItem.Term_DE
				}
				catch { $dsDiag.Trace("Title DE does not exist") }
			}
			Try {
				$Prop["Title FR"].Value = $mSelectedItem.Term_FR
			}
			catch { $dsDiag.Trace("Title FR does not exist") }
				
			Try {
				$Prop["Title IT"].Value = $mSelectedItem.Term_IT
			}
			catch { $dsDiag.Trace("Title IT does not exist") }
				
			Try {
				$Prop["Title ES"].Value = $mSelectedItem.Term_ES
			}
			catch { $dsDiag.Trace("Title ES does not exist") }
				
		}
		If ($dsWindow.Name -eq "InventorWindow") {
			#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			$_temp1 = $dsWindow.FindName("Categories").SelectedIndex
			#endregion

			# check language override settings of VDS
			$mLCode = @{}
			$mLCode += mGetDBOverride
			#If override exists, apply it, else continue with $PSUICulture
			If ($mLCode["UI"] -eq "de-DE") {
				$Prop["Title"].Value = $mSelectedItem.Term_EN
				Try {
					$Prop["Title DE"].Value = $mSelectedItem.Term_DE
				}
				catch { $dsDiag.Trace("Title DE does not exist") }
			} 
			Else {
				$Prop["Title"].Value = $mSelectedItem.Term_EN
				Try {
					$Prop["Title DE"].Value = $mSelectedItem.Term_DE
				}
				catch { $dsDiag.Trace("Title DE does not exist") }
			}	
			Try {
				$Prop["Title FR"].Value = $mSelectedItem.Term_FR
			}
			catch { $dsDiag.Trace("Title FR does not exist") }
		
			Try {
				$Prop["Title IT"].Value = $mSelectedItem.Term_IT
			}
			catch { $dsDiag.Trace("Title IT does not exist") }
			
			Try {
				$Prop["Title ES"].Value = $mSelectedItem.Term_ES
			}
			catch { $dsDiag.Trace("Title ES does not exist") }
			
		}
		If ($dsWindow.Name -eq "FileWindow") {
			
			#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			$_temp10 = $dsWindow.FindName("DocTypeCombo").SelectedIndex
			$_temp40 = $dsWindow.FindName("NumSchms").IsEnabled
			$_temp41 = $dsWindow.FindName("btnOK").IsEnabled
			#endregion

			$Prop["_XLTN_TITLE"].Value = $mSelectedItem.Term_EN
			Try {
				$Prop["_XLTN_TITLE-DE"].Value = $mSelectedItem.Term_DE
			}
			catch { $dsDiag.Trace("Title DE does not exist") }
			Try {
				$Prop["_XLTN_TITLE-EN"].Value = $mSelectedItem.Term_EN
			}
			catch { $dsDiag.Trace("Title EN does not exist") }
			Try {
				$Prop["_XLTN_TITLE-FR"].Value = $mSelectedItem.Term_FR
			}
			catch { $dsDiag.Trace("Title FR does not exist") }
			Try {
				$Prop["_XLTN_TITLE-IT"].Value = $mSelectedItem.Term_IT
			}
			catch { $dsDiag.Trace("Title IT does not exist") }
			Try {
				$Prop["_XLTN_TITLE-ES"].Value = $mSelectedItem.Term_ES
			}
			catch { $dsDiag.Trace("Title ES does not exist") }
		}

		$dsWindow.FindName("btnSearchTerm").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab-rendering restore
		If ($_temp1) {	$dsWindow.FindName("Categories").SelectedIndex = $_temp1 }
		If ($_temp10) { $dsWindow.FindName("DocTypeCombo").SelectedIndex = $_temp10 }
		If ($_temp40) { $dsWindow.FindName("NumSchms").IsEnabled = $_temp40 }
		If ($_temp41) { $dsWindow.FindName("btnOK") = $_temp41 } 
		#endregion
	}
	Catch {
		$dsDiag.Trace("Error writing term.value(s) to property field")
	}
	
	$dsWindow.FindName("tabProperties").IsSelected = $true

	#close the expander if available
	Try {
		$dsWindow.FindName("expTermSearch").Visibility = "Collapsed"
		$dsWindow.FindName("expTermSearch").IsExpanded = $false
		$dsWindow.FindName("btnSearchTerm").IsDefault = $false
	}
	Catch { 
		$dsDiag.Trace("The expander TermCatalog is not present. Contact your VDS administrator.")
	}
}

#endregion CatalogLookUp

#region BreadCrumb TermClassSelection

function mAddTrmClsCmb ([String] $_CoName, $_Standard, $_classes) {	
	$children = mTerm_SearchClsEnts $_CoName $_Standard
	If ($null -eq $children) { return }
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
	$cmb.Margin = "0,0,0,1"
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
			mTerm_ClsCmbSelectionChanged($sender) #-sender $sender
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
			If ($_classes[0]) {
				#avoid activation of null ;)
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

function mAddTrmClsCmbChild ($data) {
	$children = @()
	$children = mTerm_GetClsUsesList($data) #-sender $data
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
			mTerm_ClsCmbSelectionChanged($sender) #-sender $sender
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
				If ($_classes[$_i - 1]) {
					#avoid activation of null ;)
					$_CurrentName = $_classes[$_i - 1] #remember the number of breadcrumb children is +1 (the class start with index 0)
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

function mTerm_SearchClsEnts ([String] $_CoName, [String] $_Standard) {
	try {
		$dsDiag.Trace(">> mTerm_SearchClsEnts started")		
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 2		
		$srchConds[0] = mTerm_CreateClsSrchCond "Category Name" $_CoName "AND" # note - for any reason, the "Category Name can't be replaced by a variable"
		$srchConds[1] = mTerm_CreateClsSrchCond $UIString["Adsk.QS.ClsStandard"] $_Standard "AND" # note - the classification standard condition is always applied as filter when a standard is selected in the UI; if no standard is selected, the condition value is empty and should not impact the search results

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
				$MsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("Could not find any " + $_CoName, "VDS Sample -- Classified Objects", "OK")
				break;
			}
		}
		#$dsDiag.Inspect("mResultAll")

		return $mResultAll
	}
	catch { 
		$dsDiag.Trace("!! Error in mTerm_SearchClsEnts")
	}
}

function mTerm_GetClsUsesList ($sender) {
	try {
		$dsDiag.Trace(">> mTerm_GetClsUsesList started")
		$mBreadCrumb = $dsWindow.FindName("wrpClassification")
		$_i = $mBreadCrumb.Children.Count - 1
		$_CurrentCmbName = "cmbBreadCrumb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClass = $mBreadCrumb.Children[$_i].SelectedValue.Name
		#[System.Windows.MessageBox]::Show("Currentclass: $_CurrentClass and Level# is $_i")
		switch ($_i) {
			0 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_01"] }
			1 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_02"] }
			2 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_03"] }
			3 { $mSearchFilter = $UIString["Adsk.QS.ClsLevel_04"] }
			4 { $mSearchFilter = $UIString["Adsk.QS.ClsObject"] }
			default { $mSearchFilter = "*" }
		}
		$_customObjects = mTerm_SearchClsEnts($mSearchFilter) #-_CoName $mSearchFilter
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
	catch { $dsDiag.Trace("!! Error in mAddTrmClsCmbChild !!") }
}

function mTerm_ClsCmbSelectionChanged ($mSender) {
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	[int]$position = $mSender.Name.Split('_')[1]

	# Only build breadcrumb maps for Vault Custom Object windows
	# CAD windows (Inventor/AutoCAD) don't use custom entity property mappings
	if ($dsWindow.Name -eq "CustomObjectClassifiedWindow") {
		try {
			# Check if mGetCustEntsPropNameValMaps function exists (Vault-specific)
			if (Get-Command mGetCustEntsPropNameValMaps -ErrorAction SilentlyContinue) {
				switch ($position) {
						0 { $Global:_BC1 = mGetCustEntsPropNameValMaps $mSender.ItemsSource }
						1 { $Global:_BC2 = mGetCustEntsPropNameValMaps $mSender.ItemsSource }
						2 { $Global:_BC3 = mGetCustEntsPropNameValMaps $mSender.ItemsSource }
						3 { $Global:_BC4 = mGetCustEntsPropNameValMaps $mSender.ItemsSource }
						Default {}
					}
			}
		}
		catch {
			$dsDiag.Trace("Warning: Could not build breadcrumb property maps (Vault-only feature)")
		}
	}
	
	$dsDiag.Trace("Selection changed at position $position, selected value = $($mSender.SelectedValue.Name)")					
	$children = $mBreadCrumb.Children.Count - 1
	while ($children -gt $position ) {
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children]);
		$children--;
	}
	
	Try {
		#fill properties
		if ($mBreadCrumb.Children[0]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_01"]].Value = $mBreadCrumb.Children[0].SelectedItem.Name			
			$_x1 = $_BC1[$mBreadCrumb.Children[0].SelectedItem.Num][$UIString["Adsk.QS.ClsLevelCode"]]
			if (($null -ne $_x1) -and ($_x1 -ne "")) {				
				$Prop[$UIString["Adsk.QS.ClsCode"]].Value = "$($_x1)"
			}
		}
		else {
			$Prop[$UIString["Adsk.QS.ClsCode"]].Value = $null
		}
		if ($mBreadCrumb.Children[1]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_02"]].Value = $mBreadCrumb.Children[1].SelectedItem.Name 
			$_x2 = $_BC2[$mBreadCrumb.Children[1].SelectedItem.Num][$UIString["Adsk.QS.ClsLevelCode"]]
			if ($null -ne $_x2 -and $_x2 -ne "") {
				$Prop[$UIString["Adsk.QS.ClsCode"]].Value = "$($_x1)_$($_x2)"
			}
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_02"]].Value = ""
		}
		if ($mBreadCrumb.Children[2]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_03"]].Value = $mBreadCrumb.Children[2].SelectedItem.Name 
			$_x3 = $_BC3[$mBreadCrumb.Children[2].SelectedItem.Num][$UIString["Adsk.QS.ClsLevelCode"]]
			if ($null -ne $_x3 -and $_x3 -ne "") {
				$Prop[$UIString["Adsk.QS.ClsCode"]].Value = "$($_x1)_$($_x2)_$($_x3)"
			}
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_03"]].Value = ""
		}
		if ($mBreadCrumb.Children[3]) { 
			$Prop[$UIString["Adsk.QS.ClsLevel_04"]].Value = $mBreadCrumb.Children[3].SelectedItem.Name 
			$_x4 = $_BC4[$mBreadCrumb.Children[3].SelectedItem.Num][$UIString["Adsk.QS.ClsLevelCode"]]
			if ($null -ne $_x4 -and $_x4 -ne "") {
				$Prop[$UIString["Adsk.QS.ClsCode"]].Value = "$($_x1)_$($_x2)_$($_x3)_$($_x4)"
			}
		}
		else { 
			$Prop[$UIString["Adsk.QS.ClsLevel_04"]].Value = ""
		}
		if ($mBreadCrumb.Children[4]) { 
			$Prop[$UIString["Adsk.QS.ClsObject"]].Value = $mBreadCrumb.Children[4].SelectedItem.Name 
			#$_x5 = $_BC4[$mBreadCrumb.Children[4].SelectedItem.Num][$UIString["Adsk.QS.ClsCode"]]
			$Prop[$UIString["Adsk.QS.ClsCode"]].Value = "$($_x1)_$($_x2)_$($_x3)_$($_x4)"
		}
		else { $Prop[$UIString["Adsk.QS.ClsObject"]].Value = "" }

		#write the highest level Custent Id to a text file for post-close event
		$value = $mBreadCrumb.Children[$children].SelectedItem.Id
		$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"
	}
	catch {}
	$dsDiag.Trace("---combo selection = $_selected, Position $position")

	#don't continue adding children according the classification group level
	switch ($Prop["_Category"].Value) {
		$UIString["Adsk.QS.ClsLevel_02"] {
			$dsDiag.Trace("Main group is the object's level; don't add a child. Position $($position)")
			return
		}
		
		$UIString["Adsk.QS.ClsLevel_03"] {
			if ($position -eq 1) {
				return
			}
			else {
				mAddTrmClsCmbChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}

		$UIString["Adsk.QS.ClsLevel_04"] {
			if ($position -eq 2) {
				return
			}
			else {
				mAddTrmClsCmbChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}

		$UIString["Adsk.QS.ClsObject"] {
			if ($position -eq 3) {
				return
			}
			else {
				mAddTrmClsCmbChild($sender.SelectedItem) #-sender $sender.SelectedItem
			}
		}

		default {
			mAddTrmClsCmbChild($sender.SelectedItem) #-sender $sender.SelectedItem
		}
	}	
}

function mResetTermClassFilter([Bool] $ShowWarning = $true) {
	$dsDiag.Trace(">> Reset Term Classification Filter started...")
	
	# Get the breadcrumb wrapper panel
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	
	if (-not $mBreadCrumb) {
		$dsDiag.Trace("Warning: wrpClassification breadcrumb not found")
		return
	}
	
	# Clear all existing ComboBoxes from the WrapPanel
	while ($mBreadCrumb.Children.Count -gt 0) {
		$cmb = $mBreadCrumb.Children[0]
		if ($cmb.Name) {
			$mBreadCrumb.UnregisterName($cmb.Name)
		}
		$mBreadCrumb.Children.RemoveAt(0)
	}
	
	mAddTrmClsCmb -_CoName $UIString["Adsk.QS.ClsLevel_01"] -_Standard $Global:mActiveStandard #enables classification filter for catalog of terms starting with segment

	
	$dsDiag.Trace("Breadcrumb reset complete. Children remaining: $($mBreadCrumb.Children.Count)")
	
	# Enable the classification standard combo box (user can select a new standard)
	if ($dsWindow.FindName("cmb_ClsStd")) {
		$dsWindow.FindName("cmb_ClsStd").IsEnabled = $true
		if ($UIString["Adsk.QS.ClsTT_01"]) {
			$dsWindow.FindName("cmb_ClsStd").Tooltip = $UIString["Adsk.QS.ClsTT_01"]
		}
		$dsDiag.Trace("Classification Standard combo enabled")
	}
	
	# Clear the search text box
	if ($dsWindow.FindName("mSearchTermText")) {
		$dsWindow.FindName("mSearchTermText").Text = ""
		$dsDiag.Trace("Search text cleared")
	}
	
	# Clear the search results DataGrid
	if ($dsWindow.FindName("dataGrdTermsFound")) {
		$dsWindow.FindName("dataGrdTermsFound").ItemsSource = $null
		$dsDiag.Trace("Search results DataGrid cleared")
	}

	# Clear the status message
	if ($dsWindow.FindName("txtTermStatusMsg")) {
		$dsWindow.FindName("txtTermStatusMsg").Text = ""
		$dsWindow.FindName("txtTermStatusMsg").Visibility = "Collapsed"
		$dsDiag.Trace("Status message cleared")
	}
	
	# Clear any cached breadcrumb level maps
	if ($Global:_BreadcrumbLevelMaps) {
		$Global:_BreadcrumbLevelMaps.Clear()
		$dsDiag.Trace("Breadcrumb level maps cleared")
	}
	
	# Reset classification level property values if they exist
	if ($Global:mClsLevelNames) {
		$Global:mClsLevelNames | ForEach-Object {
			try {
				if ($Prop[$_]) {
					$Prop[$_].Value = ""
				}
			}
			catch {
				$dsDiag.Trace("Could not reset property: $_")
			}
		}
		$dsDiag.Trace("Classification level properties cleared")
	}
	
	# Reset the ClsCode property
	if ($UIString["Adsk.QS.ClsCode"] -and $Prop[$UIString["Adsk.QS.ClsCode"]]) {
		$Prop[$UIString["Adsk.QS.ClsCode"]].Value = ""
		$dsDiag.Trace("ClsCode property cleared")
	}
	
	$dsDiag.Trace("...Reset Term Classification Filter finished <<")
}
#endregion BreadCrumb TermClassSelection