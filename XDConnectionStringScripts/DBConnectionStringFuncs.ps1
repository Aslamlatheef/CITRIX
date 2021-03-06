## Copyright (c) Citrix Systems, Inc. All rights reserved.
##
## This table contains the service information used by the rest of the code to update services
## By using this table a lot of code was reduced to looping
## Ordering is alphabetical, other than Config Logging and DA which must be last
$ServiceProperties = @(
    @{
        ServiceName = "AD Identity";
        SnapInName = "Citrix.ADIdentity.Admin.V2";
        SetDBConnCmdlet = "Set-AcctDBConnection";
        GetServiceStatus = "Get-AcctServiceStatus";
    },
    @{
        ServiceName = "Analytics";
        SnapInName = "Citrix.Analytics.Admin.V1";
        SetDBConnCmdlet = "Set-AnalyticsDBConnection";
        GetServiceStatus = "Get-AnalyticsServiceStatus";
        Optional = $true;
    },
    @{
        ServiceName = "App Library";
        SnapInName = "Citrix.AppLibrary.Admin.V1";
        SetDBConnCmdlet = "Set-AppLibDBConnection";
        GetServiceStatus = "Get-AppLibServiceStatus";
        Optional = $true;
    },
    @{
        ServiceName = "Broker";
        SnapInName = "Citrix.Broker.Admin.V2";
        SetDBConnCmdlet = "Set-BrokerDBConnection";
        GetServiceStatus = "Get-BrokerServiceStatus";
    },
    @{
        ServiceName = "Configuration";
        SnapInName = "Citrix.Configuration.Admin.V2";
        SetDBConnCmdlet = "Set-ConfigDBConnection";
        GetServiceStatus = "Get-ConfigServiceStatus";
    },
    @{
        ServiceName = "Env Test";
        SnapInName = "Citrix.EnvTest.Admin.V1";
        SetDBConnCmdlet = "Set-EnvTestDBConnection";
        GetServiceStatus = "Get-EnvTestServiceStatus";
    },
    @{
        ServiceName = "Hosting";
        SnapInName = "Citrix.Host.Admin.V2";
        SetDBConnCmdlet = "Set-HypDBConnection";
        GetServiceStatus = "Get-HypServiceStatus";
    },
    @{
        ServiceName = "Machine Creation";
        SnapInName = "Citrix.MachineCreation.Admin.V2";
        SetDBConnCmdlet = "Set-ProvDBConnection";
        GetServiceStatus = "Get-ProvServiceStatus";
    },
    @{
        ServiceName = "Monitor";
        SnapInName = "Citrix.Monitor.Admin.V1";
        SetDBConnCmdlet = "Set-MonitorDBConnection";
        GetServiceStatus = "Get-MonitorServiceStatus";
    },
    @{
        ServiceName = "Orchestration";
        SnapInName = "Citrix.Orchestration.Admin.V1";
        SetDBConnCmdlet = "Set-OrchDBConnection";
        GetServiceStatus = "Get-OrchServiceStatus";
        Optional = $true;
    },
    @{
        ServiceName = "StoreFront Integration";
        SnapInName = "Citrix.Storefront.Admin.V1";
        SetDBConnCmdlet = "Set-SFDBConnection";
        GetServiceStatus = "Get-SFServiceStatus";
    },
    @{
        ServiceName = "Trust";
        SnapInName = "Citrix.Trust.Admin.V1";
        SetDBConnCmdlet = "Set-TrustDBConnection";
        GetServiceStatus = "Get-TrustServiceStatus";
        Optional = $true;
    },
    ## Config Log and DA need to be last
    @{
        ServiceName = "Configuration Logging";
        SnapInName = "Citrix.ConfigurationLogging.Admin.V1";
        SetDBConnCmdlet = "Set-LogDBConnection";
        GetServiceStatus = "Get-LogServiceStatus";
    },
    @{
        ServiceName = "Delegated Admin";
        SnapInName = "Citrix.DelegatedAdmin.Admin.V1";
        SetDBConnCmdlet = "Set-AdminDBConnection";
        GetServiceStatus = "Get-AdminServiceStatus";
        NeedsForce = $true;
    }
    ## do not add more services here, Config Log and DA need to be last.
    );

$ServiceInfoObjects = New-Object System.Collections.ArrayList
foreach ($props in $ServiceProperties)
{
    $serviceInfo = New-Object PSObject -Property $props 
    $ServiceInfoObjects.Add($serviceInfo) | Out-Null;
}

function Check-SnapinLoaded([string]$snapinName)
{    
    if ( (Get-PSSnapin -Name $snapinName -ErrorAction SilentlyContinue) -eq $null )
    {
        Add-PsSnapin $snapinName -ErrorAction SilentlyContinue
        if ( (Get-PSSnapin -Name $snapinName -ErrorAction SilentlyContinue) -eq $null )
        {
            write-host -ForegroundColor Red ("Unable to locate and load snapin {0}." -f $snapinName)
            return $false
        }
    }
    return $true
}

function Check-Snapins
{
    $loadFailed = $false
    $ignoredSnapIns = @()
    foreach ($serviceInfo in $ServiceInfoObjects)
    {
        $snapinLoaded = (Check-SnapinLoaded $serviceInfo.SnapInName)
        if (!$snapinLoaded)
        {
            if ($serviceInfo.Optional)
            {
                Write-Host ("Snapin {0} is optional, and not available." -f $serviceInfo.SnapInName)
                $ignoredSnapIns += $serviceInfo
                $snapinLoaded = $true
                continue;
            }
        }
        $loadFailed = !$snapinLoaded -or $loadFailed
    }
    if ($loadFailed)
    {
        write-host -ForegroundColor Red "Unable to locate all snapins, please check your installation"
        exit
    }
    foreach ($serviceInfo in $ignoredSnapIns)
    {
        $ServiceInfoObjects.Remove($serviceInfo)
    }
    
    write-host -ForegroundColor Green ("Loaded {0} snapins, {1} optional snapins not found." -f $ServiceInfoObjects.Count, $ignoredSnapIns.Count)
}

<#
.SYNOPSIS
Request a yes or no answer to a question on continuing the script.

.DESCRIPTION
Requests the user provides a yes or no continuing with the script.
Default is to assume that the user doesn't wish to continue.
Returns 0 for yes and 1 for no.

.PARAMETER message 
a message to display the user.

.EXAMPLE
$continue = ConfirmContinue "There was an error, are you sure you wish to continue?"
if ($continue -eq 1)
{
    exit
}
#>
function ConfirmContinue([string]$message)
{
    $yesNoChoice = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
    
    $yesNoChoice.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" "&Yes"))
    $yesNoChoice.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" "&No"))
   
    $Host.ui.PromptForChoice("Are you sure?", $message, $yesNoChoice, 1)
}

function Check-Services([String[]]$controllers)
{
    $activity = "Checking {0} controller(s)" -f $controllers.Count

    Write-Host "Checking DDC Services are running..."
    Write-Progress $activity -Id 2 -PercentComplete 0 -Status "Checking Controllers"
    $count = 0
    $ServiceErrors = 0

    foreach ($controller in $controllers)
    {
        $status = ("Checking {0}" -f $controller)
        $percent = [Math]::Round(($count / $controllers.Count) * 100)
        Write-Progress $activity -Id 2 -PercentComplete 0 -Status $status
        
        foreach ($serviceInfo in $ServiceInfoObjects)
        {
            $ServiceStatus = $null
            try 
            {
                $ServiceStatus = & $serviceInfo.GetServiceStatus -AdminAddress $controller
            }
            catch
            {
                write-host -ForegroundColor Red ("{0} Service on Controller {1} reported an error of:" -f $serviceInfo.ServiceName,$controller)
                write-host -ForegroundColor Red $error[0]
                $ServiceErrors = $ServiceErrors + 1
                continue
            }

            if ($ServiceStatus.ServiceStatus -ne "OK")
            {
                write-host -ForegroundColor Red ("{0} Service on Controller {1} reported status of {2}" -f $serviceInfo.ServiceName,$controller,$ServiceStatus.ServiceStatus)
                $ServiceErrors = $ServiceErrors + 1
            }
        }
        $count = $count + 1
    }
    Write-Progress $activity -Id 2 -PercentComplete 100 -Status "All Controllers updated" -Completed
    Write-Host ("{0} Services Checked" -f ($controllers.Count * $ServiceInfoObjects.Count))
    if ($ServiceErrors -ne 0)
    {
        $continue = ConfirmContinue "There appear to be environmental issues, are you sure you wish to continue?"
    
        if ($continue -eq 1)
        {
            exit
        }
    }
}

function Set-MonitorDataStore([String[]]$controllers, [string]$newConnectionString)
{
    if ([String]::IsNullOrEmpty($newConnectionString))
    {
        write-error "Set-MonitorDataStore requires a new connection string"
        return
    }

    $firstController = $true;
    
    foreach ($controller in $controllers)
    {
        if ($firstController)
        {
            $null = Set-MonitorDBConnection -DataStore Monitor -DBConnection $newConnectionString -AdminAddress $controller
            $firstController = $false;
        }
        else
        {
            $null = Reset-MonitorDataStore -DataStore Monitor -AdminAddress $controller
        }
    }
}

function Reset-MonitorDataStoreString([String[]]$controllers)
{
    $firstController = $true;
    
    foreach ($controller in $controllers)
    {
        if ($firstController)
        {
            $null = Set-MonitorDBConnection -DataStore Monitor -DBConnection $null -AdminAddress $controller
            $firstController = $false;
        }
        else
        {
            $null = Reset-MonitorDataStore -DataStore Monitor -AdminAddress $controller
        }
    }
}

function Set-ConfigLogDataStore([String[]]$controllers, [string]$newConnectionString)
{
    if ([String]::IsNullOrEmpty($newConnectionString))
    {
        write-error "Set-ConfigLogDataStore requires a new connection string"
        return
    }

    $firstController = $true;
    
    foreach ($controller in $controllers)
    {
        if ($firstController)
        {
            $null = Set-LogDBConnection -DataStore Logging -DBConnection $newConnectionString -AdminAddress $controller
            $firstController = $false;
        }
        else
        {
            $null = Reset-LogDataStore -DataStore Logging -AdminAddress $controller
        }
    }
}

function Reset-ConfigLogDataStore([String[]]$controllers)
{
    $firstController = $true;
    
    foreach ($controller in $controllers)
    {
        if ($firstController)
        {
            $null = Set-LogDBConnection -DataStore Logging -DBConnection $null -AdminAddress $controller
            $firstController = $false;
        }
        else
        {
            $null = Reset-LogDataStore -DataStore Logging -AdminAddress $controller
        }
    }
}

function Set-SiteDatabase([String[]]$controllers, [string]$newConnectionString, [bool]$resetConnectionString, [bool]$alwaysForce = $false)
{
    if ($resetConnectionString)
    {
        $actualConnectionString = $null
    }
    else
    {
        if ([String]::IsNullOrEmpty($newConnectionString))
        {
            write-error "ConnectionString should not be empty or null!";
            exit
        }
        else
        {
            $actualConnectionString = $newConnectionString
        }
    }

    $activity = "Updating {0} controller(s)" -f $controllers.Count
    Write-Progress $activity -ParentId 1 -Id 2 -PercentComplete 0 -Status "Updating Controllers"
    $controllerCount = 0

    foreach ($controller in $controllers)
    {
        $status = "Updating {0}" -f $controller
        $controllerPercent = [Math]::Round(($controllerCount / $controllers.Count) * 100)
        Write-Progress $activity -ParentId 1 -Id 2 -PercentComplete $controllerPercent -Status $status

        $serviceActivity = "Updating Service Connection String"

        $serviceCount = 0
        foreach ($serviceInfo in $ServiceInfoObjects)
        {
            $servicePercent = [Math]::Round(($serviceCount / $ServiceInfoObjects.Count) * 100)
            Write-Progress $serviceActivity -ParentId 2 -Id 3 -PercentComplete $servicePercent -Status $serviceInfo.ServiceName
           
            if (($alwaysForce) -or ($serviceInfo.NeedsForce -ne $null -and $serviceInfo.NeedsForce))
            {
                $SetResult = & $serviceInfo.SetDBConnCmdlet -AdminAddress $controller -DBConnection $actualConnectionString -force
            }
            else
            {
                $SetResult = & $serviceInfo.SetDBConnCmdlet -AdminAddress $controller -DBConnection $actualConnectionString
            }
            $serviceCount = $serviceCount + 1;            
        }
        Write-Progress $serviceActivity -ParentId 2 -Id 3 -PercentComplete 100 -Status "Complete" -Completed
    
        $controllerCount = $controllerCount + 1
    }
    Write-Progress $activity -ParentId 1 -Id 2 -PercentComplete 100 -Status "All Controllers updated" -Completed
}

function CreateControllerList
{
    $controllers = get-BrokerController
    $ControllerList = New-Object System.Collections.ArrayList
    foreach($controller in $controllers)
    {
        $ControllerList.Add($controller.DNSName) | Out-Null
    }
    
    if ($ControllerList.Count -eq 0)
    {
        Write-Host -ForegroundColor Yellow ("No controllers found, assuming site is broken, using localhost")
        $ControllerList.Add('localhost') | Out-Null
    }
    
    return ,$controllerList
}

function DisplayConnectionStringChange([string]$whichConnectionString,[string]$connectionString,[string]$updatedConnectionString)
{
    Write-Host ("{0} connection string will be updated:" -f $whichConnectionString)
    Write-Host ("From: {0}" -f $connectionString)
    Write-Host ("To:   {0}" -f $updatedConnectionString)
}

function ProcessConnectionStringUpdates(
[String[]]$controllers,
[String]$siteConnectionString,
[String]$siteUpdatedConnectionString,
[String]$configLoggingDataStoreConnectionString,
[String]$configLoggingUpdatedConnectionString,
[String]$monitorLoggingDataStoreConnectionString,
[String]$monitorUpdatedConnectionString
)
{
    if ([string]::IsNullOrEmpty($configLoggingDataStoreConnectionString))
    {
        $configLoggingDataStoreConnectionString = $siteConnectionString
    }
    if ([string]::IsNullOrEmpty($configLoggingUpdatedConnectionString))
    {
        $configLoggingUpdatedConnectionString = $siteUpdatedConnectionString
    }
    if ([string]::IsNullOrEmpty($monitorLoggingDataStoreConnectionString))
    {
        $monitorLoggingDataStoreConnectionString = $siteConnectionString
    }
    if ([string]::IsNullOrEmpty($monitorUpdatedConnectionString))
    {
        $monitorUpdatedConnectionString = $siteUpdatedConnectionString
    }

    Write-Host ""
    DisplayConnectionStringChange "Site" $siteConnectionString $siteUpdatedConnectionString
    Write-Host ""
    DisplayConnectionStringChange "Configuration Logging" $configLoggingDataStoreConnectionString $configLoggingUpdatedConnectionString
    Write-Host ""
    DisplayConnectionStringChange "Monitoring" $monitorLoggingDataStoreConnectionString $monitorUpdatedConnectionString

    Write-Host ""
    Write-Host ("This will affect {0} controller(s):" -f $controllers.Count)
    foreach ($controllerName in $controllers)
    {
        Write-Host ("{0}" -f $controllerName)
    }

    $continue = ConfirmContinue "Continuing with this script will change your database configuration. If an error occurs it may require manual intervention to resolve issues. Are you sure you wish to continue?"

    if ($continue -eq 1)
    {
        Write-Host "No changes have been made."
        return
    }
    
    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 0 -Status "Resetting Configuration Logging Datastore connection string"
    Reset-ConfigLogDataStore $controllers

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 16 -Status "Resetting Monitoring Datastore connection string"
    Reset-MonitorDataStoreString $controllers

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 33 -Status "Resetting Site Database connection string"
    Set-SiteDatabase $controllers $null $true

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 50 -Status "Setting new Site Database connection string"
    Set-SiteDatabase $controllers $siteUpdatedConnectionString $false

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 66 -Status "Setting new Configuration Logging Datastore connection string"
    Set-ConfigLogDataStore $controllers $configLoggingUpdatedConnectionString

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 83 -Status "Setting new Monitoring Datastore connection string"
    Set-MonitorDataStore $controllers $monitorUpdatedConnectionString

    Write-Progress "Updating Connection Strings" -Id 1 -PercentComplete 100 -Status "New Connection strings applied" -Completed
}