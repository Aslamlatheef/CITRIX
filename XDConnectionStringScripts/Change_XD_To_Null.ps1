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

Check-Snapins

## perhaps a catch 22, but we assume that we can actually get a list of controllers from the current ddc
$controllers = CreateControllerList
Check-Services $controllers

Reset-ConfigLogDataStore $controllers
Reset-MonitorDataStoreString $controllers

Set-SiteDatabase $controllers $null $true $true

