# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


$folderId=$vaultContext.CurrentSelectionSet[0].Id
$vaultContext.ForceRefresh = $true
$dialog = $dsCommands.GetCreateFolderDialog($folderId)

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.Folder.xaml", "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.Folder.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if($result)
{
	#new folder can be found in $dialog.CurrentFolder
	$folder = $vault.DocumentService.GetFolderById($folderId)
	$path=$folder.FullName+"/"+$dialog.CurrentFolder.Name
	
	#recursively add subfolders to new folders that are not base category folders
	$UIString = mGetUIStrings
	$NewFolder = $vault.DocumentService.GetFolderByPath($path)
	if($NewFolder.Cat.Catname -ne $UIString["CAT5"])
	{
		#the new folder is the targetfolder to create subfolders, the source folder is the template to be used
		$TempFolderName = "$/Templates/Folders/" + $NewFolder.Cat.Catname
		$tempFolder = $vault.DocumentService.GetFolderByPath($TempFolderName)
		
		#copy Access Control List if user's permission include ACLRead, ACLWrite
		$UserPermissions = mGetCUsPermissions
		$mValidPermis = $false

		if($UserPermissions -contains 102 -and $UserPermissions -contains 103) # 102: ACL Read, 103: ACL Write permission
		{
			$mValidPermis = $true
			$mCopiedACL = mCopyEntACL -SourceEnt  $tempFolder -TargetEnt  $NewFolder
		}

		If($tempFolder){ mRecursivelyCreateFolders -targetFolder $NewFolder -sourceFolder $tempFolder -inclACL $mValidPermis }
	}

	#region create_links
	try
	{
		$companyID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mOrganisationId.txt"
		$contactID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2026\mPersonId.txt"
		if($companyID -ne $null) { $link2 = $vault.DocumentService.AddLink($dialog.CurrentFolder.Id,"CUSTENT",$companyID,"Folder->Organisation") }
		if($contactID -ne $null) { $link3 = $vault.DocumentService.AddLink($dialog.CurrentFolder.Id,"CUSTENT",$contactID,"Folder->Person") }
	}
	catch
	{
		$dsDiag.Trace("CreateFolder.ps1 - AddLink command failed") 
	}
	finally {
		#in any case don't use the last entry twice...
		$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mOrganisationId.txt"
		$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\mPersonId.txt"
	}
	#endregion

	$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::Folder
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
	$vaultContext.GoToLocation = $location
}