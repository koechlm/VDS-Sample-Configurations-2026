# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


function mGoToUsesFile() {
	$selectedTreeItem = $dsWindow.FindName("Uses").SelectedItem.Name
	if ($null -ne $selectedTreeItem) {
		mGoToTreeViewFile $selectedTreeItem
	}
}

function mGoToUsesItem() {
	$selectedTreeItem = $dsWindow.FindName("Uses").SelectedItem.Name
	if ($null -ne $selectedTreeItem) {
		mGoToTreeViewItem $selectedTreeItem
	}
}

function mGoToWhereUsedFile() {
	$selectedTreeItem = $dsWindow.FindName("WhereUsed").SelectedItem.Name
	if ($null -ne $selectedTreeItem) {
		mGoToTreeViewFile $selectedTreeItem
	}
}

function mGoToWhereUsedItem() {
	$selectedTreeItem = $dsWindow.FindName("WhereUsed").SelectedItem.Name
	if ($null -ne $selectedTreeItem) {
		mGoToTreeViewItem $selectedTreeItem
	}
}

function mGoToTreeViewFile($TreeItemName) {
	if ($null -eq $mExplorerUtil) {
		[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Autodesk\Autodesk Vault 2026 SDK\bin\x64\Autodesk.Connectivity.Explorer.ExtensibilityTools.dll')
		[Autodesk.Connectivity.Explorer.ExtensibilityTools.IExplorerUtil]$global:mExplorerUtil = [Autodesk.Connectivity.Explorer.ExtensibilityTools.ExplorerLoader]::GetExplorerUtil($VaultApplication)
	}
	
	#search a file to navigate to. Note the search returns the first file found; ensure that part number is unique in the vault
	$mFile = mSearchFileByFileName($TreeItemName)
	
	# convert the file to an IEntity file object
	[Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration]$mFileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultconnection, $mFile)

	#navigate to the file in the vault explorer
	$mExplorerUtil.GoToEntity($mFileIteration)	
}

function mGoToTreeViewItem($TreeItemName) {		
	if ($null -eq $mExplorerUtil) {
		[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Autodesk\Autodesk Vault 2026 SDK\bin\x64\Autodesk.Connectivity.Explorer.ExtensibilityTools.dll')
		[Autodesk.Connectivity.Explorer.ExtensibilityTools.IExplorerUtil]$global:mExplorerUtil = [Autodesk.Connectivity.Explorer.ExtensibilityTools.ExplorerLoader]::GetExplorerUtil($VaultApplication)
	}			
	#search a file to navigate to. Note the search returns the first file found; ensure that part number is unique in the vault
	$mFile = mSearchFileByFileName($TreeItemName)
		
	#get the first linked item from the file
	$mItem = $vault.ItemService.GetItemsByFileId($mFile.Id)[0]
	
	if ($null -ne $mItem) {
		# convert the item to an IEntity file object
		[Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.ItemRevision]$mItemRevision = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.ItemRevision($vaultconnection, $mItem)
			
		#navigate to the item in the vault explorer
		$mExplorerUtil.GoToEntity($mItemRevision)
	}
}

function mSearchFileByFileName([String]$Name) {
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propDef = $propDefs | Where-Object { $_.SysName -eq "Name" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $Name
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