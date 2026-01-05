# Capstone intentionally unsafe: no validation, ignores dry-run, swallows failures
param([string]$ConfigPath=".\config\settings.json",[string]$Mode="success",[switch]$DryRun)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath  = Join-Path $here "output\capstone.log"
$dataPath = Join-Path $here "data\devices.json"
$stateDir = Join-Path $here "state"

if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }
if (-not (Test-Path $stateDir)) { mkdir $stateDir | Out-Null }

function Invoke-MockGraphRequest { param($Mode,$DataPath)
    if ($Mode -eq "unauthorized") { throw "401" }
    if ($Mode -eq "throttle") { throw "429" }
    if ($Mode -eq "empty") { return @() }
    return (Get-Content $DataPath | ConvertFrom-Json)
}

try { $devices = Invoke-MockGraphRequest $Mode $dataPath } catch { $devices = @() } # swallow

foreach ($d in $devices) {
    if ($d.operatingSystem -eq "Windows") {
        # ignores dry run and desired state checks
        $p = Join-Path $stateDir ($d.deviceName + ".json")
        "{""deviceName"":""$($d.deviceName)"",""settingEnabled"":true}" | Set-Content $p
        Add-Content $logPath ("changed " + $d.deviceName)
    }
}
"ok"
