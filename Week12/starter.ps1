#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [string]$ConfigPath = ".\config\settings.json",
    [ValidateSet('success','unauthorized','throttle','empty')][string]$Mode = 'success',
    [switch]$DryRun
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFull = Join-Path $here $ConfigPath
$dataPath   = Join-Path $here "data\devices.json"
$logPath    = Join-Path $here "output\capstone.log"
$stateDir   = Join-Path $here "state"

function Invoke-MockGraphRequest {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('success','unauthorized','throttle','empty')][string]$Mode,
        [Parameter(Mandatory=$true)][string]$DataPath
    )

    switch ($Mode) {
        'unauthorized' { throw (New-Object System.UnauthorizedAccessException("401 Unauthorized (simulated)")) }
        'throttle'     { 
            $ex = New-Object System.Exception("429 Too Many Requests (simulated)")
            $ex.Data["status"] = 429
            $ex.Data["retryAfterSeconds"] = 2
            throw $ex
        }
        'empty'        { return @() }
        default        { 
            if (-not (Test-Path $DataPath)) { throw "Data file not found: $DataPath" }
            $raw = Get-Content -Path $DataPath -Raw
            if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
            return ($raw | ConvertFrom-Json)
        }
    }
}

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }

function Log {
    param([ValidateSet('INFO','WARN','ERROR')][string]$Level,[string]$Device,[string]$Message)
    Ensure-Dir (Split-Path -Parent $logPath)
    $line = "{0} [{1}] device={2} {3}" -f (Get-Date).ToString("s"), $Level, ($Device ?? '-'), $Message
    Add-Content -Path $logPath -Value $line
}

function Get-Settings {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
    $cfg = (Get-Content -Path $Path -Raw | ConvertFrom-Json)
    if ([string]::IsNullOrWhiteSpace($cfg.targetOsPrefix)) { throw "Config missing: targetOsPrefix" }
    if ([string]::IsNullOrWhiteSpace($cfg.requiredOwnership)) { throw "Config missing: requiredOwnership" }
    if ($cfg.maxDevices -lt 1 -or $cfg.maxDevices -gt 5000) { throw "Config maxDevices out of range" }
    return $cfg
}

function Get-SettingState {
    param([string]$DeviceName)
    Ensure-Dir $stateDir
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    if (-not (Test-Path $p)) { return $null }
    return (Get-Content -Path $p -Raw | ConvertFrom-Json)
}

function Set-SettingState {
    param([string]$DeviceName,[bool]$Enabled)
    Ensure-Dir $stateDir
    $p = Join-Path $stateDir ("{0}.json" -f $DeviceName)
    @{ deviceName=$DeviceName; settingEnabled=$Enabled; updated=(Get-Date).ToString("s") } |
        ConvertTo-Json | Set-Content -Path $p
}

function Get-Devices {
    param([string]$Mode,[string]$DataPath)
    try {
        return Invoke-MockGraphRequest -Mode $Mode -DataPath $DataPath
    } catch {
        if ($_.Exception.Data.Contains("status") -and $_.Exception.Data["status"] -eq 429) {
            $retry = $_.Exception.Data["retryAfterSeconds"]
            throw "Throttled (429). Retry-After: $retry sec. (simulated)"
        }
        throw
    }
}

function Invoke-Remediation {
    param($Device,[bool]$Desired,[switch]$DryRun)

    $current = Get-SettingState -DeviceName $Device.deviceName
    if ($null -ne $current -and $current.settingEnabled -eq $Desired) {
        Log -Level INFO -Device $Device.deviceName -Message "No change required"
        return
    }

    if ($DryRun) {
        Log -Level INFO -Device $Device.deviceName -Message "DRYRUN: Would apply settingEnabled=$Desired"
        return
    }

    Log -Level INFO -Device $Device.deviceName -Message "Applying settingEnabled=$Desired (simulated)"
    Set-SettingState -DeviceName $Device.deviceName -Enabled $Desired
    Log -Level INFO -Device $Device.deviceName -Message "Applied"
}

$cfg = Get-Settings -Path $configFull
Log -Level INFO -Device '-' -Message ("Run start mode={0} dryRun={1}" -f $Mode, [bool]$DryRun)

$devices = Get-Devices -Mode $Mode -DataPath $dataPath
if ($null -eq $devices -or $devices.Count -eq 0) { throw "No devices returned." }

$targets = $devices | Where-Object {
    $_.operatingSystem -eq 'Windows' -and
    $_.ownership -eq $cfg.requiredOwnership -and
    $_.osVersion -like ("{0}*" -f $cfg.targetOsPrefix)
} | Select-Object -First $cfg.maxDevices

Log -Level INFO -Device '-' -Message ("Targets={0}" -f ($targets | Measure-Object).Count)

foreach ($t in $targets) {
    Invoke-Remediation -Device $t -Desired $true -DryRun:$DryRun
}

Log -Level INFO -Device '-' -Message "Run end"
Write-Host "Done. See $logPath"
