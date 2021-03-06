<#
   Copyright (c) Citrix Systems, Inc. All rights reserved.

.SYNOPSIS
   Reconfigure XenDesktop connection strings to include MultiSubnetFailover

.DESCRIPTION
   This script uses the XenDesktop Powershell API to reconfigure
   the database connection strings in the correct sequence to update the connection string.
#>

param (
    [switch]    $help
    )

if ($help)
{
    Get-Help($MyInvocation.MyCommand.Path) -detailed
    return
}

#requires -Version 3.0
. $PSScriptRoot\DBConnectionStringFuncs.ps1

function CreateNewConnectionString([string]$currentConnectionString)
{
	$connectionBuilder = new-Object System.Data.SqlClient.SqlConnectionStringBuilder $currentConnectionString
	if ($connectionBuilder["MultiSubnetFailover"] -eq $null)
	{
    	$connectionBuilder["MultiSubnetFailover"] = $true
	}
	else
	{
		$connectionBuilder["MultiSubnetFailover"] = !$connectionBuilder["MultiSubnetFailover"]
	}	
    
	return $connectionBuilder.ConnectionString
}

Check-Snapins

## perhaps a catch 22, but we assume that we can actually get a list of controllers from the current ddc
$controllers = CreateControllerList
Check-Services $controllers

$siteConnectionString = Get-BrokerDBConnection -AdminAddress $controllers[0]
$configLoggingDataStoreConnectionString = Get-LogDBConnection -DataStore "Logging" -AdminAddress $controllers[0]
$monitorLoggingDataStoreConnectionString = Get-MonitorDBConnection -DataStore "Monitor" -AdminAddress $controllers[0]

$siteUpdatedConnectionString = CreateNewConnectionString $siteConnectionString
$configLoggingUpdatedConnectionString = CreateNewConnectionString $configLoggingDataStoreConnectionString
$monitorUpdatedConnectionString = CreateNewConnectionString $monitorLoggingDataStoreConnectionString

ProcessConnectionStringUpdates $controllers $siteConnectionString $siteUpdatedConnectionString $configLoggingDataStoreConnectionString $configLoggingUpdatedConnectionString $monitorLoggingDataStoreConnectionString $monitorUpdatedConnectionString