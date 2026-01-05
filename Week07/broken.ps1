# Assumes fields always exist -> throws or logs nonsense
param([string]$InputFile=".\data\devices_bad.json")

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputPath = Join-Path $here $InputFile
$logPath   = Join-Path $here "output\week7.log"

$d = (Get-Content $inputPath | ConvertFrom-Json)

foreach ($x in $d) {
    # will crash if deviceName is null
    Add-Content $logPath ($x.deviceName.ToUpper() + " " + $x.osVersion.Length)
}
"ok"
