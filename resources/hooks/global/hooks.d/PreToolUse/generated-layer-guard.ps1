# 対象イベント: PreToolUse
# 役割: codex-kit が生成・管理する場所を直接編集しないように止める。

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

# codex-kit 自身は管理下の場所を再生成してよい。
$codexKitCommandPattern = '(?i)(^|[\s;&|])(?:\.\\|\.\/)?codex-kit(?:\.ps1|\.cmd|\.exe)?\s+(init|sync|update)\b'
if ($command -match $codexKitCommandPattern) {
    exit 0
}

$managedPathPatterns = @(
    '(?i)(^|[\s"''])(?:\.\/|\.\\)?\.agents(?:[\\/]|$)',
    '(?i)(^|[\s"''])(?:\.\/|\.\\)?agent-skills[\\/]toolkit(?:[\\/]|$)',
    '(?i)(^|[\s"''])(?:\.\/|\.\\)?\.codex[\\/]hooks\.json(?=$|[\s"''])',
    '(?i)(^|[\s"''])(?:\.\/|\.\\)?\.codex[\\/]hooks[\\/]codex-kit-dispatch\.[A-Za-z0-9]+(?=$|[\s"''])'
)

if (-not (Test-AnyPattern -Text $command -Patterns $managedPathPatterns)) {
    exit 0
}

$isPatchTool = $toolName -match '^(apply_patch|Edit|Write)$'
$mutatingCommandPattern = '(?i)\b(Remove-Item|rm|del|erase|rmdir|Move-Item|mv|Copy-Item|cp|copy|Set-Content|Add-Content|Out-File|New-Item|mkdir|touch)\b|\bgit\s+(add|checkout|restore|clean|rm|mv)\b|>>?\s*'

if ($isPatchTool -or $command -match $mutatingCommandPattern) {
    Stop-WithBlock 'codex-kit が生成・管理する場所への直接変更を止めた。必要な変更は agent-skills/repo 側へ置くか、codex-kit sync/update で再生成して。対象: .agents, agent-skills/toolkit, .codex/hooks.json, .codex/hooks/codex-kit-dispatch.*'
}

exit 0
