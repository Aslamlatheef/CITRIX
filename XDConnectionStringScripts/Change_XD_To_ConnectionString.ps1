<#
   Copyright (c) Citrix Systems, Inc. All rights reserved.

.SYNOPSIS
   Reconfigure XenDesktop connection string to that provided

.DESCRIPTION
   This script uses the XenDesktop Powershell API to reconfigure
   the database connection strings in the correct sequence to update the connection string.  
#>

param (
    [switch]    $help,	
	[Parameter(Mandatory=$True,Position=1)]
	[string]	$newSiteConnectionString,
	
	[Parameter(Position=2)]
	[string]	$newMonitorConnectionString,
	
	[Parameter(Position=3)]
	[string]	$newConfigLoggingConnectionString
    )

if ($help)
{
    Get-Help($MyInvocation.MyCommand.Path) -detailed
    return
}

if ([string]::IsNullOrEmpty($newMonitorConnectionString))
{
	$newMonitorConnectionString = $newSiteConnectionString
}

if ([string]::IsNullOrEmpty($newConfigLoggingConnectionString))
{
	$newConfigLoggingConnectionString = $newSiteConnectionString
}

#requires -Version 3.0
. $PSScriptRoot\DBConnectionStringFuncs.ps1

function CreateNewConnectionString([string]$newConnectionString)
{
	$connectionBuilder = new-Object System.Data.SqlClient.SqlConnectionStringBuilder $newConnectionString
	    
	return $connectionBuilder.ConnectionString
}

Check-Snapins
$controllers = CreateControllerList
Check-Services $controllers

$siteConnectionString = Get-BrokerDBConnection -AdminAddress $controllers[0]
$configLoggingDataStoreConnectionString = Get-LogDBConnection -DataStore "Logging" -AdminAddress $controllers[0]
$monitorLoggingDataStoreConnectionString = Get-MonitorDBConnection -DataStore "Monitor" -AdminAddress $controllers[0]

$siteUpdatedConnectionString = CreateNewConnectionString $newSiteConnectionString
$configLoggingUpdatedConnectionString = CreateNewConnectionString $newConfigLoggingConnectionString
$monitorUpdatedConnectionString = CreateNewConnectionString $newMonitorConnectionString 

ProcessConnectionStringUpdates $controllers $siteConnectionString $siteUpdatedConnectionString $configLoggingDataStoreConnectionString $configLoggingUpdatedConnectionString $monitorLoggingDataStoreConnectionString $monitorUpdatedConnectionString