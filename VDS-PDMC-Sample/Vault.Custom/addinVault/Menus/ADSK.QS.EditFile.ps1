
$vaultContext.ForceRefresh = $true
$fileId=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditDialog($fileId)

#differentiation of Office moved to PowerShell, GetTemplateFolders in *Default.ps1
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.File.xaml", "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.File.xaml"
$dialog.XamlFile = $xamlFile

#updated file can be found in $dialog.CurrentFile
$result = $dialog.Execute()

if ($result)
{
	##region update links
	#$parentID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mFileClassId.txt"
	#$childID = ($vault.DocumentService.GetLatestFileByMasterId($dialog.CurrentFile.MasterId)).Id

	#[System.Collections.ArrayList]$existingTargetLnks = @()
	#$existingTargetLnks = $vault.DocumentService.GetLinksByTargetEntityIds(@($childID))

	##filter target links by "class" objects only
	#[System.Collections.ArrayList]$existingCustentLnks = @()
	#[System.Collections.ArrayList]$existingCustents = @()
	#[System.Collections.ArrayList]$existingCustentIDs = @()
	#[System.Collections.ArrayList]$existingClassLnks = @()
	
	#$ClassCat = $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true) | Where-Object{ $_.Name -eq "Class" }

	#$existingCustentLnks += $existingTargetLnks | Where-Object { $_.ParEntClsId -eq "CUSTENT"}
	#$existingCustentLnks | ForEach-Object { 	$existingCustentIDs += $_.ParentId	}
	#$existingCustents = $vault.CustomEntityService.GetCustomEntitiesByIds($existingCustentIDs)

	#foreach ($lnk in $existingCustentLnks)
	#{
	#	$custent = $existingCustents | Where-Object { $_.Id -eq $lnk.ParentId	}
	#	if($custent.Cat.CatId -eq $ClassCat.Id)
	#	{
	#		$existingClassLnks += $lnk
	#	}
	#}

	##manage the file's classification links
	#if($existingClassLnks.Count -gt 1)
	#{
	#	[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("A classified object must not have more than a single parent; correct your links manually and repeat the edit.", "VDS PDMC-Sample Classification")
	#}
	#elseif($existingClassLnks.Count -eq 1)
	#{
	#	$currentLnk = $existingClassLnks[0]
	#	if($existingClassLnks[0].ParentId -ne $parentID -and ($parentID -ne $null -or $parentID -ne "-1"))
	#	{
	#		#delete the old one
	#		$vault.DocumentService.DeleteLinks(@($currentLnk.Id))
	#		#create a new link
	#		$link = $vault.DocumentService.AddLink($parentID,"FILE", $childID, "Parent->Child")
	#	}
		
	#	#remove the link, if $parentID is -1 (result of remove class function)
	#	if($parentID -eq "-1")
	#	{
		
	#		$vault.DocumentService.DeleteLinks(@($currentLnk.Id))
	#	}
	#}
	#elseif($existingClassLnks.Count -eq 0)
	#{
	#	#create a new link
	#	$link = $vault.DocumentService.AddLink($parentID,"FILE", $childID, "Parent->Child")
	#}

	##in case cancel / close Window (Window button X), remove last entries as well...
	$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mFileClassId.txt"

	##endregion
}

