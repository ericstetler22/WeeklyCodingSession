#requires -Version 3.0
<#
.SYNOPSIS
Logging that supports incident response.

.DESCRIPTION
Demonstrates structured, contextual logs with a run id and per-device outcomes.
#>
[CmdletBinding()]
param(
    [string]$DataPath = (Join-Path $PSScriptRoot "data\devices.json"),
    [string]$LogPath  = (Join-Path $PSScriptRoot "output\remediation.log")
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

function Get-Devices {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Data file not found: $Path" }
    return (Get-Content -Path $Path -Raw | ConvertFrom-Json)
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run start"

$devices = Get-Devices -Path $DataPath
foreach ($d in $devices) {
    if ($d.operatingSystem -ne 'Windows') {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message "Skip: non-Windows"
        continue
    }

    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message ("Check: ownership={0} compliance={1}" -f $d.ownership, $d.complianceState)

    # Simulated remediation decision
    if ($d.ownership -ne 'Company') {
        Write-Log -Path $LogPath -Level WARN -RunId $runId -Device $d.deviceName -Message "Skip: not company-owned"
        continue
    }

    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message "Action: simulated remediation"
    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message "Result: success"
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $LogPath"
