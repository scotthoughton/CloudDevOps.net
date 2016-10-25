#Requires -version 3
<#   
.SYNOPSIS   
Script that trigger the SCCM Client commands on remote machines via WMI
    
.DESCRIPTION 
This script uses WMI to trigger SCCM client commands to update the following client policies:
     Hardware Inventory Cycle
     Discovery Data Collection Cycle
     File Collection Cycle
     Software Inventory Cycle	
     Software Update Scan Cycle
     Application Deployment Evaluation Cycle
     File Collection Cycle
     Software Metering Usage Report Cycle
     Machine Policy Retrieval Cycle
     Machine Policy Evaluation Cycle	
     User Policy Retrieval Cycle
     User Policy Evaluation Cycle	
     State Message Refresh	
     Windows Installers Source List Update Cycle
 
.PARAMETER Computers
The computer that will be queried by this script
.NOTES   
Name: Trigger-SCCMClientUpdate.ps1
Author: Scott W Houghton
DateCreated: 2016-10-19
DateUpdated: 2016-10-25
Site: http://CloudDevOps.net
Version: 1.5.0
.LINK
http://CloudDevOps.net
.EXAMPLE
	.\Trigger-SCCMClientUpdate.ps1 -Computers server01
Description
-----------
This command will use WMI to connect to server01 and triggers SCCM commands
.EXAMPLE
	.\Trigger-SCCMClientUpdate.ps1 -Computers server01,server02,server03
Description
-----------
This command will use WMI to connect to server01,server02,server03 triggers SCCM commands
.EXAMPLE
	.\Trigger-SCCMClientUpdate.ps1 -Computers $env:COMPUTERNAME
Description
-----------
This command will use WMI to connect to localhost and triggers SCCM commands
#>
param(
    [String[]]$Computers
)
#Set Paths
$path = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
$scriptName =  $MyInvocation.MyCommand.Name
if(!(Test-Path "$path\Logs")){ New-Item "$path\Logs" -type directory }
if(!(Test-Path "$path\CSVs")){ New-Item "$path\CSVs" -type directory }
$dateTime = Get-Date -Format  yyyy-MM-dd_HHmm
$Logfile = "$path\Logs\$scriptName" + "-Log"+ $dateTime + ".txt"
$transcriptPath = "$path\Logs\$scriptName" + "Transcript"+ $dateTime + ".txt"

function Show-TextBox{
#Version 2.1
    param(
        [string]$formText = "Data Entry Form",
        [string]$labelText = "Please enter the information in the space below:",
        [bool]$multiLineText = $true
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
$objTextBox.Multiline = $multiLineText
$objTextBox.AcceptsReturn = $True
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,175) 
$objForm.Controls.Add($objTextBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
if($multiLineText){
[String[]]$x = ""
$x = $objTextBox.Text.Split("`r`n")
$x = $x.Trim(" ")
$x = $x.Trim()
$textList = @()
$x | %{if(![string]::IsNullOrEmpty($_) -and $_ -ne "" -and $_ -ne " " -and $_ -ne "`r`n"){ $textList += $_ }}
Return $textList
}
else{
    Return $objTextBox.Text
}
}

Start-Transcript -Path $transcriptPath

if($Computers -eq $null -or $Computers -eq "" -or $Computers -eq " "){$Computers = Show-TextBox -formText "Computer Entry" -labelText "Enter One Computer Name Per Line"}
foreach($Computer in $Computers){
[string]$server = $Computer
if(![string]::IsNullOrEmpty($server) -and $server -ne "" -and $server -ne " " -and $server -ne "`r`n"){
    Write-Output "Updating SCCM Client on $server"
    #SCCM Command - Hardware Inventory Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000001}') |Out-Null
    #SCCM Command - Discovery Data Collection Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000003}') |Out-Null
    #SCCM Command - File Collection Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000010}') |Out-Null
    #SCCM Command - Software Inventory Cycle	
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000002}') |Out-Null
    #SCCM Command - Software Update Scan Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000113}') |Out-Null
    #SCCM Command - Application Deployment Evaluation Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000121}') |Out-Null
    #SCCM Command - File Collection Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000010}') |Out-Null
    #SCCM Command - Software Metering Usage Report Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000031}') |Out-Null
    #SCCM Command - Machine Policy Retrieval Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000021}') |Out-Null
    #SCCM Command - Machine Policy Evaluation Cycle	
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000022}') |Out-Null
    #SCCM Command - User Policy Retrieval Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000026}') |Out-Null
    #SCCM Command - User Policy Evaluation Cycle	
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000027}') |Out-Null
    #SCCM Command - State Message Refresh	
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000111}') |Out-Null
    #SCCM Command - Windows Installers Source List Update Cycle
    ([wmiclass]"\\$Computer\ROOT\ccm:SMS_Client").TriggerSchedule('{00000000-0000-0000-0000-000000000032}') |Out-Null
}
}
Stop-Transcript
