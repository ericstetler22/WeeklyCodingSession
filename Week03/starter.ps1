#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [ValidateSet('success','unauthorized','throttle','empty')]
    [string]$Mode = 'success'
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$outPath  = Join-Path $here "output\result.txt"

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

function Get-Devices {
    param([string]$Mode,[string]$DataPath)

    try {
        $devices = Invoke-MockGraphRequest -Mode $Mode -DataPath $DataPath
        if ($null -eq $devices -or $devices.Count -eq 0) {
            throw "No devices returned (simulated)."
        }
        return $devices
    }
    catch {
        # Simulated throttling detection
        if ($_.Exception.Data.Contains("status") -and $_.Exception.Data["status"] -eq 429) {
            $retry = $_.Exception.Data["retryAfterSeconds"]
            throw "Graph throttled (429). Retry-After: $retry seconds. (simulated)"
        }
        throw
    }
}

function Write-Output {
    param([string]$Path,[string]$Message)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Message
}

$devices = Get-Devices -Mode $Mode -DataPath $dataPath
Write-Output -Path $outPath -Message ("Fetched {0} devices (simulated)." -f $devices.Count)

Write-Host "Success. See $outPath"
exit 0
