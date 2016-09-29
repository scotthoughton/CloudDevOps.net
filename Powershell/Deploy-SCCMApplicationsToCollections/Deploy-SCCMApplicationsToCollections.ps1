<#   
.SYNOPSIS   
Deploys a list of applications to a list of collections for Microsoft System Center Configuration Manager 2012R2
    
.DESCRIPTION 
This script uses the SCCM Module to connect to a SCCM server 
 
.PARAMETER Collections
List of SCCM Collections, with one Collection per line, or a Search Pattern Such as "MW:"

.PARAMETER Applications
List of SCCM Applications, with one application per line, to be deployed to the collections, each application will be deployed to each collection

.PARAMETER SiteCode
SCCM SiteCode

.NOTES   
Name: Deploy-SCCMApplicationsToCollections.ps1
Author: Scott W Houghton
DateCreated: 2016-09-29
DateUpdated: 2016-09-29
Site: http://CloudDevOps.net
Version: 1.0.0

.LINK
http://CloudDevOps.net

.EXAMPLE
	.\Deploy-SCCMApplicationsToCollections.ps1 -Collections MyCollection -Applications MyApplication -SiteCode MSC

Description
-----------
This command will deploy the application MyApplication to the collection MyCollection to site MSC

.EXAMPLE
	.\Deploy-SCCMApplicationsToCollections.ps1 -Collections MyCollection1, MyCollection2 -Applications MyApplication -SiteCode MSC

Description
-----------
This command will deploy the application MyApplication to the collections MyCollection1 and MyCollection2 to site MSC

.EXAMPLE
	.\Deploy-SCCMApplicationsToCollections.ps1 -Collections MyCollection1, MyCollection2 -SiteCode MSC

Description
-----------
This command will prompt for the application to deploy to the collections MyCollection1 and MyCollection2 to site MSC

.EXAMPLE
	.\Deploy-SCCMApplicationsToCollections.ps1 -Applications MyApplication -SiteCode MSC

Description
-----------
This command will prompt for the collections to deploy the application MyApplication to to site MSC

.EXAMPLE
	.\Deploy-SCCMApplicationsToCollections.ps1

Description
-----------
This command will promt for a list of collections and applications to deploy and promopt for the SiteCode

#>
#Requires -Modules "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

param(
    [string[]]$Collections,
    [string[]]$Applications,
    [string]$SiteCode
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
#Module Requires SCCM Client To Be Installed
import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
#Set SCCM Site Code
if($SiteCode -eq $null -or $SiteCode -eq "" -or $SiteCode -eq " "){
$SiteCode = (Show-TextBox -formText "SCCM Site Code Entry" -labelText "Enter SCCM Site Code:")
}
Set-Location $SiteCode
Function Start-Deploy([string]$ApplicationName,[string]$CollectionName){
Start-CMApplicationDeployment -CollectionName "$CollectionName" -Name "$ApplicationName" `
-DeployAction "Install" -DeployPurpose "Require" -UserNotification "DisplaySoftwareCenterOnly" `
-PreDeploy $True -RebootOutsideServiceWindow $false -SendWakeUpPacket $false -UseMeteredNetwork $false
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
if($Collections -eq $null -or $Collections -eq "" -or $Collections -eq " "){$Collections = Show-TextBox -formText "Collection Entry" -labelText "Enter One Collection Name Per Line or Enter a Search Pattern Such as 'MW:*':"}
if($Applications -eq $null -or $Applications -eq "" -or $Applications -eq " "){$Applications = Show-TextBox -formText "Application Entry" -labelText "Enter One Application Name Per Line:"}
foreach($Collection in $Collections){
if(![string]::IsNullOrEmpty($Collection) -and $Collection -ne "" -and $Collection -ne " " -and $Collection -ne "`r`n"){
[string]$CollectionSearchName = $Collection
$CollectionList = Get-CMDeviceCollection -Name "$CollectionSearchName" | Select Name
foreach($CollectionListItem in $CollectionList){
    [string]$CollectionName = $CollectionListItem.Name
if(![string]::IsNullOrEmpty($CollectionName) -and $CollectionName -ne "" -and $CollectionName -ne " " -and $CollectionName -ne "`r`n"){
    foreach($Application in $Applications){
        [string]$ApplicationName = $Application
if(![string]::IsNullOrEmpty($ApplicationName) -and $ApplicationName -ne "" -and $ApplicationName -ne " " -and $ApplicationName -ne "`r`n"){
    Write-Output "Deploying $ApplicationName to $CollectionName"
    Start-Deploy -ApplicationName $ApplicationName -CollectionName $CollectionName
}
}
}
}
}
}
Stop-Transcript
pause