#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$logPath  = Join-Path $here "output\week4.log"

function Get-DevicesFromMock {
    param([string]$Path)
    return (Get-Content -Path $Path -Raw | ConvertFrom-Json)
}

function Get-NonCompliantCompanyWindowsDevices {
    param($Devices)
    return $Devices | Where-Object {
        $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' -and $_.complianceState -eq 'noncompliant'
    }
}

function Invoke-RemediationAction {
    param($Device)
    # Simulated remediation: return a result object
    return [pscustomobject]@{
        deviceName = $Device.deviceName
        action     = 'Simulated remediation'
        result     = 'success'
    }
}

function Write-LogLine {
    param([string]$Path,[string]$Message)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Add-Content -Path $Path -Value ("{0} {1}" -f (Get-Date).ToString("s"), $Message)
}

$devices  = Get-DevicesFromMock -Path $dataPath
$targets  = Get-NonCompliantCompanyWindowsDevices -Devices $devices

Write-LogLine -Path $logPath -Message ("Targets: {0}" -f $targets.Count)

foreach ($t in $targets) {
    $r = Invoke-RemediationAction -Device $t
    Write-LogLine -Path $logPath -Message ("{0}: {1}" -f $r.deviceName, $r.result)
}

Write-Host "Done. See $logPath"
