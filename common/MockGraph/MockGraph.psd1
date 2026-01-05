@{
    RootModule        = 'MockGraph.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b9d0b4b9-0b1d-4b86-8d2f-6a6a4af8d0a1'
    Author            = 'Team Training'
    CompanyName       = 'Internal'
    Copyright         = '(c) 2026'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-MockGraphRequest',
        'New-MockGraphError',
        'Test-IsMockGraphThrottle',
        'Get-MockGraphRetryAfterSeconds',
        'Invoke-WithMockRetry'
    )
}
