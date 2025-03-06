# Invoke-Retry

一個 PowerShell 重試函數，用於執行可能失敗的操作並自動重試。

## 快速使用

```ps1
irm 'raw.githubusercontent.com/hunandy14/Invoke-Retry/main/Invoke-Retry.ps1'|iex
Invoke-Retry -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop {
    Get-Content "non-existing-file.txt"
}
```

## 詳細說明

載入腳本

```ps1
irm 'raw.githubusercontent.com/hunandy14/Invoke-Retry/main/Invoke-Retry.ps1'|iex
```

使用 Finally 腳本

```ps1
Invoke-Retry -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop {
    Get-Content "non-existing-file.txt"
} -FinallyScriptBlock {
    Write-Host "  🔄 Running Cleanup"
}
```

指定特定錯誤重試

```ps1
Invoke-Retry {
    Get-Content "non-existing-file.txt"
} -FinallyScriptBlock {
    Write-Host "  🔄 Running Cleanup"
} -RetryableErrors @(
    [System.Management.Automation.ItemNotFoundException],
    [System.IO.FileNotFoundException],
    [System.IO.DirectoryNotFoundException]
) -MaxRetries 3 -DelaySeconds 1 -ErrorAction Stop
```
