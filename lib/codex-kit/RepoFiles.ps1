# codex-kit CLI が対象リポジトリに置く管理ファイル。
# AGENTS.md と .gitignore はユーザーが触る可能性が高いため、管理ブロックや追記だけで更新する。

function Get-RepoRulesBlock {
    param(
        [string]$ToolkitRoot,
        [string[]]$Profiles
    )

    # 共通ルール template から toolkit 管理 marker を剥がし、対象 repo 用の管理ブロックに再利用する。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $commonRulesTemplatePath = Join-Path $resourcesRoot 'global/AGENTS.common-rules-template.md'
    $commonRulesTemplate = Get-Content -Raw -LiteralPath $commonRulesTemplatePath
    $body = $commonRulesTemplate -replace '(?s)<!-- codex-toolkit:global-rules:start -->\s*', ''
    $body = $body -replace '(?s)\s*<!-- codex-toolkit:global-rules:end -->', ''
    $profileLine = "- このリポジトリの codex-kit profiles: $($Profiles -join ', ')。リポジトリ固有に育てる skill や hook は ``agent-skills/repo`` に置く。"
    return ($body.TrimEnd() + "`n" + $profileLine + "`n")
}

function Update-ManagedBlock {
    param(
        [string]$Path,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Body,
        [bool]$DryRun
    )

    # marker の内側だけを置き換える。marker 外の README 的な説明や repo 固有ルールは残す。
    $newBlock = "$StartMarker`n$Body$EndMarker`n"
    $current = ''
    if (Test-Path -LiteralPath $Path) {
        $current = Get-Content -Raw -LiteralPath $Path
    }

    $pattern = "(?s)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))\r?\n?"
    if ($current -match $pattern) {
        $next = [regex]::Replace($current, $pattern, $newBlock)
    } elseif ([string]::IsNullOrWhiteSpace($current)) {
        $next = $newBlock
    } else {
        $next = $current.TrimEnd() + "`n`n" + $newBlock
    }

    if ($next -eq $current) {
        return
    }

    if ($DryRun) {
        Write-Step "AGENTS.md 管理ブロック更新: $Path"
        return
    }

    Set-Content -LiteralPath $Path -Value $next -Encoding UTF8
}

function Update-RepoAgents {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot,
        [string[]]$Profiles,
        [bool]$DryRun
    )

    $agentsPath = Join-Path $RepoRoot 'AGENTS.md'
    $body = Get-RepoRulesBlock -ToolkitRoot $ToolkitRoot -Profiles $Profiles
    Update-ManagedBlock -Path $agentsPath -StartMarker '<!-- codex-kit:repo-rules:start -->' -EndMarker '<!-- codex-kit:repo-rules:end -->' -Body $body -DryRun $DryRun
}

function Update-GitignoreFromTemplate {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot,
        [bool]$DryRun
    )

    # 生成物を Git に入れないための ignore 行を足す。
    # 既存 .gitignore から行を消さず、template 側の不足分だけを末尾へ追加する。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $templatePath = Join-Path $resourcesRoot 'templates/repo/.gitignore'
    $gitignorePath = Join-Path $RepoRoot '.gitignore'
    $templateLines = Get-Content -LiteralPath $templatePath
    $currentLines = @()
    if (Test-Path -LiteralPath $gitignorePath) {
        $currentLines = Get-Content -LiteralPath $gitignorePath
    }

    $toAppend = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $templateLines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($currentLines -notcontains $line) {
            [void]$toAppend.Add($line)
        }
    }

    if ($toAppend.Count -eq 0) {
        return
    }

    if ($DryRun) {
        Write-Step ".gitignore に codex-kit 生成物の除外を追加: $gitignorePath"
        return
    }

    $nextLines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $currentLines) {
        [void]$nextLines.Add($line)
    }
    if ($nextLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($nextLines[$nextLines.Count - 1])) {
        [void]$nextLines.Add('')
    }
    foreach ($line in $toAppend) {
        [void]$nextLines.Add($line)
    }

    Set-Content -LiteralPath $gitignorePath -Value $nextLines -Encoding UTF8
}
