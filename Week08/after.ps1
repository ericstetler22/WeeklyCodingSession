#requires -Version 3.0
<#
.SYNOPSIS
Centralizes Graph behavior behind a single layer.

.DESCRIPTION
Imports MockGraph and exposes one function for device retrieval so scripts don't duplicate API handling.
#>
[CmdletBinding()]
param(
    [ValidateSet('success','unauthorized','throttle','empty','transient')]
    [string]$Mode = 'success',

    [string]$LogPath = (Join-Path $PSScriptRoot "output\week8.log")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot "..\common\MockGraph\MockGraph.psd1"
Import-Module $modulePath -Force
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

function Get-DevicesFromGraphLayer {
    param([string]$Mode,[string]$Path)

    return Invoke-WithMockRetry -MaxAttempts 3 -ScriptBlock {
        Invoke-MockGraphRequest -Mode $Mode -DataPath $Path -TransientFailures 1
    }
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start mode={0}" -f $Mode)

try {
    $devices = Get-DevicesFromGraphLayer -Mode $Mode -Path $dataPath
    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Returned {0} devices" -f ($devices | Measure-Object).Count)
    Write-Host "Done. See $LogPath"
}
catch {
    Write-Log -Path $LogPath -Level ERROR -RunId $runId -Device '-' -Message ("FAILED: {0}" -f $_.Exception.Message)
    throw
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
