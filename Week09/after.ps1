#requires -Version 3.0
<#
.SYNOPSIS
Demonstrates DryRun and -WhatIf behavior for safe changes.

.DESCRIPTION
Uses SupportsShouldProcess so both -DryRun and -WhatIf are meaningful.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$DryRun,
    [string]$LogPath = (Join-Path $PSScriptRoot "output\week9.log")
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
$dataPath = Join-Path $PSScriptRoot "data\devices.json"

function Invoke-SimulatedChange {
    param([string]$DeviceName,[switch]$DryRun)

    $action = "Apply simulated change"
    if ($DryRun) {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $DeviceName -Message "DRYRUN: would apply change"
        return
    }

    if ($PSCmdlet.ShouldProcess($DeviceName, $action)) {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $DeviceName -Message "APPLY: simulated change"
    } else {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $DeviceName -Message "WHATIF: would apply change"
    }
}

$devices = (Get-Content -Path $dataPath -Raw | ConvertFrom-Json) |
    Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start dryRun={0}" -f [bool]$DryRun)

foreach ($d in $devices) {
    Invoke-SimulatedChange -DeviceName $d.deviceName -DryRun:$DryRun
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $LogPath"
