#$vaultContext.ForceRefresh = $true
$selectionSet = $vaultContext.CurrentSelectionSet[0]
$id= $selectionSet.Id
$dialog = $dsCommands.GetCreateCustomObjectDialog($id)

$xamlFile = New-Object CreateObject.WPF.XamlFile "CustomEntityXaml", "%ProgramData%\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObjectClassified.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if ($result)
{
	#region create_links
	try
	{
		$parentID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"
		$childID = $dialog.CurrentEntity.Id
		if($parentID -ne $null) { $link = $vault.DocumentService.AddLink($parentID,"CUSTENT",$childID,"Parent->Child") }
	}
	catch
	{
		#$dsDiag.Trace("CreateCustomObjectClassified.ps1 - AddLink command failed") 
	}
	#endregion

	$entityNumber = $dialog.CurrentEntity.Num
	$entityGuid = $selectionSet.TypeId.EntityClassSubType
	$selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId $entityGuid
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $entityNumber
	$vaultContext.GoToLocation = $location
}

#in case cancel / close Window (Window button X), remove last entries as well...
$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mParentId.txt"
