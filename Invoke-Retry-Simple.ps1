function Invoke-Retry {
    param (
        [Parameter(Position = 0, Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [ValidateRange(1, 100)]
        [int]$MaxRetries = 3,
        
        [ValidateRange(1, 3600)]
        [int]$DelaySeconds = 5
    )

    $attemptCount = 1
    try {
        & $ScriptBlock
        return
    }
    catch {
        while ($attemptCount -lt $MaxRetries) {
            $attemptCount++
            Write-Warning "Operation failed, waiting $DelaySeconds seconds before retry (Attempt $attemptCount/$MaxRetries)"
            Start-Sleep -Seconds $DelaySeconds
            try {
                & $ScriptBlock
                return
            }
            catch {
                if ($attemptCount -ge $MaxRetries) {
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
# } -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop
