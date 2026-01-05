#requires -Version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$data   = Join-Path $here "data\devices.json"
$outDir = Join-Path $here "output"
$out    = Join-Path $outDir "summary.txt"

function Ensure-Dir { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }

function Get-DeviceSummary {
    param($Devices)

    $windowsCompany = $Devices | Where-Object { $_.operatingSystem -eq 'Windows' -and $_.ownership -eq 'Company' }
    $win10 = $windowsCompany | Where-Object { $_.osVersion -like '10.*' }
    $win11 = $windowsCompany | Where-Object { $_.osVersion -like '11.*' }

    return [pscustomobject]@{
        TotalDevices       = $Devices.Count
        WindowsCompany     = $windowsCompany.Count
        Windows10Company   = $win10.Count
        Windows11Company   = $win11.Count
        NonCompliantWinCo  = ($windowsCompany | Where-Object { $_.complianceState -eq 'noncompliant' }).Count
    }
}

$devices = (Get-Content -Path $data -Raw | ConvertFrom-Json)
$summary = Get-DeviceSummary -Devices $devices

Ensure-Dir -Path $outDir
$summary | Format-List | Out-String | Set-Content -Path $out
Write-Host "Wrote summary to $out"
