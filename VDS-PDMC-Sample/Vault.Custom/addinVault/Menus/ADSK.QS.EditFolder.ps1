
$vaultContext.ForceRefresh = $true
$folderId=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditFolderDialog($folderId)

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.Folder.xaml", "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.Folder.xaml"
$dialog.XamlFile = $xamlFile

$dialog.Execute()

