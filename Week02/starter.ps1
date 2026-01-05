#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [Parameter(Mandatory=$true)]
    [string[]]$DeviceNames
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$logPath  = Join-Path $here "output\actions.log"

function Assert-SafeDeviceNames {
    param([Parameter(Mandatory=$true)][string[]]$Names)

    if ($Names.Count -eq 0) { throw "No device names provided." }

    foreach ($n in $Names) {
        if ([string]::IsNullOrWhiteSpace($n)) { throw "Device name cannot be empty." }
        if ($n -match '^\*$' -or $n -match '\*') { throw "Wildcards are not allowed: '$n'" }
        if ($n.Length -lt 5) { throw "Device name too short: '$n'" }
    }
}

function Get-DeviceIndex {
    param([Parameter(Mandatory=$true)][string]$Path)
    $devices = (Get-Content -Path $Path -Raw | ConvertFrom-Json)
    $index = @{}
    foreach ($d in $devices) { $index[$d.deviceName] = $d }
    return $index
}

function Write-Log {
    param([string]$Message)
    $dir = Split-Path -Parent $logPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $line = "{0} {1}" -f (Get-Date).ToString("s"), $Message
    Add-Content -Path $logPath -Value $line
}

Assert-SafeDeviceNames -Names $DeviceNames
$deviceIndex = Get-DeviceIndex -Path $dataPath

foreach ($name in $DeviceNames) {
    if (-not $deviceIndex.ContainsKey($name)) {
        Write-Log "SKIP: Device not found: $name"
        continue
    }

    # Simulated change
    Write-Log "APPLY: Would apply configuration to $name"
}

Write-Host "Done. See $logPath"
