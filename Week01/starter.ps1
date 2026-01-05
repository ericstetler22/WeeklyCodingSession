#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputPath  = Join-Path $here "data\devices.json"
$outDir     = Join-Path $here "output"
$outCsv     = Join-Path $outDir "win10_devices.csv"

function Get-DevicesFromJson {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Input file not found: $Path" }
    $raw = Get-Content -Path $Path -Raw
    return ($raw | ConvertFrom-Json)
}

function Get-Windows10Devices {
    param([Parameter(Mandatory=$true)]$Devices)
    # "Windows 10" is simulated by osVersion starting with "10."
    return $Devices | Where-Object { $_.operatingSystem -eq 'Windows' -and ($_.osVersion -like '10.*') }
}

function Export-DeviceReportCsv {
    param(
        [Parameter(Mandatory=$true)]$Devices,
        [Parameter(Mandatory=$true)][string]$Path
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    $Devices | Select-Object id, deviceName, osVersion, ownership, complianceState, lastSyncDateTime |
        Export-Csv -Path $Path -NoTypeInformation
}

$devices = Get-DevicesFromJson -Path $inputPath
$win10   = Get-Windows10Devices -Devices $devices
Export-DeviceReportCsv -Devices $win10 -Path $outCsv

Write-Host ("Wrote {0} rows to {1}" -f ($win10 | Measure-Object).Count, $outCsv)
