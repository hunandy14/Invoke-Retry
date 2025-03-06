function Invoke-Retry {
    param (
        # 要重試的腳本區塊
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [scriptblock]$ScriptBlock,

        # 最後執行的腳本區塊
        [scriptblock]$FinallyScriptBlock = $null,

        # 最大重試次數
        [int]$MaxRetries = 3,
        # 失敗後的等待時間
        [int]$DelaySeconds = 60,
        
        # 重試時的訊息
        [string]$RetryMessage = "Execution failed ({0} / {1}), Error message: {2}",
        # 等待訊息
        [string]$WaitMessage = "Waiting {0} seconds before retry... (Attempt {1} / {2})",
        # 自訂錯誤訊息
        [string]$FailureMessage = "Maximum retry attempts ({0}) reached, program terminated abnormally" 
    )

    begin {
        $retryCount = 0
    }

    process {
        while ($retryCount -lt $MaxRetries) {
            try {
                & $ScriptBlock
                return
            }
            catch {
                $retryCount++
                $msg = $RetryMessage -f $retryCount, $MaxRetries, $_
                Write-Host $msg -ForegroundColor Red

                if ($retryCount -ge $MaxRetries) {
                    $msg = $FailureMessage -f $MaxRetries
                    Write-Host "  $msg" -ForegroundColor Red
                    $msg = "Invoke-Retry Error: " + ($FailureMessage -f $MaxRetries) + " Error message: " + $_.Exception.Message
                    Write-Error $msg
                }
                else {
                    $msg = ($WaitMessage -f $DelaySeconds, ($retryCount + 1), $MaxRetries)
                    Write-Host "  $msg" -ForegroundColor Yellow
                    Start-Sleep -Seconds $DelaySeconds
                }
            }
            finally {
                if ($FinallyScriptBlock -ne $null) {
                    & $FinallyScriptBlock
                }
            }
        }
    }
}

# Invoke-Retry {
#     throw "Error occurred"
# } FfinallyScriptBlock {
#     Write-Host "  🔄 Running Cleanup"
# } -MaxRetries 3 -DelaySeconds 1
