# MockGraph module

A small PowerShell 5.1-friendly module that simulates Microsoft Graph behavior for training.

## Import
From a week folder:

```powershell
Import-Module ..\common\MockGraph\MockGraph.psd1 -Force
```

## Simulate modes
- `success` – returns JSON from `-DataPath`
- `unauthorized` – throws 401
- `throttle` – throws 429 with Retry-After
- `empty` – returns empty array
- `transient` – throws 503 a configurable number of times before succeeding

## Basic retry wrapper

```powershell
$result = Invoke-WithMockRetry -MaxAttempts 3 -ScriptBlock {
    Invoke-MockGraphRequest -Mode throttle -DataPath .\data\devices.json
}
```
