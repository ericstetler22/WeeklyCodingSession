#requires -Version 3.0
<#
.SYNOPSIS
Exports a report of Windows 10 devices from mock device data.

.DESCRIPTION
This script is intentionally small and readable. It loads devices from JSON,
filters Windows devices with an OS version prefix (default 10.), and exports CSV.
#>
[CmdletBinding()]
param(
    [string]$InputPath = (Join-Path $PSScriptRoot "data\devices.json"),
    [string]$OutputCsv = (Join-Path $PSScriptRoot "output\win10_devices.csv"),
    [ValidateNotNullOrEmpty()][string]$OsVersionPrefix = "10."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DevicesFromJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Input file not found: $Path"
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

    return ($raw | ConvertFrom-Json)
}

function Select-WindowsDevicesByOsPrefix {
    param(
        [Parameter(Mandatory=$true)]$Devices,
        [Parameter(Mandatory=$true)][string]$Prefix
    )

    $pattern = "{0}*" -f $Prefix
    return $Devices | Where-Object {
        $_.operatingSystem -eq 'Windows' -and
        -not [string]::IsNullOrWhiteSpace($_.osVersion) -and
        ($_.osVersion -like $pattern)
    }
}

function Export-DeviceReportCsv {
    param(
        [Parameter(Mandatory=$true)]$Devices,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    $Devices |
        Select-Object id, deviceName, operatingSystem, osVersion, ownership, complianceState, lastSyncDateTime |
        Export-Csv -Path $Path -NoTypeInformation
}

$devices = Get-DevicesFromJson -Path $InputPath
$targets = Select-WindowsDevicesByOsPrefix -Devices $devices -Prefix $OsVersionPrefix

Export-DeviceReportCsv -Devices $targets -Path $OutputCsv

Write-Host ("Wrote {0} rows to {1}" -f ($targets | Measure-Object).Count, $OutputCsv)
