# No timestamps, no context, hard to troubleshoot
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$data    = Join-Path $here "data\devices.json"
$logPath = Join-Path $here "output\remediation.log"

$d = (Get-Content $data | ConvertFrom-Json)

if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }
Add-Content $logPath "start"

foreach ($x in $d) {
    if ($x.operatingSystem -eq "Windows") {
        Add-Content $logPath "doing thing"
        Add-Content $logPath "success"
    }
}

Add-Content $logPath "end"
"ok"
