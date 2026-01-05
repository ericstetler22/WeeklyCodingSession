#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$data    = Join-Path $here "data\devices.json"
$logPath = Join-Path $here "output\remediation.log"

function Ensure-Directory {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

function Write-Log {
    param(
        [string]$Path,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level,
        [string]$DeviceName,
        [string]$Message
    )
    Ensure-Directory -Path $Path
    $line = "{0} [{1}] device={2} {3}" -f (Get-Date).ToString("s"), $Level, ($DeviceName ?? '-'), $Message
    Add-Content -Path $Path -Value $line
}

$devices = (Get-Content -Path $data -Raw | ConvertFrom-Json)
Write-Log -Path $logPath -Level INFO -DeviceName '-' -Message "Run start"

foreach ($d in $devices) {
    if ($d.operatingSystem -ne 'Windows') {
        Write-Log -Path $logPath -Level INFO -DeviceName $d.deviceName -Message "Skip: non-Windows"
        continue
    }

    # Simulated check + action
    Write-Log -Path $logPath -Level INFO -DeviceName $d.deviceName -Message "Check: compliance=$($d.complianceState)"
    Write-Log -Path $logPath -Level INFO -DeviceName $d.deviceName -Message "Action: simulated remediation"
    Write-Log -Path $logPath -Level INFO -DeviceName $d.deviceName -Message "Result: success"
}

Write-Log -Path $logPath -Level INFO -DeviceName '-' -Message "Run end"
Write-Host "Done. See $logPath"
