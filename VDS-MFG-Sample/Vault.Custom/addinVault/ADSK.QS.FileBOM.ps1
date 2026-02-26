class mBomRow {
	[int32] $Position
	[string] $PartNumber
	[string] $ComponentType
	[float] $Quantity
	[string] $Name
	[byte[]] $Thumbnail
	[string] $Title
	[string] $Description
	[string] $Material
}

class mBom {
	[mBomRow[]] $BOMItems	
}

# NEW in VDS-MFG-Sample and VDS-PDMC-Sample 2026.2.0: the functions mGetMdlStates and GetFileBOM moved to the VdsUtilities.VltHelpers classfor extended support and better debugging
# This script sample continues to demonstrates how to navigate from a BOM component in the file BOM to the corresponding file or item in Vault Explorer, and how to implement a search function to filter the BOM list.

function mGoToCadBomCompFile {
	$selectedBomRow = $dsWindow.FindName("bomList").SelectedItem
	[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Autodesk\Autodesk Vault 2026 SDK\bin\x64\Autodesk.Connectivity.Explorer.ExtensibilityTools.dll')
	[Autodesk.Connectivity.Explorer.ExtensibilityTools.IExplorerUtil]$mExplorerUtil = [Autodesk.Connectivity.Explorer.ExtensibilityTools.ExplorerLoader]::GetExplorerUtil($VaultApplication)
		
	#search a file to navigate to. Note the search returns the first file found; ensure that part number is unique in the vault
	$mFile = mSearchFileByPartNumber($selectedBomRow.PartNumber)
	
	# convert the file to an IEntity file object
	[Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration]$mFileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultconnection, $mFile)

	#navigate to the file in the vault explorer
	$mExplorerUtil.GoToEntity($mFileIteration)
}

function mGoToCadBomCompItem {
	$selectedBomRow = $dsWindow.FindName("bomList").SelectedItem
	[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Autodesk\Autodesk Vault 2026 SDK\bin\x64\Autodesk.Connectivity.Explorer.ExtensibilityTools.dll')
	[Autodesk.Connectivity.Explorer.ExtensibilityTools.IExplorerUtil]$mExplorerUtil = [Autodesk.Connectivity.Explorer.ExtensibilityTools.ExplorerLoader]::GetExplorerUtil($VaultApplication)
		
	#search a file to navigate to. Note the search returns the first file found; ensure that part number is unique in the vault
	$mFile = mSearchFileByPartNumber($selectedBomRow.PartNumber)
	
	#get the first linked item from the file
	$mItem = $vault.ItemService.GetItemsByFileId($mFile.Id)[0]

	if ($null -ne $mItem) {
		# convert the item to an IEntity file object
		[Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.ItemRevision]$mItemRevision = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.ItemRevision($vaultconnection, $mItem)
		
		#navigate to the item in the vault explorer
		$mExplorerUtil.GoToEntity($mItemRevision)
	}
}

function mSearchFileByPartNumber([String]$PartNumber) {
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propDef = $propDefs | Where-Object { $_.SysName -eq "PartNumber" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $PartNumber
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must

	$mSearchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$srchSort = New-Object Autodesk.Connectivity.WebServices.SrchSort
	#$srchSort
	$mBookmark = ""     
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.File]'

	while (($mSearchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $mSearchStatus.TotalHits)) {
		$mResultPage = $vault.DocumentService.FindFilesBySearchConditions(@($srchCond), @($srchSort), @(($vault.DocumentService.GetFolderRoot()).Id), $true, $true, [ref]$mBookmark, [ref]$mSearchStatus)
		#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
		If ($mSearchStatus.IndxStatus -eq "IndexingComplete" -or $mSearchStatus -eq "IndexingContent") {
		}
		if ($mResultPage.Count -ne 0) {
			$mResultAll.AddRange($mResultPage)
		}
		else { break; }
			
		break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
	}

	return $mResultAll[0]
}

# Function to handle the search button click event
function CadBomSearchButton_Click {
	# Get the search text from the TextBox
	$searchText = $dsWindow.FindName("txtCadBomSearch").Text

	# Call the FilterBOMList function to filter the BOM list based on the search text
	FilterBOMList -searchText $searchText

	 # enable the clear button if the search filtered the list
	$dsWindow.FindName("btnCadBomClear").IsEnabled = $true
	# disable the Find button to avoid changing the search text while filtering
	$dsWindow.FindName("btnCadBomFind").IsEnabled = $false
}

# Function to handle the clear button click event
function CadBomClearButton_Click {
	# Clear the search text in the TextBox
	$dsWindow.FindName("txtCadBomSearch").Text = ""

	#reset the bom list to its original state if the search text is empty
	$dsWindow.FindName("bomList").ItemsSource = $global:currentBOMList

	#disable the clear button and enable the Find button
	$dsWindow.FindName("btnCadBomFind").IsEnabled = $true
	$dsWindow.FindName("btnCadBomClear").IsEnabled = $false

}

# Function to filter the BOM list based on a search string
function FilterBOMList {
    param (
        [string]$searchText
    )

	# Escape the '*' character in the search text
    $escapedSearchText = [regex]::Escape($searchText)
	
	# avoid to update the unfiltered list with a filtered one
	if ($null -eq $global:currentBOMList) {
	    $global:currentBOMList = $dsWindow.FindName("bomList").ItemsSource
	}

	# Restrict the '*' character
	if ($searchText -match '\*') {
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("The '*' character is not allowed in the search.", "Invalid Input", "OK")
	}

    # Filter the BOM list by checking all properties of each mBomRow
	$global:filteredBOMList = New-Object mBom
    $global:filteredBOMList = $currentBOMList | Where-Object {
        $row = $_
        $row.PSObject.Properties.Value | ForEach-Object {
            if ($_ -match $escapedSearchText) {
				# If any property matches the search text, return true to include this row in the filtered list and enable the clear button
				$dsWindow.FindName("btnCadBomClear").IsEnabled = $true
                return $true
            }			
        }
			# If no properties matched, return false
			return $false
		}
	

	    # Ensure the result is enumerable
		if ($filteredBOMList.Count -eq 1) {
			$filteredBOMList = @($filteredBOMList)
		}

    # Update the ItemsSource of the BOM list with the filtered results
    $dsWindow.FindName("bomList").ItemsSource = $filteredBOMList
}