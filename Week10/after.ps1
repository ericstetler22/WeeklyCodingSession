#requires -Version 3.0
<#
.SYNOPSIS
Loads validated config to drive script behavior.

.DESCRIPTION
Demonstrates config-over-code with strict validation and safe defaults.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = ".\config\settings.json",
    [string]$LogPath    = (Join-Path $PSScriptRoot "output\week10.log")
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
$configFull = Join-Path $PSScriptRoot $ConfigPath
$dataPath   = Join-Path $PSScriptRoot "data\devices.json"

function Get-Settings {
    param([string]$Path)

    if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
    $cfg = (Get-Content -Path $Path -Raw | ConvertFrom-Json)

    # Required fields
    if ([string]::IsNullOrWhiteSpace($cfg.targetOsPrefix))     { throw "Config missing: targetOsPrefix" }
    if ([string]::IsNullOrWhiteSpace($cfg.requiredOwnership)) { throw "Config missing: requiredOwnership" }

    # Ranges / safety
    if ($cfg.maxDevices -lt 1 -or $cfg.maxDevices -gt 5000) { throw "Config maxDevices out of range (1..5000)" }

    return $cfg
}

$cfg = Get-Settings -Path $configFull
Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Loaded config osPrefix={0} ownership={1} max={2}" -f $cfg.targetOsPrefix, $cfg.requiredOwnership, $cfg.maxDevices)

$devices = (Get-Content -Path $dataPath -Raw | ConvertFrom-Json)
$pattern = "{0}*" -f $cfg.targetOsPrefix

$targets = $devices | Where-Object {
    $_.operatingSystem -eq 'Windows' -and
    $_.ownership -eq $cfg.requiredOwnership -and
    $_.osVersion -like $pattern
} | Select-Object -First $cfg.maxDevices

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Targets={0}" -f ($targets | Measure-Object).Count)
Write-Host "Done. See $LogPath"
