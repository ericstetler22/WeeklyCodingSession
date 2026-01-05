# MockGraph.psm1
# PowerShell 5.1-friendly mock layer to simulate Microsoft Graph / Intune behavior locally.
# Intended for training and safe experimentation.

Set-StrictMode -Version Latest

function New-MockGraphError {
    param(
        [Parameter(Mandatory=$true)][int]$StatusCode,
        [Parameter(Mandatory=$true)][string]$Message,
        [int]$RetryAfterSeconds = 0
    )

    $ex = New-Object System.Exception($Message)
    $ex.Data["status"] = $StatusCode
    if ($RetryAfterSeconds -gt 0) {
        $ex.Data["retryAfterSeconds"] = $RetryAfterSeconds
    }
    return $ex
}

function Invoke-MockGraphRequest {
    <#
    .SYNOPSIS
    Simulates a Graph request.

    .PARAMETER Mode
    One of: success, unauthorized, throttle, empty, transient

    .PARAMETER DataPath
    Path to a JSON file to return on success.

    .PARAMETER TransientFailures
    For Mode=transient, number of times to throw a 503 before succeeding.

    .EXAMPLE
    Invoke-MockGraphRequest -Mode throttle -DataPath .\data\devices.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('success','unauthorized','throttle','empty','transient')]
        [string]$Mode,

        [Parameter(Mandatory=$true)]
        [string]$DataPath,

        [int]$TransientFailures = 1
    )

    switch ($Mode) {
        'unauthorized' {
            throw (New-MockGraphError -StatusCode 401 -Message "401 Unauthorized (simulated)")
        }
        'throttle' {
            throw (New-MockGraphError -StatusCode 429 -Message "429 Too Many Requests (simulated)" -RetryAfterSeconds 2)
        }
        'empty' {
            return @()
        }
        'transient' {
            if (-not $script:__MockGraphTransientCount) { $script:__MockGraphTransientCount = 0 }
            if ($script:__MockGraphTransientCount -lt $TransientFailures) {
                $script:__MockGraphTransientCount++
                throw (New-MockGraphError -StatusCode 503 -Message "503 Service Unavailable (simulated)")
            }
            # fall through to success
        }
    }

    if (-not (Test-Path $DataPath)) {
        throw (New-MockGraphError -StatusCode 404 -Message ("404 Not Found (simulated): {0}" -f $DataPath))
    }

    $raw = Get-Content -Path $DataPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    return ($raw | ConvertFrom-Json)
}

function Test-IsMockGraphThrottle {
    param([Parameter(Mandatory=$true)]$ErrorRecord)
    try {
        return ($ErrorRecord.Exception.Data.Contains("status") -and $ErrorRecord.Exception.Data["status"] -eq 429)
    } catch { return $false }
}

function Get-MockGraphRetryAfterSeconds {
    param([Parameter(Mandatory=$true)]$ErrorRecord)
    try {
        if ($ErrorRecord.Exception.Data.Contains("retryAfterSeconds")) {
            return [int]$ErrorRecord.Exception.Data["retryAfterSeconds"]
        }
    } catch {}
    return 0
}

function Invoke-WithMockRetry {
    <#
    .SYNOPSIS
    Basic retry wrapper (useful for teaching throttling/retry patterns).

    .PARAMETER ScriptBlock
    The operation to run.

    .PARAMETER MaxAttempts
    Total attempts including the first try.

    .PARAMETER BaseDelaySeconds
    Delay used when no Retry-After is available.

    .EXAMPLE
    Invoke-WithMockRetry -MaxAttempts 3 -ScriptBlock { Invoke-MockGraphRequest -Mode throttle -DataPath .\data\devices.json }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [int]$MaxAttempts = 3,
        [int]$BaseDelaySeconds = 1
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return & $ScriptBlock
        }
        catch {
            $isLast = ($attempt -eq $MaxAttempts)
            if ($isLast) { throw }

            if (Test-IsMockGraphThrottle -ErrorRecord $_) {
                $retryAfter = Get-MockGraphRetryAfterSeconds -ErrorRecord $_
                if ($retryAfter -le 0) { $retryAfter = $BaseDelaySeconds }
                Start-Sleep -Seconds $retryAfter
                continue
            }

            # For other errors, simple backoff
            Start-Sleep -Seconds $BaseDelaySeconds
        }
    }
}

Export-ModuleMember -Function `
    Invoke-MockGraphRequest, `
    New-MockGraphError, `
    Test-IsMockGraphThrottle, `
    Get-MockGraphRetryAfterSeconds, `
    Invoke-WithMockRetry
