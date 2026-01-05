# Intentionally messy: unclear names, magic values, hard to read
$h = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = "$h\data\devices.json"
$o = "$h\output\win10_devices.csv"

# no strict mode, no error preference, no validation
$d = (Get-Content $p | ConvertFrom-Json) # not -Raw, slower and fragile

$r = @()
foreach ($x in $d) {
    if ($x.operatingSystem -eq "Windows") {
        if ($x.osVersion -like "10.*") {
            $r += $x # building array inefficiently
        } else {
            # do nothing
        }
    }
}

if (-not (Test-Path "$h\output")) { mkdir "$h\output" | Out-Null }

$r | Select id, deviceName, osVersion, ownership, complianceState, lastSyncDateTime | Export-Csv $o -NoTypeInformation
"done"
