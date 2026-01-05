# Intentionally mixed concerns: query, decide, act, log all in one tangled loop
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$logPath  = Join-Path $here "output\week4.log"

$d = (Get-Content $dataPath | ConvertFrom-Json)

if (-not (Test-Path (Split-Path $logPath -Parent))) { mkdir (Split-Path $logPath -Parent) | Out-Null }
Add-Content $logPath ("start " + (Get-Date))

foreach ($x in $d) {
    if ($x.operatingSystem -eq "Windows") {
        if ($x.ownership -eq "Company") {
            if ($x.complianceState -eq "noncompliant") {
                # remediation inline
                Add-Content $logPath ("fixing " + $x.deviceName)
                # pretend success
                Add-Content $logPath ("fixed " + $x.deviceName)
            }
        }
    }
}

Add-Content $logPath ("end " + (Get-Date))
"ok"
