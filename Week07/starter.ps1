#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param([string]$InputFile = ".\data\devices_bad.json")

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputPath = Join-Path $here $InputFile
$logPath   = Join-Path $here "output\week7.log"

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Log { param([string]$Msg) Ensure-Dir (Split-Path -Parent $logPath); Add-Content $logPath ("{0} {1}" -f (Get-Date).ToString("s"), $Msg) }

function Validate-Device {
    param($Device)
    if ($null -eq $Device.id) { return "missing id" }
    if ([string]::IsNullOrWhiteSpace($Device.deviceName)) { return "missing deviceName" }
    if ([string]::IsNullOrWhiteSpace($Device.operatingSystem)) { return "missing operatingSystem" }
    if ([string]::IsNullOrWhiteSpace($Device.osVersion)) { return "missing osVersion" }
    return $null
}

$devices = (Get-Content -Path $inputPath -Raw | ConvertFrom-Json)
Log "Run start: input=$InputFile"

foreach ($d in $devices) {
    $err = Validate-Device -Device $d
    if ($null -ne $err) {
        Log ("SKIP: {0} ({1})" -f ($d.id ?? "<no id>"), $err)
        continue
    }

    Log ("OK: {0} os={1} {2}" -f $d.deviceName, $d.operatingSystem, $d.osVersion)
}

Log "Run end"
Write-Host "Done. See $logPath"
