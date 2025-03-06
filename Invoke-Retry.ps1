<#
.SYNOPSIS
    執行指定的腳本區塊，在失敗時自動重試。

.DESCRIPTION
    這個函數會執行提供的腳本區塊，如果執行失敗，會等待指定的時間後重試。
    重試次數達到上限後，會執行最終腳本區塊（如果提供）並拋出錯誤。

.PARAMETER ScriptBlock
    要執行的腳本區塊。這是必要參數，可以通過管道傳入。

.PARAMETER FinallyScriptBlock
    在所有嘗試（無論成功或失敗）後執行的腳本區塊。
    通常用於清理工作，例如關閉連接或釋放資源。

.PARAMETER MaxRetries
    最大重試次數。必須是 1 到 100 之間的整數。
    預設值為 3。

.PARAMETER DelaySeconds
    每次重試之間的等待時間（秒）。必須是 1 到 3600 之間的整數。
    預設值為 60。

.PARAMETER RetryMessage
    重試時顯示的訊息格式。可以使用 {0}、{1}、{2} 作為佔位符：
    {0} = 當前重試次數
    {1} = 最大重試次數
    {2} = 錯誤訊息

.PARAMETER WaitMessage
    等待重試時顯示的訊息格式。可以使用 {0}、{1}、{2} 作為佔位符：
    {0} = 等待秒數
    {1} = 下一次重試的次數
    {2} = 最大重試次數

.PARAMETER FailureMessage
    達到最大重試次數時顯示的錯誤訊息格式。
    可以使用 {0} 作為最大重試次數的佔位符。

.PARAMETER RetryableErrors
    指定需要重試的錯誤類型列表。如果未指定，則所有錯誤都會重試。
    例如：@([System.Net.WebException], [System.IO.IOException])

.EXAMPLE
    Invoke-Retry {
        # 執行可能失敗的操作
        Get-Content "不存在的檔案.txt"
    } -MaxRetries 3 -DelaySeconds 5 -ErrorAction Stop

.EXAMPLE
    Invoke-Retry {
        # 執行需要重試的操作
        Invoke-RestMethod "https://api.example.com/data"
    } -FinallyScriptBlock {
        # 清理工作
        Write-Host "清理資源..."
    } -MaxRetries 3 -DelaySeconds 5 -ErrorAction Stop

.EXAMPLE
    # 只重試特定錯誤類型
    Invoke-Retry {
        Get-Content "file.txt"
    } -RetryableErrors @(
        [System.IO.FileNotFoundException],
        [System.IO.DirectoryNotFoundException]
    ) -MaxRetries 3 -DelaySeconds 5 -ErrorAction Stop
#>
function Invoke-Retry {
    param (
        # 要重試的腳本區塊
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [scriptblock]$ScriptBlock,

        # 最後執行的腳本區塊
        [scriptblock]$FinallyScriptBlock = $null,

        # 最大重試次數
        [ValidateRange(1, 100)]
        [int]$MaxRetries = 3,
        # 失敗後的等待時間（秒）
        [ValidateRange(1, 3600)]
        [int]$DelaySeconds = 60,
        
        # 重試時的訊息
        [string]$RetryMessage = "Execution failed ({0} / {1}), Error message: {2}",
        # 等待訊息
        [string]$WaitMessage = "Waiting {0} seconds before retry... (Attempt {1} / {2})",
        # 自訂錯誤訊息
        [string]$FailureMessage = "Maximum retry attempts ({0}) reached, program terminated abnormally",

        # 需要重試的錯誤類型列表
        [Type[]]$RetryableErrors = @()
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
                $errorType = $_.Exception.GetType()
                
                if ($RetryableErrors.Count -gt 0 -and $RetryableErrors -notcontains $errorType) {
                    Write-Error "Error type not configured for retry: $($errorType.FullName)"
                    throw
                }

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

## 範例1 任意錯誤都重試
# Invoke-Retry {
#     throw "Error occurred"
# } -FinallyScriptBlock {
#     Write-Host "  🔄 Running Cleanup"
# } -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop

## 範例2 指定錯誤重試 (範圍外不重試直接報錯)
# Invoke-Retry {
#     Get-Content "non-existing-file.txt" -ErrorAction Stop
# } -FinallyScriptBlock {
#     Write-Host "  🔄 Running Cleanup"
# } -RetryableErrors @(
#     # [System.Management.Automation.ItemNotFoundException],
#     [System.IO.FileNotFoundException],
#     [System.IO.DirectoryNotFoundException]
# ) -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop
