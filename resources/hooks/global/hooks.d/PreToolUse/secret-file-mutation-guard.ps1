# 対象イベント: PreToolUse
# 役割: 実際の機密情報が入っていそうなファイルの変更、コピー、stage を止める。

$ErrorActionPreference = 'Stop'
$script:CodexHookRawInput = @($input) -join "`n"

function Read-HookPayload {
    $raw = $script:CodexHookRawInput
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $raw = [Console]::In.ReadToEnd()
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-ToolCommand {
    param([object]$Payload)

    if ($null -eq $Payload -or $null -eq $Payload.tool_input) {
        return ''
    }

    $properties = $Payload.tool_input.PSObject.Properties.Name
    if ($properties -contains 'command') {
        return [string]$Payload.tool_input.command
    }

    return ($Payload.tool_input | ConvertTo-Json -Compress -Depth 20)
}

function Test-AnyPattern {
    param(
        [string]$Text,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ($Text -match $pattern) {
            return $true
        }
    }

    return $false
}

function Stop-WithBlock {
    param([string]$Message)

    [Console]::Error.WriteLine($Message)
    exit 2
}

$payload = Read-HookPayload
$command = Get-ToolCommand -Payload $payload
if ([string]::IsNullOrWhiteSpace($command)) {
    exit 0
}

$toolName = if ($null -ne $payload -and $null -ne $payload.tool_name) { [string]$payload.tool_name } else { '' }

$mutatingPattern = '(?i)\b(Set-Content|Add-Content|Out-File|New-Item|Remove-Item|rm|del|erase|Copy-Item|cp|copy|Move-Item|mv|move|git\s+add)\b|>>?\s*'
$isPatchTool = $toolName -match '^(apply_patch|Edit|Write)$'
if (-not $isPatchTool -and $command -notmatch $mutatingPattern) {
    exit 0
}

# 例や雛形は読み書きできるように残し、実際の機密情報らしいものだけを止める。
$normalized = $command
$normalized = $normalized -replace '(?i)\.env\.(example|sample|template|schema)', ''
$normalized = $normalized -replace '(?i)(example|sample|template)\.env', ''
$normalized = $normalized -replace '(?i)\.pem\.pub', ''

$secretPathPatterns = @(
    '(?i)(^|[\s"''`=:(\[])(?:\.{1,2}[\\/])?(?:[^\\/\s"''`]+[\\/])*\.env(?:\.[A-Za-z0-9_-]+)?(?=$|[\s"''`)\];,])',
    '(?i)(^|[\s"''`=:(\[])(?:\.{1,2}[\\/])?(?:[^\\/\s"''`]+[\\/])*(id_rsa|id_ed25519|credentials\.json|secrets\.json)(?=$|[\s"''`)\];,])',
    '(?i)(^|[\s"''`=:(\[])(?:\.{1,2}[\\/])?(?:[^\\/\s"''`]+[\\/])*[^\\/\s"''`]+\.(pem|pfx|p12|key)(?=$|[\s"''`)\];,])',
    '(?i)service-account[^\\/\s"''`]*\.json(?=$|[\s"''`)\];,])'
)

if (Test-AnyPattern -Text $normalized -Patterns $secretPathPatterns) {
    Stop-WithBlock '機密情報が入っていそうなファイルの変更、コピー、stage を止めた。必要なら .env.example などの例や雛形を使い、実際の機密情報は Codex に読ませず、秘密情報の管理場所やローカル設定側で扱って。'
}

exit 0
