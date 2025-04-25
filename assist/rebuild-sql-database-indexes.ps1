# This script needs to be placed here for the runbook to access it: https://github.com/First-Response-Finance/automationscripts
# This is workaround until Azure Automation supports bicep modules that can be uploaded with the runbook or accessed via a private storage account.
# You will need to delete the runbook in Azure to force it to pickup the changes in this file.

param (
    [Parameter(Mandatory = $true)]
    [string]$assistEnvironment,

    [Parameter(Mandatory = $true)]
    [string]$subscriptionId
)

Import-Module SQLServer

Write-Output "Authenticating with Managed Identity that is built into the Automation Account..."
#az login --identity | Out-Null

if ($subscriptionId) {
    Write-Output "Setting Azure subscription context to $subscriptionId..."
    az account set --subscription $subscriptionId
}

# Set variables
$databaseName = "sqldb-frfl-assist-$assistEnvironment"
$databaseServerInstance = "sql-frfl-assist-$assistEnvironment.database.windows.net"

# SQL query to get rebuild indexes on all tables
$query = @"
DECLARE @sql NVARCHAR(MAX);
SELECT @sql = (
    SELECT 'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] REBUILD; ' 
    FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.type IN (1, 2) AND i.name IS NOT NULL
    FOR XML PATH('')
);
EXEC sp_executesql @sql;
"@

if (Get-Module -ListAvailable -Name SQLServer) {
    Write-Information "SQLServer module already installed"
}
else {
    Install-Module SQLServer
}

# Execute SQL query
$token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-SqlCmd -ServerInstance $databaseServerInstance -Database $databaseName -AccessToken $token -Query $query
