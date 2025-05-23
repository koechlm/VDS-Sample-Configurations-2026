# DISCLAIMER:
# ---------------------------------
# In any case, code, templates, and snippets of this solution are of "work in progress" character.
# Neither Markus Koechl, nor Autodesk represents that these samples are reliable, accurate, complete, or otherwise valid. 
# Accordingly, those configuration samples are provided as is with no warranty of any kind, and you use the applications at your own risk.


class mAssocCustent
{
	 [string] $id
	 [string] $icon
	 [string] $name
	 [string] $title
	 [string] $description
	 [string] $owner
	 [string] $datestart
	 [string] $state
	 [string] $priority
	 [string] $dateend
	 [string] $comments
}


function mGetAssocCustents($mIds)
{
	#$dsDiag.Trace(">> Starting mGetAssocCustents($mIds)")
	$mCustEntities = $vault.CustomEntityService.GetCustomEntitiesByIds($mIds)
	If(-not $Global:CustentPropDefs) { $Global:CustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")}
	$PropDefs = $Global:CustentPropDefs
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}
	$mAssocCustents = @()
	
	$mAllCustEntProps = $vault.PropertyService.GetProperties("CUSTENT",$mIds,$propDefIds)
	
	Foreach($mCustEnt in $mCustEntities)
	{ 
		$mAssocCustEnt = New-Object mAssocCustent

		$mCustEntProps = $mAllCustEntProps | Where-Object {$_.EntityId -eq $mCustEnt.Id}
		#set id
		$mAssocCustent.id = $mCustEnt.Id

		#set custom icon
		$iconLocation = $([System.IO.FileInfo]::new($VaultContext.UserControl.XamlFile).DirectoryName)
		$mIconpath = [System.IO.Path]::Combine($iconLocation,"Icons\task.ico")
		$exists = Test-Path $mIconPath
		$mAssocCustEnt.icon = $mIconPath
		
		#set system properties name, title, description, state
		$mAssocCustEnt.name = $mCustEnt.Name
		$mtitledef = $PropDefs | Where-Object { $_.SysName -eq "Title"}
		$mtitleprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mtitledef.Id}
		$mAssocCustEnt.title = $mtitleprop.Val
		$mdescriptiondef = $PropDefs | Where-Object { $_.SysName -eq "Description"}
		$mdescriptionprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mdescriptiondef.Id}
		$mAssocCustEnt.description = $mdescriptionprop.Val
		$mdescriptiondef = $PropDefs | Where-Object { $_.SysName -eq "State"}
		$mdescriptionprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mdescriptiondef.Id}
		$mAssocCustEnt.state = $mdescriptionprop.Val
		
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-02"]} #date start
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.datestart = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-03"]} #date end
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.dateend = $mUdpProp.Val
		#set user def properties 
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-04"]} #owner
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.owner = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-05"]} #priority
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.priority = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["LBL7"]} #comments
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.comments = $mUdpProp.Val

		#add the filled entity
		$mAssocCustents += $mAssocCustEnt
	}

	return $mAssocCustents

}

function mTaskClick()
{
	$mSelectedItem = $dsWindow.FindName("dataGrdLinks").SelectedItem
    $mOutFile = "mECOTabClick.txt"
	$mSelectedItem.Id | Out-File "$($env:appdata)\Autodesk\DataStandard 2026\$($mOutFile)"
}

function mGetEcoTasks([String]$m)
{
		$mSearchString = "Task"
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$propDef = $propDefs | Where-Object { $_.DispName -eq "Category Name" }
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3
		$srchCond.SrchTxt = $mSearchString
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""     
		$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'
	
		while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
		{
			 $mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions(@($srchCond),@($srchSort),[ref]$bookmark,[ref]$searchStatus)
			
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
			{
				#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
			}
			if($mResultPage.Count -ne 0)
			{
				$mResultAll.AddRange($mResultPage)
			}
			else { break;}
				
			break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
		}
}
