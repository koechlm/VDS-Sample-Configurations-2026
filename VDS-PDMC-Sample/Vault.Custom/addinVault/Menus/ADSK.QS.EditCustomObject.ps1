$vaultContext.ForceRefresh = $true
$id = $vaultContext.CurrentSelectionSet[0].Id

$dialog = $dsCommands.GetEditCustomObjectDialog($id) #loads the default. 

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.CustomObject.xaml", "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObject.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if ($result) {
	$custent = $dialog.CurrentEntity
	$cat = $vault.CategoryService.GetCategoryById($custent.Cat.CatId)
	switch ($cat.Name) {
		"Person" {
			#update the custom object name if one of the properties changed
			$mN1 = mGetCustentPropValue $custent.Id "First Name"
			$mN2 = mGetCustentPropValue $custent.Id "Last Name"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, "$($mN1) $($mN2)")
		}
		"Task" {
			$ParentId = $dialog.CurrentEntity.Id
			$ChildId = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mPersonId.txt"
			[Autodesk.Connectivity.Webservices.Lnk()]$existingChldLnks = @()
			$existingChldLnks = $vault.DocumentService.GetLinksByParentIds(@($ParentId), "CUSTENT")
			if ($null -ne $ChildId) {
				#filter to Task->Person links, a single link of this type is allowed (Person = task owner)
				$existingChldIds = @()
				$existingChldLnks | ForEach-Object { $existingChldIds += $_.ToEntId }
				$existingChldCustents = $vault.CustomEntityService.GetCustomEntitiesByIds($existingChldIds)
				$PersonCatId = ($vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true) | Where-Object { $_.Name -eq "Person" }).Id
				$existingChldPersons = @($existingChldCustents | Where-Object { $_.Cat.CatId -eq $PersonCatId })
				if ($existingChldPersons.Count -gt 0) {
					#delete the existing links to all Person objects
					$existingPersonIds = @()
					$existingChldPersons | ForEach-Object { $existingPersonIds += $_.Id }
					$LnksToDelete = $existingChldLnks | Where-Object { $existingPersonIds -contains $_.ToEntId }
					$LnkIdsToDelete = @()
					$LnksToDelete | ForEach-Object { $LnkIdsToDelete += $_.Id }
					if ($LnksToDelete.Count -gt 1) {
						$result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning("A task must not have more than one link to a 'Person'; Continue with OK to update the task with a single link to the task's owner. Abort with Cancel to correct the links manually.", "VDS PDMC-Sample ECO-Tasks", "OKCancel")
						if ($result -eq "OK") {
							$vault.DocumentService.DeleteLinks($LnkIdsToDelete)
						}						
					}
					elseif ($LnksToDelete.Count -eq 1) {
						$vault.DocumentService.DeleteLinks($LnkIdsToDelete)
					}
				}
				#create a new link
				$link = $vault.DocumentService.AddLink($ParentId, "CUSTENT", $ChildId, "Parent->Child")
				if ($null -eq $link) {
					$result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("Failed to update the task with a link to the owner (Person object)", "VDS PDMC-Sample ECO-Tasks")
				}				
			}			
		}
	}
	
}

#reset the selection, as it would persist sessions
$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mECOTabClick.txt"
$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mPersonId.txt"