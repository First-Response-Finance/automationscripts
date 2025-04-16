param (
    [Parameter(Mandatory = $true)]
    [string] $containerAppName,
    [Parameter(Mandatory = $true)]
    [int] $minReplicas
)

$environment = Get-AutomationVariable -Name "Environment"

Write-Output "Logging in with managed identity"
Connect-AzAccount -Identity | Out-Null

Write-Output "Updating container app settings"
Update-AzContainerApp `
    -Name $containerAppName `
    -ResourceGroupName "rg-frfl-evolve-${environment}" `
    -ScaleMinReplica $minReplicas | Out-Null

Write-Output "Successfully set min replicas"