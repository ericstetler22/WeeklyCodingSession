#requires -Version 3.0
<#
.SYNOPSIS
Demonstrates fail-fast behavior for Graph-like calls with clear errors.

.DESCRIPTION
Uses the shared MockGraph module, detects throttling, and shows a safe retry pattern.
#>
[CmdletBinding()]
param(
    [ValidateSet('success','unauthorized','throttle','empty','transient')]
    [string]$Mode = 'success',

    [string]$DataPath = (Join-Path $PSScriptRoot "data\devices.json"),
    [string]$OutPath  = (Join-Path $PSScriptRoot "output\result.txt")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot "..\common\MockGraph\MockGraph.psd1"
Import-Module $modulePath -Force

function Ensure-Dir {
    param([Parameter(Mandatory=$true)][string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

try {
    $devices = Invoke-WithMockRetry -MaxAttempts 3 -ScriptBlock {
        Invoke-MockGraphRequest -Mode $Mode -DataPath $DataPath -TransientFailures 1
    }

    if ($null -eq $devices -or $devices.Count -eq 0) {
        throw "No devices returned. Stopping (simulated)."
    }

    Ensure-Dir -Path $OutPath
    Set-Content -Path $OutPath -Value ("Fetched {0} devices (mode={1})" -f $devices.Count, $Mode)

    Write-Host "Success. See $OutPath"
    exit 0
}
catch {
    Ensure-Dir -Path $OutPath
    Set-Content -Path $OutPath -Value ("FAILED: {0}" -f $_.Exception.Message)
    Write-Error $_.Exception.Message
    exit 1
}
