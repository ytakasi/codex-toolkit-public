# codex-kit CLI の command 実装。

function Invoke-ListProfiles {
    param([string]$ToolkitRoot)

    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    Write-Host 'profiles'
    foreach ($profile in Get-AvailableProfiles -ToolkitRoot $ToolkitRoot) {
        if ($profile -eq 'global') {
            $root = Join-Path $resourcesRoot 'skills/global'
        } else {
            $root = Join-Path $resourcesRoot "skills/profiles/$profile"
        }
        $skills = @()
        if (Test-Path -LiteralPath $root) {
            $skills = @(Get-ChildItem -LiteralPath $root -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | Sort-Object Name | ForEach-Object { $_.Name })
        }
        Write-Host "- $profile"
        if ($skills.Count -gt 0) {
            Write-Host "  skills: $($skills -join ', ')"
        }
    }
}
function Invoke-Status {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot
    )

    $manifest = Read-Manifest -RepoRoot $RepoRoot
    $profiles = @(Get-ManifestProfiles -Manifest $manifest)
    $currentCommit = Get-ToolkitCommit -ToolkitRoot $ToolkitRoot
    $toolkitLayerRoot = Get-RepoPath -RepoRoot $RepoRoot -RelativePath ([string]$manifest.toolkitSourceRoot)
    $repoSourceRoot = Get-RepoPath -RepoRoot $RepoRoot -RelativePath ([string]$manifest.repoSourceRoot)
    $toolkitFiles = Get-RelativeFileKeys -Root $toolkitLayerRoot
    $repoFiles = Get-RelativeFileKeys -Root $repoSourceRoot
    $overrides = @()
    foreach ($key in $repoFiles.Keys) {
        if ($toolkitFiles.ContainsKey($key)) {
            $overrides += [string]$repoFiles[$key]
        }
    }

    Write-Host 'codex-kit status'
    Write-Step "repo: $RepoRoot"
    Write-Step "profiles: $($profiles -join ', ')"
    Write-Step "manifest toolkitCommit: $($manifest.toolkitCommit)"
    Write-Step "current toolkitCommit: $currentCommit"
    Write-Step "toolkit layer: $($manifest.toolkitSourceRoot)"
    Write-Step "repo source: $($manifest.repoSourceRoot)"
    Write-Step "runtime: $($manifest.generatedRuntimeRoot)"
    Write-Step "repo レイヤー上書き: $($overrides.Count) 件"
    $overrides | Sort-Object | ForEach-Object {
        Write-Host "  - $_"
    }
}
function Invoke-Doctor {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot
    )

    Write-Host 'codex-kit doctor'
    Write-Step "toolkit root: $ToolkitRoot"
    Write-Step "repo root: $RepoRoot"
    Write-Step "git: $((Get-Command git -ErrorAction SilentlyContinue).Source)"
    Write-Step "pwsh: $((Get-Command pwsh -ErrorAction SilentlyContinue).Source)"

    $manifestPath = Join-Path $RepoRoot '.codex-kit/manifest.json'
    if (Test-Path -LiteralPath $manifestPath) {
        Write-Step "manifest: OK ($manifestPath)"
        $manifest = Read-Manifest -RepoRoot $RepoRoot
        foreach ($relative in @($manifest.toolkitSourceRoot, $manifest.repoSourceRoot, $manifest.generatedRuntimeRoot, $manifest.hookEntrypoint, $manifest.hookDispatcher)) {
            $path = Get-RepoPath -RepoRoot $RepoRoot -RelativePath ([string]$relative)
            $state = if (Test-Path -LiteralPath $path) { 'OK' } else { 'missing' }
            Write-Step "${relative}: $state"
        }
    } else {
        Write-Step "manifest: missing ($manifestPath)"
    }
}

function Invoke-SelfUpdate {
    param(
        [string]$ToolkitRoot,
        [bool]$DryRun
    )

    if ($DryRun) {
        Write-Step "git pull --ff-only を実行予定: $ToolkitRoot"
        return
    }

    & git -C $ToolkitRoot pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        throw 'self-update に失敗した。sync は実行しない。'
    }
}

function Get-DefaultRequirementsPath {
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        $programData = if (-not [string]::IsNullOrWhiteSpace($env:ProgramData)) {
            $env:ProgramData
        } else {
            [Environment]::GetFolderPath('CommonApplicationData')
        }

        return Get-FullPath (Join-Path $programData 'OpenAI/Codex/requirements.toml')
    }

    return '/etc/codex/requirements.toml'
}

function Invoke-Harden {
    param(
        [string]$ToolkitRoot,
        [bool]$DryRun,
        [string]$TargetPath
    )

    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $template = Join-Path $resourcesRoot 'templates/codex-requirements/requirements.secret-read-deny.toml'
    if (-not (Test-Path -LiteralPath $template)) {
        throw "管理側強制設定の雛形が見つからない: $template"
    }

    if ([string]::IsNullOrWhiteSpace($TargetPath)) {
        $TargetPath = Get-DefaultRequirementsPath
    } else {
        $TargetPath = Get-FullPath $TargetPath
    }

    if (-not $DryRun) {
        throw 'harden の実反映はまだ未実装。まず --dry-run で候補と既存 requirements.toml を確認して。'
    }

    Write-Host 'codex-kit harden --dry-run'
    Write-Step "管理側強制設定の雛形: $template"
    Write-Step "requirements.toml 反映候補: $TargetPath"

    $parent = Split-Path -Parent $TargetPath
    if ([string]::IsNullOrWhiteSpace($parent)) {
        Write-Step 'target parent: unknown'
    } elseif (Test-Path -LiteralPath $parent) {
        Write-Step "target parent: exists ($parent)"
    } else {
        Write-Step "target parent: missing ($parent)"
    }

    if (Test-Path -LiteralPath $TargetPath) {
        Write-Step 'requirements.toml: exists'
        Write-Step '既存の requirements.toml と雛形を手動で確認してからマージする。'
    } else {
        Write-Step 'requirements.toml: missing'
        Write-Step '新規作成候補。system 管理領域なので実反映には権限が必要になる場合がある。'
    }

    Write-Step '公式確認: requirements.toml は admin-enforced configuration。permissions.filesystem.deny_read は exact path または glob を受ける。'
    Write-Step '注意: native Windows では deny_read は direct file tool には効くが、shell subprocess の read には効かない。repo hook の変更・stage 防止と併用する。'
    Write-Step 'harden --dry-run では個人環境や管理環境へは書き込まない。'
}

function Invoke-Main {
    param([string[]]$RawArgs)

    $parsed = Read-CliArgs -RawArgs $RawArgs
    $toolkitRoot = Get-ToolkitRoot

    switch ($parsed.Command) {
        { $_ -in @('help', '--help', '-h') } {
            Write-Usage
        }
        'list-profiles' {
            Invoke-ListProfiles -ToolkitRoot $toolkitRoot
        }
        'init' {
            Invoke-Init -Parsed $parsed -ToolkitRoot $toolkitRoot
        }
        'sync' {
            $repoRoot = Get-RepoRootFromOptions -Parsed $parsed
            Invoke-Sync -RepoRoot $repoRoot -ToolkitRoot $toolkitRoot -DryRun (Test-Option -Parsed $parsed -Name 'dry-run')
        }
        'status' {
            $repoRoot = Get-RepoRootFromOptions -Parsed $parsed
            Invoke-Status -RepoRoot $repoRoot -ToolkitRoot $toolkitRoot
        }
        'doctor' {
            $repoRoot = Get-RepoRootFromOptions -Parsed $parsed
            Invoke-Doctor -RepoRoot $repoRoot -ToolkitRoot $toolkitRoot
        }
        'self-update' {
            Invoke-SelfUpdate -ToolkitRoot $toolkitRoot -DryRun (Test-Option -Parsed $parsed -Name 'dry-run')
        }
        'update' {
            $dryRun = Test-Option -Parsed $parsed -Name 'dry-run'
            $repoRoot = Get-RepoRootFromOptions -Parsed $parsed
            Invoke-SelfUpdate -ToolkitRoot $toolkitRoot -DryRun $dryRun
            Invoke-Sync -RepoRoot $repoRoot -ToolkitRoot $toolkitRoot -DryRun $dryRun
        }
        'harden' {
            Invoke-Harden -ToolkitRoot $toolkitRoot -DryRun (Test-Option -Parsed $parsed -Name 'dry-run') -TargetPath (Get-Option -Parsed $parsed -Name 'target' -Default $null)
        }
        default {
            throw "unknown command: $($parsed.Command)"
        }
    }
}
