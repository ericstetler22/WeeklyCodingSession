# Hardcoded values everywhere; config file ignored
param([string]$ConfigPath=".\config\settings.json")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $here "output\week10.log"
if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }

$d = (Get-Content (Join-Path $here "data\devices.json") | ConvertFrom-Json)
# magic: always Windows 10, always first 999
$t = $d | Where-Object { $_.operatingSystem -eq "Windows" -and $_.osVersion -like "10.*" } | Select-Object -First 999
Add-Content $logPath ("targets=" + $t.Count)
"ok"
