#requires -Version 3.0
<#
.SYNOPSIS
Single-responsibility remediation flow: query -> decide -> act -> log.

.DESCRIPTION
Shows a simple but production-aligned structure for desktop remediation scripts.
#>
[CmdletBinding()]
param(
    [string]$DataPath = (Join-Path $PSScriptRoot "data\devices.json"),
    [string]$LogPath  = (Join-Path $PSScriptRoot "output\week4.log")
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

$runId = New-RunId

function Get-Devices {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Data file not found: $Path" }
    return (Get-Content -Path $Path -Raw | ConvertFrom-Json)
}

function Select-Targets {
    param($Devices)
    # Decision only: pick devices that match the criteria
    return $Devices | Where-Object {
        $_.operatingSystem -eq 'Windows' -and
        $_.ownership -eq 'Company' -and
        $_.complianceState -eq 'noncompliant'
    }
}

function Invoke-Remediation {
    param($Device)
    # Action only (simulated): returns a result object
    return [pscustomobject]@{
        deviceName = $Device.deviceName
        action     = 'Simulated remediation'
        result     = 'success'
    }
}

$devices = Get-Devices -Path $DataPath
$targets = Select-Targets -Devices $devices

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message ("Run start targets={0}" -f ($targets | Measure-Object).Count)

foreach ($t in $targets) {
    $result = Invoke-Remediation -Device $t
    Write-Log -Path $LogPath -Level INFO -RunId $runId -Device $result.deviceName -Message ("action='{0}' result={1}" -f $result.action, $result.result)
}

Write-Log -Path $LogPath -Level INFO -RunId $runId -Device '-' -Message "Run end"
Write-Host "Done. See $LogPath"
