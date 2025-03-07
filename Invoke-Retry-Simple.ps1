function Invoke-Retry {
    param (
        [Parameter(Position = 0, Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [ValidateRange(1, 100)]
        [int]$MaxRetries = 3,
        
        [ValidateRange(1, 3600)]
        [int]$DelaySeconds = 5
    )

    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            & $ScriptBlock
            return
        }
        catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                Write-Error "Maximum retry attempts ($MaxRetries) reached"
                return
            }
            Write-Warning "Operation failed, waiting $DelaySeconds seconds before retry (Attempt $retryCount/$MaxRetries)"
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

# 使用範例
# Invoke-Retry { 
#     Get-Content "non-existing-file.txt"
# } -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop
