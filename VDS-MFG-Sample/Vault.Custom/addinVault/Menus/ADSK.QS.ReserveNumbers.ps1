# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


$_Temp = $dsCommands
#$dsDiag.Inspect()
$dialog = $dsCommands.GetCreateFolderDialog(1)
$xamlFile = New-Object CreateObject.WPF.XamlFile "Reservexaml", "%ProgramData%\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.ReserveNumbers.xaml"
$dialog.XamlFile = $xamlFile


$result = $dialog.Execute()
#$dsDiag.Trace($result)
