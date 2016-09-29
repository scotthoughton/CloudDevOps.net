<#   
.SYNOPSIS   
Script that returns current TimeZone on a computer
    
.DESCRIPTION 
This script uses the Schedule.Service Windows Registry to query the local or a remote computer in order to gather the current TimeZones
 
.PARAMETER Servers
The computer that will be queried by this script, local administrative permissions are required to query this information

.NOTES   
Name: Get-WindowsTimeService.ps1
Author: Scott W Houghton
DateCreated: 2016-09-23
DateUpdated: 2016-09-29
Site: http://CloudDevOps.net
Version: 1.2.0

.LINK
http://CloudDevOps.net

.EXAMPLE
	.\Get-WindowsTimeService.ps1 $Servers server01

Description
-----------
This command will query server01 and displays the current TimeZone on that computer

.EXAMPLE
	.\Get-WindowsTimeService.ps1 $Servers server01,server02,server03

Description
-----------
This command will query server01,server02,server03 and displays the current TimeZone on the list of computers

.EXAMPLE
	.\Get-WindowsTimeService.ps1 $Servers $env:COMPUTERNAME

Description
-----------
This command will query localhost and displays the current TimeZone on that computer




#>
param(
    [String[]]$Servers
)

#Set Paths
$path = (Split-Path -Path ((Get-Variable -Name MyInvocation).Value).MyCommand.Path)
$scriptName = $MyInvocation.ScriptName
$dateTime = Get-Date -Format  yyyy-MM-dd_HHmm
$Logfile = "$path\$scriptName" + "-Log"+ $dateTime + ".txt"
$transcriptPath = "$path\$scriptName" + "Transcript"+ $dateTime + ".txt"

$OutputEncoding = [Console]::OutputEncoding
Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
   Write-Output "$logstring"
}
Function Get-LocalTimeZone{
 Param ([string]$server)
 
    Try{
        $w32reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$server)
        $keypath = 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
        $timeZoneKey  = $w32reg.OpenSubKey($keypath)
        $timeZone = $timeZoneKey.GetValue('StandardName')
        if($timeZone -clike "@tzres.dll*"){
            $timeZone = $timeZone.Replace("@tzres.dll,-","")
        $timeZoneCSV = Import-Csv "$path\CSVs\TimeZones.csv" | Where-Object { $_.TimeKey -eq $timeZone } 
        $timeZone =  $timeZoneCSV.TimeZone
        }
        $ipAddressRoot = [System.Net.Dns]::GetHostAddresses("$server")
        $ipAddress = $ipAddressRoot.IPAddressToString
        LogWrite "$server,$ipAddress,$timeZone"
}
Catch{
        $ipAddressRoot = [System.Net.Dns]::GetHostAddresses("$server")
        $ipAddress = $ipAddressRoot.IPAddressToString
        LogWrite "$server,$ipAddress,No Permission"
}
}
Start-Transcript -Path $transcriptPath
LogWrite "ServerName,IPAddress,TimeZone"
foreach($server in $Servers) {
    Get-LocalTimeZone -server $server
}
Stop-Transcript
