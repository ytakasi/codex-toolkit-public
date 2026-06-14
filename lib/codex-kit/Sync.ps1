# codex-kit CLI の init / sync と hook 生成。
# toolkit layer は生成物、repo layer は対象 repo の正本、.agents は Codex が読む runtime。

function Initialize-RepoSourceRoot {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot,
        [bool]$DryRun
    )

    # repo 固有 layer の初期形だけを配る。既にある hook / skill は NoOverwrite で守る。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $source = Join-Path $resourcesRoot 'templates/repo/agent-skills/repo'
    $destination = Join-Path $RepoRoot 'agent-skills/repo'
    Copy-DirectoryContents -Source $source -Destination $destination -DryRun $DryRun -NoOverwrite $true
}

function Get-RelativeFileKeys {
    param(
        [string]$Root,
        [bool]$IgnoreGitkeep = $true
    )

    # toolkit layer と repo layer の同名ファイルを検出するため、相対 path を case-insensitive key にする。
    $keys = @{}
    if (-not (Test-Path -LiteralPath $Root)) {
        return $keys
    }

    Get-ChildItem -LiteralPath $Root -File -Force -Recurse | ForEach-Object {
        if ($IgnoreGitkeep -and $_.Name -eq '.gitkeep') {
            return
        }

        $relative = ConvertTo-RelativePath -BasePath $Root -Path $_.FullName
        $key = (Normalize-RelativePathText $relative).ToLowerInvariant()
        $keys[$key] = $relative
    }

    return $keys
}

function Copy-SelectedSkillsToToolkitLayer {
    param(
        [string]$ToolkitRoot,
        [string]$ToolkitLayerRoot,
        [string[]]$Profiles,
        [bool]$DryRun
    )

    # 選択 profile の SKILL.md ディレクトリだけを toolkit layer へコピーする。
    # resources 配下にあるだけの補助フォルダは、SKILL.md がない限り配らない。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $skillsDestination = Join-Path $ToolkitLayerRoot 'skills'
    foreach ($profile in $Profiles) {
        if ($profile -eq 'global') {
            $sourceRoot = Join-Path $resourcesRoot 'skills/global'
        } else {
            $sourceRoot = Join-Path $resourcesRoot "skills/profiles/$profile"
        }

        if (-not (Test-Path -LiteralPath $sourceRoot)) {
            continue
        }

        Get-ChildItem -LiteralPath $sourceRoot -Directory | Sort-Object Name | ForEach-Object {
            if (-not (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md'))) {
                return
            }

            $destination = Join-Path $skillsDestination $_.Name
            Copy-DirectoryContents -Source $_.FullName -Destination $destination -DryRun $DryRun
        }
    }
}

function Copy-HooksToToolkitLayer {
    param(
        [string]$ToolkitRoot,
        [string]$ToolkitLayerRoot,
        [string[]]$Profiles,
        [bool]$DryRun
    )

    # global hooks は常に配り、profile hooks は選ばれた profile だけを追加する。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $globalHooks = Join-Path $resourcesRoot 'hooks/global'
    Copy-DirectoryContents -Source $globalHooks -Destination $ToolkitLayerRoot -DryRun $DryRun

    foreach ($profile in $Profiles) {
        if ($profile -eq 'global') {
            continue
        }

        $profileHooks = Join-Path $resourcesRoot "hooks/profiles/$profile"
        Copy-DirectoryContents -Source $profileHooks -Destination $ToolkitLayerRoot -DryRun $DryRun
    }
}

function Write-HooksJson {
    param(
        [string]$RepoRoot,
        [string]$HookEntrypoint,
        [bool]$DryRun
    )

    # hooks.json は全 event を同じ dispatcher へ向ける。
    # 実際にどの hook script を動かすかは dispatcher が toolkit/repo の hooks.d を見て決める。
    $hooks = [ordered]@{}
    foreach ($event in $script:HookEvents) {
        $command = 'pwsh -NoProfile -ExecutionPolicy Bypass -File "$(git rev-parse --show-toplevel)/.codex/hooks/codex-kit-dispatch.ps1" -EventName "' + $event + '"'
        $commandWindows = 'pwsh -NoProfile -ExecutionPolicy Bypass -Command "& { $root = git rev-parse --show-toplevel; & (Join-Path $root ''.codex/hooks/codex-kit-dispatch.ps1'') -EventName ''' + $event + ''' }"'
        $hooks[$event] = @(
            [ordered]@{
                hooks = @(
                    [ordered]@{
                        type = 'command'
                        command = $command
                        commandWindows = $commandWindows
                        timeout = 30
                    }
                )
            }
        )
    }

    $path = Join-Path $RepoRoot $HookEntrypoint
    $value = [ordered]@{
        hooks = $hooks
    }
    Write-JsonFile -Path $path -Value $value -DryRun $DryRun
}

function Get-HookDispatcherScript {
    param([string]$ToolkitRoot)

    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $templatePath = Join-Path $resourcesRoot 'templates/codex-kit/codex-kit-dispatch.ps1'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "hook 振り分けスクリプトのテンプレートが見つからない: $templatePath"
    }

    return Get-Content -Raw -LiteralPath $templatePath
}
function Write-HookDispatcher {
    param(
        [string]$RepoRoot,
        [string]$HookDispatcher,
        [string]$ToolkitRoot,
        [bool]$DryRun
    )

    $path = Join-Path $RepoRoot $HookDispatcher
    if ($DryRun) {
        Write-Step "hook 振り分けスクリプト更新: $path"
        return
    }

    $parent = Split-Path -Parent $path
    [void](New-Item -ItemType Directory -Path $parent -Force)
    Set-Content -LiteralPath $path -Value (Get-HookDispatcherScript -ToolkitRoot $ToolkitRoot) -Encoding UTF8
}

function Invoke-Sync {
    param(
        [string]$RepoRoot,
        [string]$ToolkitRoot,
        [bool]$DryRun,
        [object]$ManifestObject = $null
    )

    # sync は manifest を唯一の入力契約として、選択 profile と生成先 root を決める。
    $manifest = if ($null -eq $ManifestObject) { Read-Manifest -RepoRoot $RepoRoot } else { $ManifestObject }
    $profiles = @(Get-ManifestProfiles -Manifest $manifest)
    $available = @(Get-AvailableProfiles -ToolkitRoot $ToolkitRoot)
    foreach ($profile in $profiles) {
        if ($available -notcontains $profile) {
            throw "unknown profile in manifest: $profile"
        }
    }

    # ここから先はディレクトリ削除を伴うため、管理対象 root を既定値に限定する。
    $toolkitLayerRoot = Assert-ManagedDirectory -RepoRoot $RepoRoot -RelativePath ([string]$manifest.toolkitSourceRoot) -ExpectedRelativePath 'agent-skills/toolkit'
    $runtimeRoot = Assert-ManagedDirectory -RepoRoot $RepoRoot -RelativePath ([string]$manifest.generatedRuntimeRoot) -ExpectedRelativePath '.agents'
    $repoSourceRoot = Get-RepoPath -RepoRoot $RepoRoot -RelativePath ([string]$manifest.repoSourceRoot)

    Write-Host "codex-kit sync"
    Write-Step "repo: $RepoRoot"
    Write-Step "profiles: $($profiles -join ', ')"

    # 1. toolkit 由来の生成 layer を作り直す。
    Remove-AndRecreateDirectory -Path $toolkitLayerRoot -DryRun $DryRun
    Copy-SelectedSkillsToToolkitLayer -ToolkitRoot $ToolkitRoot -ToolkitLayerRoot $toolkitLayerRoot -Profiles $profiles -DryRun $DryRun
    Copy-HooksToToolkitLayer -ToolkitRoot $ToolkitRoot -ToolkitLayerRoot $toolkitLayerRoot -Profiles $profiles -DryRun $DryRun

    # repo layer は後勝ち。先に重複を数えて、sync/status で人間に見えるようにする。
    $toolkitFiles = Get-RelativeFileKeys -Root $toolkitLayerRoot
    $repoFiles = Get-RelativeFileKeys -Root $repoSourceRoot
    $overrides = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $repoFiles.Keys) {
        if ($toolkitFiles.ContainsKey($key)) {
            [void]$overrides.Add([string]$repoFiles[$key])
        }
    }

    # 2. Codex が読む runtime を toolkit layer + repo layer から再生成する。
    Remove-AndRecreateDirectory -Path $runtimeRoot -DryRun $DryRun
    Copy-DirectoryContents -Source $toolkitLayerRoot -Destination $runtimeRoot -DryRun $DryRun
    Copy-DirectoryContents -Source $repoSourceRoot -Destination $runtimeRoot -DryRun $DryRun

    # 3. Codex 標準 hook の入口を dispatcher へ向け、AGENTS.md の管理ブロックも同期する。
    Write-HooksJson -RepoRoot $RepoRoot -HookEntrypoint ([string]$manifest.hookEntrypoint) -DryRun $DryRun
    Write-HookDispatcher -RepoRoot $RepoRoot -HookDispatcher ([string]$manifest.hookDispatcher) -ToolkitRoot $ToolkitRoot -DryRun $DryRun
    Update-RepoAgents -RepoRoot $RepoRoot -ToolkitRoot $ToolkitRoot -Profiles $profiles -DryRun $DryRun

    $commit = Get-ToolkitCommit -ToolkitRoot $ToolkitRoot
    Set-ManifestProperty -Manifest $manifest -Name 'toolkitCommit' -Value $commit
    if ($null -eq $ManifestObject) {
        Write-JsonFile -Path (Join-Path $RepoRoot '.codex-kit/manifest.json') -Value $manifest -DryRun $DryRun
    }

    if ($overrides.Count -gt 0) {
        Write-Step "repo レイヤーで上書き: $($overrides.Count) 件"
        $overrides | Sort-Object | ForEach-Object {
            Write-Host "  - $_"
        }
    }

    Write-Step 'sync 完了'
}

function Invoke-Init {
    param(
        [pscustomobject]$Parsed,
        [string]$ToolkitRoot
    )

    # init は manifest を作り、repo layer の初期形を置き、必要ならそのまま sync まで行う。
    $repoRoot = Get-RepoRootFromOptions -Parsed $Parsed
    $dryRun = Test-Option -Parsed $Parsed -Name 'dry-run'
    $force = Test-Option -Parsed $Parsed -Name 'force'
    $noSync = Test-Option -Parsed $Parsed -Name 'no-sync'
    $preset = Get-Option -Parsed $Parsed -Name 'preset' -Default $null
    $profiles = @(Resolve-SelectedProfiles -Parsed $Parsed -ToolkitRoot $ToolkitRoot)
    $manifestPath = Join-Path $repoRoot '.codex-kit/manifest.json'

    if ((Test-Path -LiteralPath $manifestPath) -and -not $force) {
        throw "manifest は既にある。上書きするなら --force を付けて。path: $manifestPath"
    }

    $manifest = New-Manifest -Profiles $profiles -Preset $preset -ToolkitCommit (Get-ToolkitCommit -ToolkitRoot $ToolkitRoot)

    Write-Host 'codex-kit init'
    Write-Step "repo: $repoRoot"
    Write-Step "profiles: $($profiles -join ', ')"
    Write-JsonFile -Path $manifestPath -Value $manifest -DryRun $dryRun
    Initialize-RepoSourceRoot -RepoRoot $repoRoot -ToolkitRoot $ToolkitRoot -DryRun $dryRun
    Update-GitignoreFromTemplate -RepoRoot $repoRoot -ToolkitRoot $ToolkitRoot -DryRun $dryRun
    Update-RepoAgents -RepoRoot $repoRoot -ToolkitRoot $ToolkitRoot -Profiles $profiles -DryRun $dryRun

    if (-not $noSync) {
        Invoke-Sync -RepoRoot $repoRoot -ToolkitRoot $ToolkitRoot -DryRun $dryRun -ManifestObject $manifest
    }
}
