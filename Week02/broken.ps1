# Intentionally unsafe: wildcard allowed, empty input allowed, no device existence checks
param([string[]]$DeviceNames)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$logPath  = Join-Path $here "output\actions.log"

$devices = (Get-Content $dataPath | ConvertFrom-Json)

foreach ($n in $DeviceNames) {
    # if DeviceNames is empty, loop does nothing but exits "success"
    Add-Content $logPath ("{0} changing {1}" -f (Get-Date), $n)

    # wildcard or partial matches cause mass impact
    $targets = $devices | Where-Object { $_.deviceName -like $n }
    foreach ($t in $targets) {
        Add-Content $logPath ("changed {0}" -f $t.deviceName)
    }
}

"ok"
