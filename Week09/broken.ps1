# DryRun flag exists but ignored (dangerous)
param([switch]$DryRun)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $here "output\week9.log"
if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }

$d = (Get-Content (Join-Path $here "data\devices.json") | ConvertFrom-Json)

foreach ($x in $d) {
    if ($x.operatingSystem -eq "Windows") {
        Add-Content $logPath ("changed " + $x.deviceName) # always changes
    }
}
"ok"
