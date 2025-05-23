$vaultContext.ForceRefresh = $true
$id=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditCustomObjectDialog($id)

$xamlFile = New-Object CreateObject.WPF.XamlFile "CustomEntityXaml", "%ProgramData%\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObjectClassified.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if($result)
{
	$custent = $vault.CustomEntityService.GetCustomEntitiesByIds(@($id))[0]
	$parentID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"
	$cat = $vault.CategoryService.GetCategoryById($custent.Cat.CatId)
	
	#update the object's name and properties if needed
	switch($cat.Name)
	{
		"Term"
		{
			$mN = mGetCustentPropValue $custent.Id "Term EN"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, $mN)
		}
		"Class"
		{
			$mN = mGetCustentPropValue $custent.Id "Class"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, $mN)
		}
	}	
	
	#region update links
	$childID = $dialog.CurrentEntity.Id
	[System.Collections.ArrayList]$existingTargetLnks = @()
	$existingTargetLnks = $vault.DocumentService.GetLinksByTargetEntityIds(@($childID))

	if($existingTargetLnks.Count -gt 1)
	{
		[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("A classified object must not have more than a single parent; correct your links manually and repeat the edit.", "VDS PDMC-Sample Classification")
	}
	elseif($existingTargetLnks.Count -eq 1)
	{
		$currentLnk = $existingTargetLnks[0]
		if($existingTargetLnks[0].ParentId -ne $parentID -and $parentID -ne $null)
		{
			#delete the old one
			$vault.DocumentService.DeleteLinks(@($currentLnk.Id))
			#create a new link
			$link = $vault.DocumentService.AddLink($parentID,"CUSTENT", $childID, "Parent->Child")
		}
	}
	elseif($existingTargetLnks.Count -eq 0 -and $parentID -ne $null )
	{
		#create a new link
		$link = $vault.DocumentService.AddLink($parentID,"CUSTENT", $childID, "Parent->Child")
	}

	#endregion update links

	#in case cancel / close Window (Window button X), remove last entries as well...
	$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"

}