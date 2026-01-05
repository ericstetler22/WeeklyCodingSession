# Always applies change, every run, no check (non-idempotent)
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $here "state"
$logPath  = Join-Path $here "output\week6.log"

if (-not (Test-Path $stateDir)) { mkdir $stateDir | Out-Null }
if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }

$d = (Get-Content (Join-Path $here "data\devices.json") | ConvertFrom-Json)

foreach ($x in $d) {
    if ($x.operatingSystem -eq "Windows") {
        # always write, even if already set
        $p = Join-Path $stateDir ($x.deviceName + ".json")
        "{""deviceName"":""$($x.deviceName)"",""settingEnabled"":true}" | Set-Content $p
        Add-Content $logPath ("set " + $x.deviceName)
    }
}
"ok"
