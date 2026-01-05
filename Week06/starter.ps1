#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $here "state"
$logPath  = Join-Path $here "output\week6.log"

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Write-Log { param([string]$Msg) Ensure-Dir (Split-Path -Parent $logPath); Add-Content $logPath ("{0} {1}" -f (Get-Date).ToString("s"), $Msg) }

# Simulated per-device registry state stored in files (so it's safe)
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

$devices = (Get-Content -Path (Join-Path $here "data\devices.json") -Raw | ConvertFrom-Json)
Write-Log "Run start"

foreach ($d in $devices | Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }) {
    $desired = $true
    $current = Get-SettingState -DeviceName $d.deviceName

    if ($null -ne $current -and $current.settingEnabled -eq $desired) {
        Write-Log ("{0}: no change required" -f $d.deviceName)
        continue
    }

    Write-Log ("{0}: applying change (simulated)" -f $d.deviceName)
    Set-SettingState -DeviceName $d.deviceName -Enabled $desired
    Write-Log ("{0}: applied" -f $d.deviceName)
}

Write-Log "Run end"
Write-Host "Done. See $logPath"
