#requires -Version 3.0
<#
.SYNOPSIS
Idempotent remediation simulation.

.DESCRIPTION
Uses a local JSON state file per device to simulate a registry/setting state.
Only applies changes when needed (safe to re-run).
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [bool]$DesiredSettingEnabled = $true,
    [string]$LogPath = (Join-Path $PSScriptRoot "output\week6.log")
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

$runId   = New-RunId
$stateDir = Join-Path $PSScriptRoot "state"
$dataPath = Join-Path $PSScriptRoot "data\devices.json"

function Get-SettingState {
    param([Parameter(Mandatory=$true)][string]$DeviceName)
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir | Out-Null }
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    if (-not (Test-Path $p)) { return $null }
    return (Get-Content -Path $p -Raw | ConvertFrom-Json)
}

function Set-SettingState {
    param([Parameter(Mandatory=$true)][string]$DeviceName,[Parameter(Mandatory=$true)][bool]$Enabled)
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir | Out-Null }
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    @{ deviceName=$DeviceName; settingEnabled=$Enabled; updated=(Get-Date).ToString("s") } |
        ConvertTo-Json | Set-Content -Path $p
}

$devices = (Get-Content -Path $dataPath -Raw | ConvertFrom-Json) |
    Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start dryRun={0} desired={1}" -f [bool]$DryRun, $DesiredSettingEnabled)

foreach ($d in $devices) {
    $current = Get-SettingState -DeviceName $d.deviceName
    if ($null -ne $current -and $current.settingEnabled -eq $DesiredSettingEnabled) {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message "No change required"
        continue
    }

    if ($DryRun) {
        Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message ("DRYRUN: Would set settingEnabled={0}" -f $DesiredSettingEnabled)
        continue
    }

    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message ("Applying settingEnabled={0} (simulated)" -f $DesiredSettingEnabled)
    Set-SettingState -DeviceName $d.deviceName -Enabled $DesiredSettingEnabled
    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $d.deviceName -Message "Applied"
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $LogPath"
