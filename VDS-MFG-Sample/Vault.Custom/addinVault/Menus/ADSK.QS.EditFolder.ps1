# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


$vaultContext.ForceRefresh = $true
$folderId=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditFolderDialog($folderId)

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.Folder.xaml", "C:\ProgramData\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.Folder.xaml"
$dialog.XamlFile = $xamlFile

$dialog.Execute()

