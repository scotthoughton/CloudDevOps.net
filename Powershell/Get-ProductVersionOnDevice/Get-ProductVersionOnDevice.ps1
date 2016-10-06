<#   
.SYNOPSIS   
Script that returns current version of the software specified on a computer, and compares to the version you specified
    
.DESCRIPTION 
This script uses the the SCCM optimized WMI DB Win32Reg_AddRemovePrograms to query a list of computers for the specified software and version
 
.PARAMETER Computers
The computers that will be queried by this script, local administrative permissions are required to query this information

.PARAMETER Software
The Software package we are getting version info for, must match exactly how it reads from Add/Remove Programs to prevent errors of duplicate software


.PARAMETER SoftwareVersion
The version of software we are comparing against, must be in version format i.e 6.5.9600 


.NOTES   
Name: Get-ProductVersionOnDevice.ps1
Author: Scott W Houghton
DateCreated: 2016-10-05
DateUpdated: 2016-10-06
Site: http://CloudDevOps.net
Version: 1.1.0

.LINK
http://CloudDevOps.net

.EXAMPLE
	.\Get-ProductVersionOnDevice.ps1 -Computers server01 -Software "Citrix XenApp 6.5" -SoftwareVersion "6.5.9600.0"

Description
-----------
This command will query server01 and displays if Citrix XenApp is installed and if the version matches or needs an upgrade

.EXAMPLE
	.\Get-ProductVersionOnDevice.ps1 -Computers server01,server02,server03 -Software "Citrix XenApp 6.5" -SoftwareVersion "6.5.9600.0"

Description
-----------
This command will query server01,server02,server03 and displays if Citrix XenApp is installed and if the version matches or needs an upgrade

.EXAMPLE
	.\Get-ProductVersionOnDevice.ps1 

Description
-----------
This command will prompy for the list of computers to query and promot for the software and version to query for




#>
#Requires -Version 5
param(
    [string]$Software,
    [string[]]$Computers,
    [version]$SoftwareVersion
)
#Set Paths
$path = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
$scriptName =  $MyInvocation.MyCommand.Name
if(!(Test-Path "$path\Logs")){ New-Item "$path\Logs" -type directory }
if(!(Test-Path "$path\CSVs")){ New-Item "$path\CSVs" -type directory }
$dateTime = Get-Date -Format  yyyy-MM-dd_HHmm
$Logfile = "$path\Logs\$scriptName" + "-Log"+ $dateTime + ".txt"
$transcriptPath = "$path\Logs\$scriptName" + "Transcript"+ $dateTime + ".txt"
$csvPath = "$path\CSVs\$scriptName" + $dateTime + ".csv"
Start-Transcript -Path $transcriptPath

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
Function LogWrite
{
   Param ([string]$logstring)
   Write-Output "$logstring"
   Add-content $Logfile -value $logstring
}
if($Software -eq $null -or $Software -eq "" -or $Software -eq " "){[string]$Software = Show-TextBox -formText "Software Entry"  -multiLineText $false -labelText "Name of Software. ie 'Citrix XenApp 6.5' "}
if($SoftwareVersion -eq $null -or $SoftwareVersion -eq "" -or $SoftwareVersion -eq " "){$SoftwareVersionBox = Show-TextBox -multiLineText $false -formText "Software Version Entry" -labelText "Full Minimium Software Version. ie '6.5.9600.0'";[version]$SoftwareVersion = "$SoftwareVersionBox"}
if($Computers -eq $null -or $Computers -eq "" -or $Computers -eq " "){$Computers = Show-TextBox -formText "Computer Entry" -labelText "Enter 1 Computer Name Per Line:"}

 $versionListRoot = @()
foreach($Computer in $Computers){
    try{
    if(![string]::IsNullOrEmpty($Computer) -and $Computer -ne "" -and $Computer -ne " " -and $Computer -ne "`r`n"){
        if((Get-WmiObject -Class Win32Reg_AddRemovePrograms -ComputerName $Computer -ErrorAction Stop | Where DisplayName -match "$Software" | measure).Count -eq 1){
            $versionList = New-Object System.Object
            $Version = (Get-WmiObject -Class Win32Reg_AddRemovePrograms -ComputerName $Computer | Where DisplayName -match "$Software").Version
            if(![string]::IsNullOrEmpty($Version) -and $Version -ne "" -and $Version -ne " " -and $Version -ne "`r`n"){
            [version]$installedVersion = [version]$Version
            }
            else{
                [string]$installedVersion = "Not Installed"
            }
            $versionList | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
            $versionList | Add-Member -MemberType NoteProperty -Name Software -Value $Software
            if($installedVersion -ne "Not Installed" -and "$installedVersion" -ge "$SoftwareVersion"){
                LogWrite "$Computer - $Software - Needed: $SoftwareVersion - Installed: $installedVersion - Current"
                    $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $true
                    $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
                    
            }
            elseif($installedVersion -ne "Not Installed" -and "$installedVersion" -lt "$SoftwareVersion"){
                LogWrite "$Computer - $Software - Needed: $SoftwareVersion - Installed: $installedVersion -  Not Current"
                $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
                $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
            }
            else{
                LogWrite "$Computer - $Software - $installedVersion"
                $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
                $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
            }
            $versionList | Add-Member -MemberType NoteProperty -Name CurrentVersion -Value $SoftwareVersion
        }
        else{
            [string]$installedVersion = "Not Installed"
            LogWrite "$Computer - $Software - $installedVersion"
            $versionList = New-Object System.Object
            $versionList | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
            $versionList | Add-Member -MemberType NoteProperty -Name Software -Value $Software
            $versionList | Add-Member -MemberType NoteProperty -Name CurrentVersion -Value $SoftwareVersion
            $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
            $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
            
        }
        $versionListRoot += $versionList
    }
    }
    catch [System.UnauthorizedAccessException]
        {
            [string]$installedVersion = "No Permissions"
            LogWrite "$Computer - $Software - $installedVersion"
            $versionList = New-Object System.Object
            $versionList | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
            $versionList | Add-Member -MemberType NoteProperty -Name Software -Value $Software
            $versionList | Add-Member -MemberType NoteProperty -Name CurrentVersion -Value $SoftwareVersion
            $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
            $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
        }
        catch [System.Management.ManagementException]
        {
            [string]$installedVersion = "No Permissions"
            LogWrite "$Computer - $Software - $installedVersion"
            $versionList = New-Object System.Object
            $versionList | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
            $versionList | Add-Member -MemberType NoteProperty -Name Software -Value $Software
            $versionList | Add-Member -MemberType NoteProperty -Name CurrentVersion -Value $SoftwareVersion
            $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
            $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
        }
        catch [System.Exception]
        {
            if($_.Exception.GetType() -like "COMException")
            {
            [string]$installedVersion = "COM Communication Error"
            LogWrite "$Computer - $Software - $installedVersion"
            $versionList = New-Object System.Object
            $versionList | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
            $versionList | Add-Member -MemberType NoteProperty -Name Software -Value $Software
            $versionList | Add-Member -MemberType NoteProperty -Name CurrentVersion -Value $SoftwareVersion
            $versionList | Add-Member -MemberType NoteProperty -Name Current -Value $false
            $versionList | Add-Member -MemberType NoteProperty -Name InstalledVersion -Value "$installedVersion"
            }
        }
}
if($versionListRoot -ne $null){
$versionListRoot | Export-Csv -Path $csvPath -NoTypeInformation
}
else{
LogWrite "No Data Returned"
}
Stop-Transcript
pause