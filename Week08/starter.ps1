#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param([ValidateSet('success','unauthorized','throttle','empty')][string]$Mode='success')

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$logPath  = Join-Path $here "output\week8.log"

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

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Log { param([string]$Msg) Ensure-Dir (Split-Path -Parent $logPath); Add-Content $logPath ("{0} {1}" -f (Get-Date).ToString("s"), $Msg) }

function Get-DevicesViaGraphLayer {
    param([string]$Mode,[string]$DataPath)

    try {
        return Invoke-MockGraphRequest -Mode $Mode -DataPath $DataPath
    }
    catch {
        Log ("ERROR: {0}" -f $_.Exception.Message)
        throw
    }
}

Log "Run start: mode=$Mode"
$devices = Get-DevicesViaGraphLayer -Mode $Mode -DataPath $dataPath
Log ("Returned {0} devices" -f ($devices | Measure-Object).Count)
Log "Run end"
Write-Host "Done. See $logPath"
