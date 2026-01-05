#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param([string]$ConfigPath = ".\config\settings.json")

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFull = Join-Path $here $ConfigPath
$logPath    = Join-Path $here "output\week10.log"

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Log { param([string]$Msg) Ensure-Dir (Split-Path -Parent $logPath); Add-Content $logPath ("{0} {1}" -f (Get-Date).ToString("s"), $Msg) }

function Get-Settings {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
    $cfg = (Get-Content -Path $Path -Raw | ConvertFrom-Json)

    if ([string]::IsNullOrWhiteSpace($cfg.targetOsPrefix)) { throw "Config missing: targetOsPrefix" }
    if ($cfg.maxDevices -lt 1 -or $cfg.maxDevices -gt 5000) { throw "Config maxDevices out of range" }

    return $cfg
}

$cfg = Get-Settings -Path $configFull
Log ("Loaded config: targetOsPrefix={0} maxDevices={1}" -f $cfg.targetOsPrefix, $cfg.maxDevices)

$devices = (Get-Content -Path (Join-Path $here "data\devices.json") -Raw | ConvertFrom-Json)
$targets = $devices | Where-Object { $_.operatingSystem -eq 'Windows' -and $_.osVersion -like ("{0}*" -f $cfg.targetOsPrefix) } | Select-Object -First $cfg.maxDevices

Log ("Targets: {0}" -f ($targets | Measure-Object).Count)
Write-Host "Done. See $logPath"
