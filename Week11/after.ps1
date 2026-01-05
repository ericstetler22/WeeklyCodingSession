#requires -Version 3.0
<#
.SYNOPSIS
Refactors a reporting script to reduce duplication and clarify intent.

.DESCRIPTION
Demonstrates small, safe refactors: shared filters, clear helpers, fewer repeated passes.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "output\summary.txt")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

function Where-WindowsCompany {
    param($Devices)
    return $Devices | Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }
}

function Count-Where {
    param($Items, [scriptblock]$Predicate)
    return ($Items | Where-Object $Predicate | Measure-Object).Count
}

$devices = (Get-Content -Path (Join-Path $PSScriptRoot "data\devices.json") -Raw | ConvertFrom-Json)
$windowsCompany = Where-WindowsCompany -Devices $devices

$summary = [pscustomobject]@{
    TotalDevices       = $devices.Count
    WindowsCompany     = $windowsCompany.Count
    Windows10Company   = Count-Where -Items $windowsCompany -Predicate { $_.osVersion -like '10.*' }
    Windows11Company   = Count-Where -Items $windowsCompany -Predicate { $_.osVersion -like '11.*' }
    NonCompliantWinCo  = Count-Where -Items $windowsCompany -Predicate { $_.complianceState -eq 'noncompliant' }
}

Ensure-Dir -Path $OutputPath
$summary | Format-List | Out-String | Set-Content -Path $OutputPath
Write-Host "Wrote summary to $OutputPath"
