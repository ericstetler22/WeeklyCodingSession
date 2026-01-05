# Intentionally misleading: swallows errors, prints success even when broken
param([string]$Mode="success")

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $here "data\devices.json"
$outPath  = Join-Path $here "output\result.txt"

function Invoke-MockGraphRequest { param($Mode,$DataPath)
    if ($Mode -eq "unauthorized") { throw "401" }
    if ($Mode -eq "throttle") { throw "429" }
    if ($Mode -eq "empty") { return @() }
    return (Get-Content $DataPath | ConvertFrom-Json)
}

try {
    $d = Invoke-MockGraphRequest $Mode $dataPath
} catch {
    # swallow
    $d = @()
}

# always says success
if (-not (Test-Path (Split-Path $outPath -Parent))) { mkdir (Split-Path $outPath -Parent) | Out-Null }
Set-Content $outPath ("Fetched {0} devices" -f $d.Count)
"SUCCESS"
exit 0
