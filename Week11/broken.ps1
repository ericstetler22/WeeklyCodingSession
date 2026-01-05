# Duplicate filters, hard to change, easy to break
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$data   = Join-Path $here "data\devices.json"
$outDir = Join-Path $here "output"
$out    = Join-Path $outDir "summary.txt"

$d = (Get-Content $data | ConvertFrom-Json)

$w1 = $d | Where-Object { $_.operatingSystem -eq "Windows" -and $_.ownership -eq "Company" }
$w2 = $d | Where-Object { $_.ownership -eq "Company" -and $_.operatingSystem -eq "Windows" } # duplicated

$win10 = $d | Where-Object { $_.operatingSystem -eq "Windows" -and $_.ownership -eq "Company" -and $_.osVersion -like "10.*" }
$win11 = $d | Where-Object { $_.operatingSystem -eq "Windows" -and $_.ownership -eq "Company" -and $_.osVersion -like "11.*" }

if (-not (Test-Path $outDir)) { mkdir $outDir | Out-Null }
@"
Total=$($d.Count)
WindowsCompany=$($w2.Count)
Win10=$($win10.Count)
Win11=$($win11.Count)
"@ | Set-Content $out
"ok"
