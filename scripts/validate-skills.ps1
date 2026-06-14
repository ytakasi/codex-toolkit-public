[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipGitDiffCheck
)

# codex-toolkit の配布資産を静的検証する script。
# skill frontmatter、assets 配置、古い参照、line ending、git diff whitespace をまとめて見る。

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$errors = [System.Collections.Generic.List[string]]::new()
$script:SkillDirectoriesCache = $null

function Get-ResourcesRoot {
    return Join-Path $Root 'resources'
}

function Test-ResourceRootLayout {
    # resources 配下への集約が崩れていないか見る。
    # 旧 top-level global/hooks/skills/templates が復活したら公開面が二重化するため失敗にする。
    $resourcesRoot = Get-ResourcesRoot
    foreach ($relativePath in @(
        'global',
        'hooks',
        'skills',
        'templates'
    )) {
        $expected = Join-Path $resourcesRoot $relativePath
        if (-not (Test-Path -LiteralPath $expected)) {
            Add-ValidationError "resources root is missing: $expected"
        }

        $legacy = Join-Path $Root $relativePath
        if (Test-Path -LiteralPath $legacy) {
            Add-ValidationError "legacy top-level resource directory should not exist: $legacy"
        }
    }
}

function Add-ValidationError {
    param([string]$Message)
    $errors.Add($Message) | Out-Null
}

function Get-TextFileContent {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path)
}

function Get-LineEndingProfile {
    param([string]$Path)
    $text = Get-TextFileContent -Path $Path
    [pscustomobject]@{
        Path = $Path
        Crlf = ([regex]::Matches($text, "`r`n")).Count
        LfOnly = ([regex]::Matches($text, "(?<!`r)`n")).Count
    }
}

function Get-FrontmatterMap {
    param([string]$SkillPath)

    $text = Get-TextFileContent -Path $SkillPath
    $match = [regex]::Match($text, '\A---\s*\r?\n(?<body>.*?)\r?\n---', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) {
        return $null
    }

    $map = @{}
    foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $keyValue = [regex]::Match($line, '^([A-Za-z0-9_-]+):\s*(.*)$')
        if (-not $keyValue.Success) {
            $map['__invalid__'] = $line
            continue
        }

        $map[$keyValue.Groups[1].Value] = $keyValue.Groups[2].Value.Trim()
    }

    return $map
}

function Get-SkillDirectories {
    if ($null -ne $script:SkillDirectoriesCache) {
        return $script:SkillDirectoriesCache
    }

    $skillsRoot = Join-Path (Get-ResourcesRoot) 'skills'
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        $script:SkillDirectoriesCache = @()
        return $script:SkillDirectoriesCache
    }

    $script:SkillDirectoriesCache = @(
        Get-ChildItem -LiteralPath $skillsRoot -Recurse -File -Filter 'SKILL.md' |
            ForEach-Object { $_.Directory } |
            Sort-Object FullName
    )

    return $script:SkillDirectoriesCache
}

function Get-SkillDirectoryByName {
    param([string]$Name)

    $matches = @(Get-SkillDirectories | Where-Object { $_.Name -eq $Name })
    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches[0]
}

function Test-SkillMetadata {
    $skillsRoot = Join-Path (Get-ResourcesRoot) 'skills'
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        Add-ValidationError "skills root not found: $skillsRoot"
        return
    }

    $skillDirs = Get-SkillDirectories
    if ($skillDirs.Count -eq 0) {
        Add-ValidationError "no SKILL.md files found under: $skillsRoot"
        return
    }

    foreach ($duplicate in ($skillDirs | Group-Object Name | Where-Object { $_.Count -gt 1 })) {
        Add-ValidationError "duplicate skill directory name: $($duplicate.Name)"
    }

    foreach ($skillDir in $skillDirs) {
        $skillMd = Join-Path $skillDir.FullName 'SKILL.md'
        $openaiYaml = Join-Path $skillDir.FullName 'agents\openai.yaml'

        if (-not (Test-Path -LiteralPath $skillMd)) {
            Add-ValidationError "missing SKILL.md: $($skillDir.Name)"
            continue
        }

        $frontmatter = Get-FrontmatterMap -SkillPath $skillMd
        if ($null -eq $frontmatter) {
            Add-ValidationError "invalid or missing frontmatter: $($skillDir.Name)"
        } else {
            if ($frontmatter.ContainsKey('__invalid__')) {
                Add-ValidationError "invalid frontmatter line in $($skillDir.Name): $($frontmatter['__invalid__'])"
            }
            if (-not $frontmatter.ContainsKey('name')) {
                Add-ValidationError "missing frontmatter name: $($skillDir.Name)"
            } elseif ($frontmatter['name'] -ne $skillDir.Name) {
                Add-ValidationError "frontmatter name mismatch: dir=$($skillDir.Name), name=$($frontmatter['name'])"
            }
            if (-not $frontmatter.ContainsKey('description') -or [string]::IsNullOrWhiteSpace($frontmatter['description'])) {
                Add-ValidationError "missing frontmatter description: $($skillDir.Name)"
            }
        }

        if (-not (Test-Path -LiteralPath $openaiYaml)) {
            Add-ValidationError "missing agents/openai.yaml: $($skillDir.Name)"
            continue
        }

        $yaml = Get-TextFileContent -Path $openaiYaml
        foreach ($key in @('display_name', 'short_description', 'default_prompt')) {
            if ($yaml -notmatch "(?m)^\s+$key`:\s+`".+`"\s*$") {
                Add-ValidationError "missing or invalid interface.${key}: $($skillDir.Name)"
            }
        }

        $skillToken = '$' + $skillDir.Name
        if (-not $yaml.Contains($skillToken)) {
            Add-ValidationError "default_prompt does not mention ${skillToken}: $($skillDir.Name)"
        }
    }
}

function Test-StaleReferences {
    # 物理移動で残りやすい古い path や旧 skill 名を検出する。
    # ここに引っかかる場合は、docs か skill 本文が今の配置を指していない。
    $patterns = @(
        'scheduled-job-hardening',
        'workflows/',
        'workflows\\',
        'global/guidance',
        'global\\guidance',
        '\.\./\.\./templates/',
        '\.\.\\\.\.\\templates\\'
    )

    $files = Get-ChildItem -LiteralPath $Root -Recurse -File -Include *.md,*.yaml,*.yml,*.json,*.ps1,*.sh |
        Where-Object {
            $_.FullName -notmatch '\\.git\\' -and
            $_.FullName -ne $PSCommandPath
        }

    foreach ($match in ($files | Select-String -Pattern $patterns)) {
        Add-ValidationError "stale reference: $($match.Path):$($match.LineNumber): $($match.Line.Trim())"
    }
}

function Test-ProviderReferenceMove {
    $providerDryDir = Get-SkillDirectoryByName -Name 'provider-dry-run'
    $providerJobDir = Get-SkillDirectoryByName -Name 'provider-job-hardening'

    if ($null -eq $providerDryDir -and $null -eq $providerJobDir) {
        return
    }

    if ($null -ne $providerDryDir) {
        $oldRef = Join-Path $providerDryDir.FullName 'references\scheduled-provider-mvp-checklist.md'
        $providerDry = Join-Path $providerDryDir.FullName 'SKILL.md'
        if (Test-Path -LiteralPath $oldRef) {
            Add-ValidationError "old provider dry-run reference still exists: $oldRef"
        }
        if ((Test-Path -LiteralPath $providerDry) -and (Get-TextFileContent -Path $providerDry).Contains('references/scheduled-provider-mvp-checklist.md')) {
            Add-ValidationError 'provider-dry-run still points to references/scheduled-provider-mvp-checklist.md'
        }
    }

    if ($null -ne $providerJobDir) {
        $newRef = Join-Path $providerJobDir.FullName 'references\scheduled-provider-mvp-checklist.md'
        $providerJob = Join-Path $providerJobDir.FullName 'SKILL.md'
        $providerJobText = if (Test-Path -LiteralPath $providerJob) { Get-TextFileContent -Path $providerJob } else { '' }
        if ($providerJobText.Contains('references/scheduled-provider-mvp-checklist.md') -and -not (Test-Path -LiteralPath $newRef)) {
            Add-ValidationError "provider job hardening reference is missing: $newRef"
        }
    }
}

function Test-NotificationTemplateDeduplication {
    $template = Join-Path (Get-ResourcesRoot) 'skills\profiles\scheduled-batch\scheduled-batch-hardening\assets\github-actions\node-scheduled-job.yml'
    if (-not (Test-Path -LiteralPath $template)) {
        return
    }

    $text = Get-TextFileContent -Path $template
    foreach ($pattern in @('Notify Discord on failure', 'discord-error-payload', 'allowed_mentions', 'curl --fail-with-body', 'DISCORD_ERROR_WEBHOOK_URL')) {
        if ($text.Contains($pattern)) {
            Add-ValidationError "node scheduled job template still duplicates failure notification implementation: $pattern"
        }
    }

    $canonicalAsset = Join-Path (Get-ResourcesRoot) 'skills\profiles\scheduled-batch\scheduled-batch-hardening\assets\github-actions-failure-notify-step.yml'
    if ((Test-Path -LiteralPath $canonicalAsset) -and -not ($text.Contains('scheduled-batch-hardening') -and $text.Contains('assets/github-actions-failure-notify-step.yml'))) {
        Add-ValidationError 'node scheduled job template does not point to the canonical failure notify asset'
    }
}

function Test-TemplateOwnership {
    # resources/templates は CLI が直接読むテンプレートだけに限定する。
    # skill 固有の雛形は owning skill の assets/ に置く。
    $templatesRoot = Join-Path (Get-ResourcesRoot) 'templates'
    if (-not (Test-Path -LiteralPath $templatesRoot)) {
        return
    }

    $allowedTopLevel = @('repo', 'codex-kit', 'codex-requirements')
    Get-ChildItem -LiteralPath $templatesRoot -Force | ForEach-Object {
        if ($allowedTopLevel -notcontains $_.Name) {
            Add-ValidationError "resources/templates is only for CLI-owned templates; move skill-owned assets under the owning skill: $($_.FullName)"
        }
    }
}

function Test-GlobalRulesTemplateLineEndings {
    $globalRulesTemplate = Join-Path (Get-ResourcesRoot) 'global\AGENTS.common-rules-template.md'
    if (-not (Test-Path -LiteralPath $globalRulesTemplate)) {
        Add-ValidationError "共通ルールテンプレートが見つからない: $globalRulesTemplate"
        return
    }

    $profile = Get-LineEndingProfile -Path $globalRulesTemplate
    if ($profile.Crlf -ne 0) {
        Add-ValidationError "resources/global/AGENTS.common-rules-template.md は LF-only にする。CRLF=$($profile.Crlf), LF-only=$($profile.LfOnly)"
    }
}

function Test-GitDiffCheck {
    # validate-skills 単体で、commit 前に whitespace error も拾えるようにする。
    if ($SkipGitDiffCheck) {
        return
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        Write-Warning 'git not found; skipping git diff --check.'
        return
    }

    $unstaged = & git -C $Root diff --check 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "git diff --check failed:`n$($unstaged -join "`n")"
    }

    $staged = & git -C $Root diff --cached --check 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "git diff --cached --check failed:`n$($staged -join "`n")"
    }
}

Test-ResourceRootLayout
Test-SkillMetadata
Test-StaleReferences
Test-ProviderReferenceMove
Test-NotificationTemplateDeduplication
Test-TemplateOwnership
Test-GlobalRulesTemplateLineEndings
Test-GitDiffCheck

if ($errors.Count -gt 0) {
    Write-Host 'Codex Toolkit validation failed:' -ForegroundColor Red
    foreach ($validationError in $errors) {
        Write-Host "- $validationError" -ForegroundColor Red
    }
    exit 1
}

Write-Host 'Codex Toolkit validation passed.' -ForegroundColor Green
