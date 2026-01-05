#requires -Version 3.0
<#
.SYNOPSIS
Capstone: Intune-style remediation (simulated).

.DESCRIPTION
Combines: config-over-code, mocked Graph calls, validation, idempotency, logging,
dry-run/what-if safety, and fail-fast error handling.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$ConfigPath = ".\config\settings.json",
    [ValidateSet('success','unauthorized','throttle','empty','transient')]
    [string]$Mode = 'success',
    [switch]$DryRun
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

$configFull = Join-Path $PSScriptRoot $ConfigPath
$dataPath   = Join-Path $PSScriptRoot "data\devices.json"
$logPath    = Join-Path $PSScriptRoot "output\capstone.log"
$stateDir   = Join-Path $PSScriptRoot "state"

function Get-Settings {
    param([string]$Path)

    if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
    $cfg = (Get-Content -Path $Path -Raw | ConvertFrom-Json)

    if ([string]::IsNullOrWhiteSpace($cfg.targetOsPrefix))     { throw "Config missing: targetOsPrefix" }
    if ([string]::IsNullOrWhiteSpace($cfg.requiredOwnership)) { throw "Config missing: requiredOwnership" }
    if ($cfg.maxDevices -lt 1 -or $cfg.maxDevices -gt 5000) { throw "Config maxDevices out of range (1..5000)" }

    return $cfg
}

function Get-Devices {
    param([string]$Mode,[string]$Path)

    $devices = Invoke-WithMockRetry -MaxAttempts 3 -ScriptBlock {
        Invoke-MockGraphRequest -Mode $Mode -DataPath $Path -TransientFailures 1
    }

    if ($null -eq $devices -or $devices.Count -eq 0) { throw "No devices returned." }
    return $devices
}

function Get-SettingState {
    param([string]$DeviceName)
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir | Out-Null }
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    if (-not (Test-Path $p)) { return $null }
    return (Get-Content -Path $p -Raw | ConvertFrom-Json)
}

function Set-SettingState {
    param([string]$DeviceName,[bool]$Enabled)
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir | Out-Null }
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    @{ deviceName=$DeviceName; settingEnabled=$Enabled; updated=(Get-Date).ToString("s") } |
        ConvertTo-Json | Set-Content -Path $p
}

function Invoke-Remediation {
    param($Device,[bool]$Desired,[switch]$DryRun)

    $current = Get-SettingState -DeviceName $Device.deviceName
    if ($null -ne $current -and $current.settingEnabled -eq $Desired) {
        Write-Log -Path $logPath -Level INFO -RunId $runId -Device $Device.deviceName -Message "No change required"
        return
    }

    if ($DryRun) {
        Write-Log -Path $logPath -Level INFO -RunId $runId -Device $Device.deviceName -Message ("DRYRUN: Would set settingEnabled={0}" -f $Desired)
        return
    }

    $action = "Set settingEnabled=$Desired (simulated)"
    if ($PSCmdlet.ShouldProcess($Device.deviceName, $action)) {
        Write-Log -Path $logPath -Level INFO -RunId $runId -Device $Device.deviceName -Message $action
        Set-SettingState -DeviceName $Device.deviceName -Enabled $Desired
        Write-Log -Path $logPath -Level INFO -RunId $runId -Device $Device.deviceName -Message "Applied"
    } else {
        Write-Log -Path $logPath -Level INFO -RunId $runId -Device $Device.deviceName -Message "WHATIF: would apply change"
    }
}

$cfg = Get-Settings -Path $configFull

Write-Log -Path $logPath -Level INFO -RunId $runId -Device '-' -Message ("Run start mode={0} dryRun={1}" -f $Mode, [bool]$DryRun)
Write-Log -Path $logPath -Level INFO -RunId $runId -Device '-' -Message ("Config osPrefix={0} ownership={1} max={2}" -f $cfg.targetOsPrefix, $cfg.requiredOwnership, $cfg.maxDevices)

$devices = Get-Devices -Mode $Mode -Path $dataPath

$pattern = "{0}*" -f $cfg.targetOsPrefix
$targets = $devices | Where-Object {
    $_.operatingSystem -eq 'Windows' -and
    $_.ownership -eq $cfg.requiredOwnership -and
    $_.osVersion -like $pattern
} | Select-Object -First $cfg.maxDevices

Write-Log -Path $logPath -Level INFO -RunId $runId -Device '-' -Message ("Targets={0}" -f ($targets | Measure-Object).Count)

foreach ($t in $targets) {
    Invoke-Remediation -Device $t -Desired $true -DryRun:$DryRun
}

Write-Log -Path $logPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $logPath"
