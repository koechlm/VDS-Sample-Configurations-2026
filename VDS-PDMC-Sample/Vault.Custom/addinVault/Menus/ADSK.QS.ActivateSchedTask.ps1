#=============================================================================
# PowerShell script sample for Vault Data Standard                            
# Reserve a range of File Numbers from Autodesk Vault                         
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#=============================================================================
$_Temp = $dsCommands

# query that the logged in user is allowed to apply this command
$mUserEnabled = Adsk.CheckCfgAdminPermission

If($mUserEnabled -eq $false)
{
	#read UIStrings as these are not a default in the .\Menu\*.ps1 functions runspace
	$UIStrings = mGetUIStrings
	[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($UIStrings["ADSK-GroupMemberOf-00"], $UIStrings["ADSK-MsgBoxTitle"])
	return
}

$dialog = $dsCommands.GetCreateFolderDialog(1)
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.ActivateSchedTask.xaml", "%ProgramData%\Autodesk\Vault 2026\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.ActivateSchedTask.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()


