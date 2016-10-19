<#   
.SYNOPSIS   
Script that returns the status of the ICA and RDP ports on a server
    
.DESCRIPTION 
This script uses the test-netconnection cmdlet to test local or a remote computer for ICA and RDP port function.
 
.PARAMETER Computers
The computer that will be queried by this script

.NOTES   
Name: Test-CitrixServerPorts.ps1
Author: Scott W Houghton
DateCreated: 2016-10-19
DateUpdated: 2016-10-19
Site: http://CloudDevOps.net
Version: 1.0.0

.LINK
http://CloudDevOps.net

.EXAMPLE
	.\Test-CitrixServerPorts.ps1 -Computers server01

Description
-----------
This command will test server01 and  and displays the status of the ICA and RDP ports on a server

.EXAMPLE
	.\Test-CitrixServerPorts.ps1 -Computers server01,server02,server03

Description
-----------
This command will test server01,server02,server03 and displays the status of the ICA and RDP ports on a server

.EXAMPLE
	.\Test-CitrixServerPorts.ps1 -Computers $env:COMPUTERNAME

Description
-----------
This command will test localhost and  and displays the status of the ICA and RDP ports on a server




#>
#Requires -version 4
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
Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
   Write-Output "$logstring"
}
function Show-TextBox{
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
    $testHDX = test-netconnection -ComputerName $server -Port 1494 | Select TcpTestSucceeded
    $testRDP = test-netconnection -ComputerName $server -Port 3389 | Select TcpTestSucceeded
if($testHDX){
    LogWrite "$server - Citrix Port Connection Successful"
}
else{
    LogWrite "$server - Citrix Port Connection Failed"
}
if($testRDP){
    LogWrite "$server - RDP Port Connection Successful"
}
else{
    LogWrite "$server - RDP Port Connection Failed"
}
}
}
Stop-Transcript
