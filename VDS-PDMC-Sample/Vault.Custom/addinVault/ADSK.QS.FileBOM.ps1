class myBom
{
	[string] $Position
	[string] $PartNumber
	[string] $ComponentType
	[float] $Quantity
	[string] $Name
	[byte[]] $Thumbnail
	[string] $Title
	[string] $Description
	[string] $Material
}

function GetFileBOM($fileID)
{
	#Get Thumbnail PropertyDefinition 
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId('FILE')
	$thumbnailPropDef = $propDefs | Where-Object {$_.SysName -eq 'Thumbnail'}

	$bom = $vault.DocumentService.GetBOMByFileId($fileID)
	$cldIds =@()
	$bom.InstArray | Where-Object { $_.ParId -eq 0 } | ForEach-Object { 
		$CldId = $_.CldId
		$comp = $bom.CompArray | Where-Object { $_.Id -eq $CldId }
		if ($comp.XRefId -ne -1) {
			$cldIds += $comp.XRefId
		}
	}

	$bomItems = @()
	if($cldIds.Count -gt 0) #the file contains BOM information, so continue
	{
		$CldBoms = $vault.DocumentService.GetBOMByFileIds($cldIds)
		$schm = $bom.SchmArray | Where-Object { $_.SchmTyp -eq "Structured" -and $_.RootCompId -eq 0}
		$cldBomCounter = 0

		$bom.InstArray | Where-Object { $_.ParId -eq 0 } | ForEach-Object {
			$bomItem = New-Object myBom
			$CldId = $_.CldId
			if ($_.QuantOverde -eq -1)
			{
				$bomItem.Quantity = $_.Quant
			}
			else {
				$bomItem.Quantity = $_.QuantOverde
			}
			$comp = $bom.CompArray | Where-Object { $_.Id -eq $CldId }

			$occur = $bom.SchmOccArray | Where-Object { $_.SchmId -eq $schm.Id -and $_.CompId -eq $CldId }
			$bomItem.Position = $occur.DtlId

			if ($comp.XRefId -eq -1) {
				$cldBom = $bom
			}
			else {
				$cldBom = $CldBoms[$cldBomCounter++]
			}
			$UniqueId = $comp.UniqueId
			#find component in current file bom only
			$cldComp = $cldBom.CompArray | Where-Object { $_.UniqueId -eq $UniqueId -and $_.XRefId -eq -1} | Select-Object -First 1
			if(-not $cldComp){
				$cldComp = $cldBom.CompArray[0]
			}
			$bomItem.Name = $cldComp.Name
			$bomItem.ComponentType = $cldComp.CompTyp
			$cldCompAttrArray = $cldBom.CompAttrArray | Where-Object { $_.CompId -eq $cldComp.Id}
			if($cldCompAttrArray.Count -eq 0){
				$cldCompAttrArray = $cldBom.CompAttrArray
			}
			$PropPartNumber = $cldBom.PropArray | Where-Object { $_.dispName -eq "Part Number"}
			$prop = ($cldCompAttrArray | Where-Object { $_.PropId -eq $PropPartNumber.Id}) | Select-Object -First 1
			$bomItem.PartNumber = $prop.Val
			$bomItems += $bomItem

			#add Inventor default BOM columns
			$thumbnailProp = $vault.PropertyService.GetProperties('FILE', @($cldIds[$cldBomCounter - 1]), @($thumbnailPropDef.Id))[0]
			$bomItem.Thumbnail = $thumbnailProp.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Title"}
			$prop = $cldCompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id} | Select-Object -First 1
			$bomItem.Title = $prop.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Description"}
			$prop = $cldCompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id} | Select-Object -First 1
			$bomItem.Description = $prop.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Material"}
			$prop = $cldCompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id} | Select-Object -First 1
			$bomItem.Material = $prop.Val
			#add the name for navigation
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Name"}
			$prop = $cldCompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id} | Select-Object -First 1
			$bomItem.Name = $prop.Val
		}
	}
	return $bomItems	
}

function mGoToCadBomCompFile
{
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

function mGoToCadBomCompItem
{
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

function mSearchFileByPartNumber([String]$PartNumber)
{
	$mSearchString = $selectedBomRow.PartNumber
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propDef = $propDefs | Where-Object { $_.SysName -eq "PartNumber" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $mSearchString
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