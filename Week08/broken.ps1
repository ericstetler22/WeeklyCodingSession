# No abstraction: Graph behavior scattered everywhere, inconsistent handling
param([string]$Mode="success")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"

if ($Mode -eq "unauthorized") { "401"; exit 0 }
if ($Mode -eq "throttle") { "429"; exit 0 }
if ($Mode -eq "empty") { @(); exit 0 }

(Get-Content $dataPath | ConvertFrom-Json) | Out-Null
"ok"
