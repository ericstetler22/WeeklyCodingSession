#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param([switch]$DryRun)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $here "output\week9.log"

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Log { param([string]$Msg) Ensure-Dir (Split-Path -Parent $logPath); Add-Content $logPath ("{0} {1}" -f (Get-Date).ToString("s"), $Msg) }

function Invoke-SimulatedChange {
    param([string]$DeviceName,[switch]$DryRun)
    if ($DryRun) {
        Log ("DRYRUN: Would apply change to {0}" -f $DeviceName)
        return
    }
    Log ("APPLY: Applying change to {0} (simulated)" -f $DeviceName)
}

$devices = (Get-Content -Path (Join-Path $here "data\devices.json") -Raw | ConvertFrom-Json)
Log ("Run start dryRun={0}" -f [bool]$DryRun)

foreach ($d in $devices | Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }) {
    Invoke-SimulatedChange -DeviceName $d.deviceName -DryRun:$DryRun
}

Log "Run end"
Write-Host "Done. See $logPath"
