<#
.SYNOPSIS
    Reports diagnostic-settings coverage across a subscription.

.DESCRIPTION
    Read-only companion to enable-diagnostics.sh: enumerates resources of the
    monitored types and reports which ones have no diagnostic setting routing
    to the expected Log Analytics workspace. Intended for scheduled compliance
    reporting (pipeline cron) — it changes nothing.

.PARAMETER WorkspaceId
    Resource ID of the central Log Analytics workspace settings should target.

.PARAMETER ResourceGroupName
    Optional resource group to limit the scan.

.PARAMETER ResourceType
    Resource types to check. Defaults to the platform's curated set.

.PARAMETER OutputPath
    Optional path for a CSV export of the uncovered resources.

.EXAMPLE
    ./Get-DiagnosticCoverage.ps1 -WorkspaceId $lawId -OutputPath coverage.csv

.NOTES
    Exit codes: 0 = full coverage, 3 = gaps found, 2 = not authenticated.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceId,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string[]]$ResourceType = @(
        'Microsoft.Web/sites',
        'Microsoft.Web/serverfarms',
        'Microsoft.Sql/servers/databases',
        'Microsoft.KeyVault/vaults',
        'Microsoft.ContainerService/managedClusters',
        'Microsoft.Network/applicationGateways',
        'Microsoft.Network/azureFirewalls',
        'Microsoft.Storage/storageAccounts'
    ),

    [Parameter()]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$context = Get-AzContext
if (-not $context) {
    Write-Error 'Not authenticated - run Connect-AzAccount first.'
    exit 2
}
Write-Verbose "Scanning subscription $($context.Subscription.Id)"

$resourceParams = @{}
if ($ResourceGroupName) { $resourceParams['ResourceGroupName'] = $ResourceGroupName }

$resources = Get-AzResource @resourceParams |
    Where-Object { $_.ResourceType -in $ResourceType }

$report = foreach ($resource in $resources) {
    $settings = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
    $covered = [bool]($settings | Where-Object { $_.WorkspaceId -eq $WorkspaceId })

    [PSCustomObject]@{
        Name          = $resource.Name
        ResourceGroup = $resource.ResourceGroupName
        Type          = $resource.ResourceType
        Covered       = $covered
        SettingCount  = @($settings).Count
        ResourceId    = $resource.ResourceId
    }
}

$uncovered = @($report | Where-Object { -not $_.Covered })

Write-Output ("Checked {0} resource(s): {1} covered, {2} uncovered." -f `
    @($report).Count, (@($report).Count - $uncovered.Count), $uncovered.Count)

if ($uncovered.Count -gt 0) {
    $uncovered | Format-Table Name, ResourceGroup, Type -AutoSize | Out-String | Write-Output
}

if ($OutputPath) {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Output "Full report written to $OutputPath"
}

if ($uncovered.Count -gt 0) { exit 3 }
exit 0
