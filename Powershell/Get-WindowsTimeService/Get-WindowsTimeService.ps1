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
