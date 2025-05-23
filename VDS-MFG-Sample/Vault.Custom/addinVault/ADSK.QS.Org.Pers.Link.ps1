# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


#initializes the dialog expander, filling combo box items and activating event handlers
function mExpOrgPersLnk
{
	$dsWindow.FindName("expOrgPersLnk").Visibility = "Visible"
	$dsWindow.FindName("expOrgPersLnk").IsExpanded = $true

	#close the expander as another property is selected 
	$dsWindow.FindName("DSDynCatPropGrid").add_GotFocus({
		$dsWindow.FindName("expOrgPersLnk").Visibility = "Collapsed"
	})

	#read custom objects to fill combobox items; do this only one time
	If(-not $dsWindow.FindName("cmbOrganisation").Items) 
		{
			$dsWindow.FindName("cmbOrganisation").ItemsSource = @(mSearchCustentOfCat $UIString["MSDCE_CO01"])
			
			#read linked contact per selected custom object
			If($Prop["_Category"].Value -ne $UIString["MSDCE_CO02"])
			{
				$dsWindow.FindName("cmbOrganisation").add_SelectionChanged({
					param($sender,$e)
					$dsWindow.FindName("cmbPerson").ItemsSource = @(mGetCustentLinkedOfCat -LinkParent $e.AddedItems[0] -CatName $UIString["MSDCE_CO02"])
					If($dsWindow.FindName("cmbPerson").Items.Count -gt 1) { $dsWindow.FindName("cmbPerson").IsDropDownOpen = $true}
					If($dsWindow.FindName("cmbPerson").Items.Count -eq 1) { $dsWindow.FindName("cmbPerson").SelectedIndex = 0}
					If($dsWindow.FindName("cmbPerson").Items) 
					{
						$dsWindow.FindName("cmbPerson").IsEnabled = $true
					}
					Else
					{
						$dsWindow.FindName("cmbPerson").IsEnabled = $false
					}
				})
			}
			
			#share the current selected object Ids for link creation on post close (=CreateFoder.ps1 ..if($result))
			$dsWindow.FindName("chkBoxCreateLnks").add_Checked({
				mOrgLinkActivate
			})
			#remove the current selected object Ids, as these trigger link creation on post close
			#$dsWindow.FindName("chkBoxCreateLnks").add_Unchecked({
			#	mOrgLinkReset
			#})

			#an usability add-on: avoid another click to open list on first usage
			if($dsWindow.FindName("cmbOrganisation").Items.Count -gt 1)
			{
				$dsWindow.FindName("cmbOrganisation").IsDropDownOpen = $true
			}
		}
	#another usability add-on: avoid selection of single list item setting pre-selection on it
	if($dsWindow.FindName("cmbOrganisation").Items.Count -eq 1)
	{
		$dsWindow.FindName("cmbOrganisation").SelectedIndex = 0
	}

}

#function to query linked custom objects, that match a specific category only
function mGetCustentLinkedOfCat($LinkParent, [String]$CatName)
{
	try 
	{
		$links = $vault.DocumentService.GetLinksByParentIds(@($LinkParent.Id),@("CUSTENT"))
		if($links)
		{
			$linkIds = @()
			$links | ForEach-Object { $linkIds += $_.ToEntId }
			$mLinkedCustObjects = @()
			$mLinkedCustObjects += $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds)
			$mCustentCats = $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
			$mCustentCat = $mCustentCats | Where-Object { $_.Name -eq $CatName}
			$mLinkedCustObjFilteredByCat = $mLinkedCustObjects | Where-Object { $_.Cat.CatID -eq $mCustentCat.Id}
			return $mLinkedCustObjFilteredByCat
		}
		Else { return $null}
	}
	catch [System.Exception]
	{		
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($error, "VDS Sample Configuration")
		return $null
	}
}

#save text file to hand over values for post-close actions; post close (.Menu\ command ) are a separate PS runspace, and using a text file is easiest way handing over values
function mSaveCustentId($filename, $value)
{
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\$($filename)"
}

#function to save current values to text value; the calling .\Menu\*.ps1 command has to read/consume the values for post-close action like link creation
function mOrgLinkActivate()
{		
	If ($dsWindow.FindName("cmbOrganisation").SelectedItem -ne -1)
	{
		mSaveCustentId -filename mOrganisationId.txt -value $dsWindow.FindName("cmbOrganisation").SelectedItem.Id
	}

	If ($dsWindow.FindName("cmbPerson").SelectedItem -ne -1)
	{
		mSaveCustentId -filename mPersonId.txt -value $dsWindow.FindName("cmbPerson").SelectedItem.Id
	}
}

#function to empty current values of text value; the calling .\Menu\*.ps1 command has to read/evaluate values for post-close action like link creation
function mOrgLinkReset()
{
	If ($dsWindow.FindName("cmbOrganisation").SelectedItem -ne -1)
	{
		mSaveCustentId -filename mOrganisationId.txt -value $null
	}

	If ($dsWindow.FindName("cmbPerson").SelectedItem -ne -1)
	{
		mSaveCustentId -filename mPersonId.txt -value $null
	}
}
