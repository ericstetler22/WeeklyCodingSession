#requires -Version 3.0
<#
.SYNOPSIS
Simulates a safe remediation action for specific device names.

.DESCRIPTION
Demonstrates guardrails: validates inputs, rejects wildcards, requires explicit targets,
and supports -WhatIf via ShouldProcess (PowerShell 5.1 compatible).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$DeviceNames,

    [string]$DataPath = (Join-Path $PSScriptRoot "data\devices.json"),
    [string]$LogPath  = (Join-Path $PSScriptRoot "output\actions.log")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-RunId { [guid]::NewGuid().ToString() }

function Ensure-Dir {
    param([Parameter(Mandatory=$true)][string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][ValidateSet('INFO','WARN','ERROR')][string]$Level,
        [string]$RunId,
        [string]$Device,
        [Parameter(Mandatory=$true)][string]$Message
    )
    Ensure-Dir -Path $Path
    $ts = (Get-Date).ToString("s")
    $line = "{0} [{1}] run={2} device={3} {4}" -f $ts, $Level, ($RunId ?? '-'), ($Device ?? '-'), $Message
    Add-Content -Path $Path -Value $line
}

$runId = New-RunId

function Assert-SafeDeviceNames {
    param([Parameter(Mandatory=$true)][string[]]$Names)

    foreach ($n in $Names) {
        if ([string]::IsNullOrWhiteSpace($n)) { throw "Device name cannot be empty." }
        if ($n -match '\*') { throw "Wildcards are not allowed: '$n'" }
        if ($n.Length -lt 5) { throw "Device name too short: '$n'" }
    }

    # Extra safety: prevent accidental large targeting
    if ($Names.Count -gt 50) {
        throw "Refusing to target more than 50 devices in one run (safety limit)."
    }
}

function Get-DeviceIndex {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path $Path)) { throw "Data file not found: $Path" }

    $devices = (Get-Content -Path $Path -Raw | ConvertFrom-Json)
    $index = @{}
    foreach ($d in $devices) { $index[$d.deviceName] = $d }
    return $index
}

Assert-SafeDeviceNames -Names $DeviceNames
$index = Get-DeviceIndex -Path $DataPath

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start targets={0}" -f $DeviceNames.Count)

foreach ($name in $DeviceNames) {
    if (-not $index.ContainsKey($name)) {
        Write-Log -Path $LogPath -Level WARN -RunId $runId -Device $name -Message "Device not found. Skipping."
        continue
    }

    $action = "Apply simulated config to $name"
    if ($PSCmdlet.ShouldProcess($name, $action)) {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $name -Message "APPLY: simulated change"
    } else {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $name -Message "WHATIF: would apply change"
    }
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $LogPath"
