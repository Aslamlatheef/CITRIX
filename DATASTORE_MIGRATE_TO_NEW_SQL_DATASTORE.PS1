#### you need to run this script in the DDC of your CITRIX ENVIRONIMENT

Add-PSSnapin Citrix*
$currentdb=Get-BrokerDBConnectio
Write-Host " this is your current DB $currentdb"

## Disable Configuration Logging
Write-Host "Disabling Configuration Logging"
Set-LogSite -State "Disabled"
Set-MonitorConfiguration -DataCollectionEnabled $False
Write-Host "Disable Configuration Logging if no error pops out"

 
## Replace $ServerName with the New SQL server, and instance if present
## Replace $DBName,$LogDBName,$MonitorDBName with the name of your restored Database
 

$ServerName="SQLCluster.domain.com"
$DBName ="Citrix_XenApp_Site"
$LogDBName = "Citrix_XenApp_Logging"
$MonitorDBName = "Citrix_XenApp_Monitoring"
 
$cs="Server=$ServerName; Initial Catalog=$DBName; Integrated Security=True"
write-host "check connection with this server $cs"

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
 
Set-AcctDBConnection -DBConnection $null -AdminAddress $Controller
Set-AnalyticsDBConnection –DBConnection $null –AdminAddress $Controller
Set-AppLibDBConnection –DBConnection $null –AdminAddress $Controller
Set-BrokerDBConnection -DBConnection $null -AdminAddress $Controller
Set-ConfigDBConnection -DBConnection $null -AdminAddress $Controller
Set-EnvTestDBConnection -DBConnection $null -AdminAddress $Controller
Set-HypDBConnection -DBConnection $null -AdminAddress $Controller
Set-MonitorDBConnection -DBConnection $null -AdminAddress $Controller
Set-OrchDBConnection –DBConnection $null –AdminAddress $Controller
Set-ProvDBConnection -DBConnection $null -AdminAddress $Controller
Set-SfDBConnection -DBConnection $null -AdminAddress $Controller
Set-TrustDBConnection –DBConnection $null –AdminAddress $Controller
Set-LogDBConnection -DBConnection $null -AdminAddress $Controller
Set-AdminDBConnection –Force -DBConnection $null -AdminAddress $Controller
 
Get-Service Citrix* | Stop-Service -Force
Get-Service Citrix* | Start-Service
 
$cs="Server=$ServerName;Initial Catalog=$DBName;Integrated Security=True"
Write-Host "Setting variable for Server DB name as $cs"
$csLogging= "Server=$ServerName;Initial Catalog=$LogDBName;Integrated Security=True"
Write-Host "Setting variable for Logging db as $csLogging"
$csMonitoring = "Server=$ServerName;Initial Catalog=$MonitorDBName;Integrated Security=True"
Write-Host "Setting variable Monitoring db as $csMonitoring "
 
Set-AdminDBConnection -DBConnection $cs
Set-ConfigDBConnection -DBConnection $cs
Set-BrokerDBConnection -DBConnection $cs
Set-EnvTestDBConnection -DBConnection $cs
Set-LogDBConnection -DBConnection $cs
Set-LogDBConnection -DataStore Logging -DBConnection $csLogging
Set-MonitorDBConnection -DBConnection $cs
Set-MonitorDBConnection -DataStore Monitor -DBConnection $csMonitoring


### https://docs.citrix.com/en-us/advanced-concepts/implementation-guides/database-connection-strings.html##
##resetting Connections######
Reset-MonitorDataStore –DataStore Monitor –AdminAddress $Controller
Reset-LogDataStore –DataStore Logging –AdminAddress $Controller
 
## Enable Monitoring
write-host "Enabling Monitoring"
Set-MonitorConfiguration -DataCollectionEnabled $true
write-host "Monitoring Enabled"
 
## Enable Configuration Logging
write-host "Enabling logging"
Set-LogSite -State "Enabled"
write-host "enabled logging"

#### check status of the service now###
Write-Host "checking status of connection"
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

##### check the currentDB ######
$currentdb=Get-BrokerDBConnectio
Write-Host " this is your updated Datastore $currentdb"

### the END##
Write-Host "THE END"
