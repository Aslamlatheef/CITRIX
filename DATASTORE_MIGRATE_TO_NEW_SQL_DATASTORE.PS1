#### you need to run this script in the DDC of your CITRIX ENVIRONIMENT

Add-PSSnapin Citrix*

## Disable Configuration Logging
Set-LogSite -State "Disabled"
Set-MonitorConfiguration -DataCollectionEnabled $False
 
## Replace $ServerName with the New SQL server, and instance if present
## Replace $DBName,$LogDBName,$MonitorDBName with the name of your restored Database
 

$ServerName="SQLCluster.domain.com"
$DBName ="Citrix_XenApp_Site"
$LogDBName = "Citrix_XenApp_Logging"
$MonitorDBName = "Citrix_XenApp_Monitoring"
 
$cs="Server=$ServerName; Initial Catalog=$DBName; Integrated Security=True"
$cs
Test-AdminDBConnection -DBConnection $cs
Test-ConfigDBConnection -DBConnection $cs
Test-AcctDBConnection -DBConnection $cs
Test-AnalyticsDBConnection -DBConnection $cs
Test-HypDBConnection -DBConnection $cs
Test-ProvDBConnection -DBConnection $cs
Test-BrokerDBConnection -DBConnection $cs
Test-EnvTestDBConnection -DBConnection $cs
Test-LogDBConnection -DBConnection $cs
Test-MonitorDBConnection -DBConnection $cs
Test-SfDBConnection -DBConnection $cs
Test-AppLibDBConnection -DBConnection $cs
 
## First unregister the Delivery Controllers from the current database:
 
Set-ConfigDBConnection -DBConnection $null
Set-AcctDBConnection -DBConnection $null
Set-AnalyticsDBConnection -DBConnection $null
Set-HypDBConnection -DBConnection $null
Set-ProvDBConnection -DBConnection $null
Set-BrokerDBConnection -DBConnection $null
Set-EnvTestDBConnection -DBConnection $null
Set-SfDBConnection -DBConnection $null
Set-MonitorDBConnection -DataStore Monitor -DBConnection $null
Set-MonitorDBConnection -DBConnection $null
Set-LogDBConnection -DataStore Logging -DBConnection $null
Set-LogDBConnection -DBConnection $null
Set-AdminDBConnection -DBConnection $null -force
Set-AppLibDBConnection –DBConnection $null
 
Get-Service Citrix* | Stop-Service -Force
Get-Service Citrix* | Start-Service
 
$cs="Server=$ServerName;Initial Catalog=$DBName;Integrated Security=True"
$csLogging= "Server=$ServerName;Initial Catalog=$LogDBName;Integrated Security=True"
$csMonitoring = "Server=$ServerName;Initial Catalog=$MonitorDBName;Integrated Security=True"
 
Set-AdminDBConnection -DBConnection $cs
Set-ConfigDBConnection -DBConnection $cs
Set-BrokerDBConnection -DBConnection $cs
Set-EnvTestDBConnection -DBConnection $cs
Set-LogDBConnection -DBConnection $cs
Set-LogDBConnection -DataStore Logging -DBConnection $csLogging
Set-MonitorDBConnection -DataStore Monitor -DBConnection $csMonitoring

 
## Enable Monitoring
Set-MonitorConfiguration -DataCollectionEnabled $true
 
## Enable Configuration Logging
Set-LogSite -State "Enabled"
 
Get-AcctServiceStatus
Get-AdminServiceStatus
Get-BrokerServiceStatus
Get-ConfigServiceStatus
Get-EnvTestServiceStatus
Get-HypServiceStatus
Get-LogServiceStatus
Get-MonitorServiceStatus
Get-ProvServiceStatus
Get-SfServiceStatus
Get-AppLibServiceStatus
