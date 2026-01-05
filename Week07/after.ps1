#requires -Version 3.0
<#
.SYNOPSIS
Validates untrusted device data.

.DESCRIPTION
Shows a predictable policy: skip bad records with logged reasons, and summarize outcomes.
#>
[CmdletBinding()]
param(
    [string]$InputFile = ".\data\devices_bad.json",
    [string]$LogPath   = (Join-Path $PSScriptRoot "output\week7.log")
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
$inputPath = Join-Path $PSScriptRoot $InputFile

function Validate-Device {
    param($Device)

    $problems = @()
    if ($null -eq $Device.id) { $problems += "missing id" }
    if ([string]::IsNullOrWhiteSpace($Device.deviceName)) { $problems += "missing deviceName" }
    if ([string]::IsNullOrWhiteSpace($Device.operatingSystem)) { $problems += "missing operatingSystem" }
    if ([string]::IsNullOrWhiteSpace($Device.osVersion)) { $problems += "missing osVersion" }

    return $problems
}

if (-not (Test-Path $inputPath)) { throw "Input file not found: $inputPath" }

$devices = (Get-Content -Path $inputPath -Raw | ConvertFrom-Json)

$ok = 0; $skipped = 0
Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start input={0}" -f $InputFile)

foreach ($d in $devices) {
    $problems = Validate-Device -Device $d
    if ($problems.Count -gt 0) {
        $skipped++
        Write-Log -Path $LogPath -Level WARN -RunId $runId -Device ($d.deviceName ?? '<unknown>') -Message ("Skip: {0}" -f ($problems -join "; "))
        continue
    }

    $ok++
    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message ("OK: os={0} {1}" -f $d.operatingSystem, $d.osVersion)
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run end ok={0} skipped={1}" -f $ok, $skipped)
Write-Host "Done. See $LogPath"
