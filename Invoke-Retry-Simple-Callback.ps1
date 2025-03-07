function Invoke-Retry {
    param (
        [Parameter(Position = 0, Mandatory)]
        [scriptblock]$ScriptBlock,

        [scriptblock]$RetryCallback = $null,

        [ValidateRange(1, 100)]
        [int]$MaxRetries = 3,

        [ValidateRange(1, 3600)]
        [int]$DelaySeconds = 5
    )

    try {
        & $ScriptBlock
        return
    }
    catch {
        for ($attemptCount = 2; $attemptCount -le $MaxRetries; $attemptCount++) {
            Write-Warning "Operation failed, waiting $DelaySeconds seconds before retry (Attempt $attemptCount/$MaxRetries)"
            Start-Sleep -Seconds $DelaySeconds

            if ($RetryCallback) { & $RetryCallback }

            try {
                & $ScriptBlock
                return
            }
            catch {
                if ($attemptCount -eq $MaxRetries) {
                    Write-Error "Maximum retry attempts ($MaxRetries) reached"
                    return
                }
            }
        }
    }
}

# 使用範例
# Invoke-Retry { 
#     Get-Content "non-existing-file.txt"
# } -RetryCallback {
#     Write-Host "Preparing for retry..."
# } -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop
