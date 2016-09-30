<#   
.SYNOPSIS   
Adds a list of Devices to a list of collections for Microsoft System Center Configuration Manager 2012R2
    
.DESCRIPTION 
This script uses the SCCM Module to connect to a SCCM server and add the specified devices to the specified collections
 
.PARAMETER Collections
List of SCCM Collections, with one Collection per line, or a Search Pattern Such as "MW:"

.PARAMETER Devices
List of SCCM Devices, with one Device per line, to be added to the collections, each Device will be added to each collection

.PARAMETER SiteCode
SCCM SiteCode

.NOTES   
Name: Add-SCCMDeviceToCollection.ps1
Author: Scott W Houghton
DateCreated: 2016-09-29
DateUpdated: 2016-09-29
Site: http://CloudDevOps.net
Version: 1.0.0

.LINK
http://CloudDevOps.net

.EXAMPLE
	.\Add-SCCMDeviceToCollection.ps1 -Collections MyCollection -Devices MyDevice -SiteCode MSC

Description
-----------
This command will add the Device MyDevice to the collection MyCollection to site MSC

.EXAMPLE
	.\Add-SCCMDeviceToCollection.ps1 -Collections MyCollection1, MyCollection2 -Devices MyDevice -SiteCode MSC

Description
-----------
This command will add the Device MyDevice to the collections MyCollection1 and MyCollection2 to site MSC

.EXAMPLE
	.\Add-SCCMDeviceToCollection.ps1 -Collections MyCollection1, MyCollection2 -SiteCode MSC

Description
-----------
This command will prompt for the Device to add to the collections MyCollection1 and MyCollection2 to site MSC

.EXAMPLE
	.\Add-SCCMDeviceToCollection.ps1 -Devices MyDevice -SiteCode MSC

Description
-----------
This command will prompt for the collections to add the Device MyDevice to to site MSC

.EXAMPLE
	.\Add-SCCMDeviceToCollection.ps1

Description
-----------
This command will prompt for a list of collections and Devices to add and promopt for the SiteCode

#>
#Requires -Version 5
param(
    [string[]]$Collections,
    [string[]]$Devices,
    [string]$SiteCode = "CAS:"
)
#Set Paths
$path = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
$scriptName =  $MyInvocation.MyCommand.Name
if(!(Test-Path "$path\Logs")){ New-Item "$path\Logs" -type directory }
if(!(Test-Path "$path\CSVs")){ New-Item "$path\CSVs" -type directory }
$dateTime = Get-Date -Format  yyyy-MM-dd_HHmm
$Logfile = "$path\Logs\$scriptName" + "-Log"+ $dateTime + ".txt"
$transcriptPath = "$path\Logs\$scriptName" + "Transcript"+ $dateTime + ".txt"

Start-Transcript -Path $transcriptPath
#Module Requires SCCM Client To Be Installed - Solves for 32bit OS
if([Environment]::Is64BitOperatingSystem){
    if((Test-Path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\")){
        import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
    }
    else{
        Write-Output "SCCM Module Not Installed"
        Pause
        Exit
    }
}
else{
    if((Test-Path "C:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\")){
        import-module "C:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
    }
    else{
        Write-Output "SCCM Module Not Installed"
        Pause
        Exit
    }
}
#Set SCCM Site Code
if($SiteCode -eq $null -or $SiteCode -eq "" -or $SiteCode -eq " "){
$SiteCode = (Show-TextBox -formText "SCCM Site Code Entry" -labelText "Enter SCCM Site Code:")
}
$SiteCode = $SiteCode.Trim(":")
$SiteCode = $SiteCode + ":"
Set-Location $SiteCode
Function Add-DeviceToCollection([string]$DeviceName,[string]$CollectionName){
	Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $CollectionName -ResourceId (get-cmdevice -Name $DeviceName).ResourceID
}

function Show-TextBox{
    param(
        [string]$formText = "Data Entry Form",
        [string]$labelText = "Please enter the information in the space below:"
    )
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = $formText
$objForm.Size = New-Object System.Drawing.Size(300,300) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,225)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,225)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = $labelText
$objForm.Controls.Add($objLabel) 

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Multiline = $True
$objTextBox.AcceptsReturn = $True
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,175) 
$objForm.Controls.Add($objTextBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
[String[]]$x
$x = $objTextBox.Text.Split("`r`n")
$x = $x.Trim(" ")
$x = $x.Trim()
$textList = @()
$x | %{if(![string]::IsNullOrEmpty($_) -and $_ -ne "" -and $_ -ne " " -and $_ -ne "`r`n"){ $textList += $_ }}
Return $textList
}
if($Collections -eq $null -or $Collections -eq "" -or $Collections -eq " "){$Collections = Show-TextBox -formText "Collection Entry" -labelText "Enter 1 Collection Per Line or Enter a Pattern, i.e.'MW:*':"}
if($Devices -eq $null -or $Devices -eq "" -or $Devices -eq " "){$Devices = Show-TextBox -formText "Device Entry" -labelText "Enter 1 Device Name Per Line:"}
foreach($Collection in $Collections){
if(![string]::IsNullOrEmpty($Collection) -and $Collection -ne "" -and $Collection -ne " " -and $Collection -ne "`r`n"){
[string]$CollectionSearchName = $Collection
$CollectionList = Get-CMDeviceCollection -Name "$CollectionSearchName" | Select Name
foreach($CollectionListItem in $CollectionList){
    [string]$CollectionName = $CollectionListItem.Name
if(![string]::IsNullOrEmpty($CollectionName) -and $CollectionName -ne "" -and $CollectionName -ne " " -and $CollectionName -ne "`r`n"){
    foreach($Device in $Devices){
        [string]$DeviceName = $Device
if(![string]::IsNullOrEmpty($DeviceName) -and $DeviceName -ne "" -and $DeviceName -ne " " -and $DeviceName -ne "`r`n"){
    Write-Output "Adding $DeviceName to $CollectionName"
    Add-DeviceToCollection -DeviceName $DeviceName -CollectionName $CollectionName
}
}
}
}
}
}
Stop-Transcript
pause