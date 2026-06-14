# codex-kit CLI の smoke test。
# 一時 repo を作って init / sync / status / doctor / hook dispatch を確認する。

param(
    [switch]$KeepTemp,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:CliPath = Join-Path $script:RepoRoot 'bin/codex-kit.ps1'
$script:CliCmdPath = Join-Path $script:RepoRoot 'bin/codex-kit.cmd'
$script:InstallPath = Join-Path $script:RepoRoot 'scripts/install-codex-kit.ps1'
$script:RunningOnWindows = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
$script:TempRepos = New-Object 'System.Collections.Generic.List[string]'

function Write-TestStep {
    param([string]$Message)

    Write-Host "[test] $Message"
}

function Convert-OutputToText {
    param([object[]]$Output)

    if ($null -eq $Output -or $Output.Count -eq 0) {
        return ''
    }

    return (($Output | ForEach-Object { [string]$_ }) -join "`n")
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-PathExists {
    param([string]$Path)

    Assert-True -Condition (Test-Path -LiteralPath $Path) -Message "path が存在しない: $Path"
}

function Assert-PathMissing {
    param([string]$Path)

    Assert-True -Condition (-not (Test-Path -LiteralPath $Path)) -Message "path が存在してはいけない: $Path"
}

function Assert-TextContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    Assert-True -Condition ($Text -match $Pattern) -Message $Message
}

function ConvertTo-RegexLiteral {
    param([string]$Text)

    return [regex]::Escape($Text)
}

function Assert-TextNotContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    Assert-True -Condition ($Text -notmatch $Pattern) -Message $Message
}

function Invoke-ProcessChecked {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$InputText = '',
        [int]$ExpectedExitCode = 0,
        [string]$Label = $FilePath,
        [string]$WorkingDirectory = ''
    )

    Write-TestStep "$Label $($Arguments -join ' ')"

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    foreach ($argument in $Arguments) {
        [void]$psi.ArgumentList.Add($argument)
    }
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $psi.WorkingDirectory = $WorkingDirectory
    }

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not [string]::IsNullOrEmpty($InputText)) {
        $process.StandardInput.Write($InputText)
    }
    $process.StandardInput.Close()

    if (-not $process.WaitForExit(120000)) {
        try {
            $process.Kill()
        } catch {
        }
        throw "command が timeout した: $Label $($Arguments -join ' ')"
    }

    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $combined = ($stdout + $stderr).TrimEnd()
    if ($VerboseOutput -and -not [string]::IsNullOrWhiteSpace($combined)) {
        $combined | Write-Host
    }

    if ($process.ExitCode -ne $ExpectedExitCode) {
        if (-not $VerboseOutput -and -not [string]::IsNullOrWhiteSpace($combined)) {
            $combined | Write-Host
        }
        throw "exit code が違う: expected=$ExpectedExitCode actual=$($process.ExitCode) command=$Label $($Arguments -join ' ')"
    }

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdout
        Stderr = $stderr
        Text = $combined
    }
}

function Invoke-CodexKit {
    param(
        [string[]]$Arguments,
        [int]$ExpectedExitCode = 0,
        [string]$InputText = ''
    )

    Invoke-ProcessChecked -FilePath 'pwsh' -Arguments (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:CliPath) + $Arguments) -ExpectedExitCode $ExpectedExitCode -InputText $InputText -Label 'codex-kit'
}

function New-SmokeRepo {
    param([string]$Name)

    $path = Join-Path $script:RepoRoot (".tmp-codex-kit-$Name-" + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path)
    [void]$script:TempRepos.Add($path)

    $result = Invoke-ProcessChecked -FilePath 'git' -Arguments @('-C', $path, 'init') -Label 'git'
    Assert-TextContains -Text $result.Text -Pattern 'Initialized empty Git repository|Reinitialized existing Git repository' -Message 'git init の出力が想定外。'
    return $path
}

function Assert-SafeTempPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $workspaceWithSep = $script:RepoRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    Assert-True -Condition $resolved.StartsWith($workspaceWithSep, [System.StringComparison]::OrdinalIgnoreCase) -Message "cleanup target が workspace 外: $resolved"
    Assert-True -Condition ((Split-Path -Leaf $resolved) -like '.tmp-codex-kit-*') -Message "cleanup target 名が想定外: $resolved"
}

function Remove-SmokeRepo {
    param([string]$Repo)

    Assert-SafeTempPath -Path $Repo
    $maxAttempts = 8
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Remove-Item -LiteralPath $Repo -Recurse -Force -ErrorAction Stop
            return
        } catch {
            if ($attempt -eq $maxAttempts) {
                throw
            }

            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }
}

function Remove-SmokeRepos {
    if ($KeepTemp) {
        Write-TestStep 'KeepTemp 指定のため一時 repo を残す。'
        $script:TempRepos | ForEach-Object { Write-Host "  $_" }
        return
    }

    foreach ($repo in $script:TempRepos) {
        if (-not (Test-Path -LiteralPath $repo)) {
            continue
        }

        Remove-SmokeRepo -Repo $repo
    }
}

function Read-Manifest {
    param([string]$Repo)

    $manifestPath = Join-Path $Repo '.codex-kit/manifest.json'
    Assert-PathExists -Path $manifestPath
    return Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
}

function Write-Manifest {
    param(
        [string]$Repo,
        [object]$Manifest
    )

    $manifestPath = Join-Path $Repo '.codex-kit/manifest.json'
    $json = $Manifest | ConvertTo-Json -Depth 40
    Set-Content -LiteralPath $manifestPath -Value ($json + "`n") -Encoding UTF8
}

function Assert-GitignoreContainsGeneratedPaths {
    param([string]$Repo)

    $gitignorePath = Join-Path $Repo '.gitignore'
    Assert-PathExists -Path $gitignorePath
    $lines = @(Get-Content -LiteralPath $gitignorePath)
    Assert-True -Condition ($lines -contains 'agent-skills/toolkit/') -Message '.gitignore に agent-skills/toolkit/ がない。'
    Assert-True -Condition ($lines -contains '.agents/') -Message '.gitignore に .agents/ がない。'
    Assert-True -Condition ($lines -contains '.codex-kit/cache/') -Message '.gitignore に .codex-kit/cache/ がない。'
}

function Assert-AgentsManagedBlock {
    param([string]$Repo)

    $agentsPath = Join-Path $Repo 'AGENTS.md'
    Assert-PathExists -Path $agentsPath
    $text = Get-Content -Raw -LiteralPath $agentsPath
    Assert-TextContains -Text $text -Pattern '<!-- codex-kit:repo-rules:start -->' -Message 'AGENTS.md に managed block start がない。'
    Assert-TextContains -Text $text -Pattern '<!-- codex-kit:repo-rules:end -->' -Message 'AGENTS.md に managed block end がない。'
    Assert-TextContains -Text $text -Pattern '`agent-skills/repo`' -Message 'AGENTS.md に repo 正本ルートの説明がない。'
}

function Assert-BasicRuntime {
    param([string]$Repo)

    Assert-PathExists -Path (Join-Path $Repo '.agents/skills/work-mode-triage/SKILL.md')
    Assert-PathExists -Path (Join-Path $Repo 'agent-skills/toolkit/skills/work-mode-triage/SKILL.md')
    Assert-PathExists -Path (Join-Path $Repo '.codex/hooks.json')
    Assert-PathExists -Path (Join-Path $Repo '.codex/hooks/codex-kit-dispatch.ps1')
    Assert-PathMissing -Path (Join-Path $Repo '.agents/skills/scheduled-batch-hardening/SKILL.md')
}

function Assert-ScheduledBatchRuntime {
    param([string]$Repo)

    $expectedSkills = @('scheduled-batch-hardening')

    foreach ($skill in $expectedSkills) {
        Assert-PathExists -Path (Join-Path $Repo ".agents/skills/$skill/SKILL.md")
    }
}

function Assert-ProfileRuntimeSkills {
    param(
        [string]$Repo,
        [string[]]$Skills
    )

    foreach ($skill in $Skills) {
        Assert-PathExists -Path (Join-Path $Repo ".agents/skills/$skill/SKILL.md")
    }
}

function Assert-AndroidMobileRuntime {
    param([string]$Repo)

    Assert-PathExists -Path (Join-Path $Repo '.agents/skills/android-mobile-risk-burndown/SKILL.md')
    Assert-PathExists -Path (Join-Path $Repo 'agent-skills/toolkit/skills/android-mobile-risk-burndown/SKILL.md')
    Assert-PathMissing -Path (Join-Path $Repo '.agents/skills/scheduled-batch-hardening/SKILL.md')
}

function Invoke-HookDispatcher {
    param(
        [string]$Repo,
        [hashtable]$Payload,
        [int]$ExpectedExitCode
    )

    $dispatcher = Join-Path $Repo '.codex/hooks/codex-kit-dispatch.ps1'
    Assert-PathExists -Path $dispatcher
    $json = $Payload | ConvertTo-Json -Compress -Depth 20
    Invoke-ProcessChecked -FilePath 'pwsh' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-EventName', 'PreToolUse') -InputText $json -ExpectedExitCode $ExpectedExitCode -Label 'hook-dispatch'
}

function Test-RepoLayerOverride {
    param([string]$Repo)

    $repoSkill = Join-Path $Repo 'agent-skills/repo/skills/work-mode-triage'
    [void](New-Item -ItemType Directory -Path $repoSkill -Force)
    Set-Content -LiteralPath (Join-Path $repoSkill 'SKILL.md') -Value @'
---
name: work-mode-triage
description: repo override smoke test
---

# Repo Override Smoke Test
'@ -Encoding UTF8

    $sync = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo)
    Assert-TextContains -Text $sync.Text -Pattern 'repo レイヤーで上書き: 1 件' -Message 'sync が repo レイヤー上書きを表示していない。'
    Assert-TextContains -Text $sync.Text -Pattern 'skills\\work-mode-triage\\SKILL\.md' -Message 'sync が上書き対象 skill を表示していない。'

    $runtimeSkill = Join-Path $Repo '.agents/skills/work-mode-triage/SKILL.md'
    $runtimeText = Get-Content -Raw -LiteralPath $runtimeSkill
    Assert-TextContains -Text $runtimeText -Pattern 'Repo Override Smoke Test' -Message 'repo レイヤーの skill が runtime へ後勝ち反映されていない。'

    $status = Invoke-CodexKit -Arguments @('status', '--repo-root', $Repo)
    Assert-TextContains -Text $status.Text -Pattern 'repo レイヤー上書き: 1 件' -Message 'status が repo レイヤー上書きを表示していない。'
}

function Test-SyncRejectsManagedPathChanges {
    param([string]$Repo)

    $manifest = Read-Manifest -Repo $Repo
    $originalToolkitSourceRoot = [string]$manifest.toolkitSourceRoot
    $originalGeneratedRuntimeRoot = [string]$manifest.generatedRuntimeRoot
    $originalRepoSourceRoot = [string]$manifest.repoSourceRoot

    try {
        $manifest.generatedRuntimeRoot = '.'
        Write-Manifest -Repo $Repo -Manifest $manifest
        $rootRuntime = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo, '--dry-run') -ExpectedExitCode 1
        Assert-TextContains -Text $rootRuntime.Text -Pattern '安全のため、現在は \.agents だけを管理対象にする' -Message 'generatedRuntimeRoot=. を拒否していない。'

        $manifest.generatedRuntimeRoot = '../outside-runtime'
        Write-Manifest -Repo $Repo -Manifest $manifest
        $outsideRuntime = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo, '--dry-run') -ExpectedExitCode 1
        Assert-TextContains -Text $outsideRuntime.Text -Pattern '安全のため、現在は \.agents だけを管理対象にする' -Message 'generatedRuntimeRoot=../outside を拒否していない。'

        $manifest.generatedRuntimeRoot = $originalGeneratedRuntimeRoot
        $manifest.toolkitSourceRoot = 'agent-skills'
        Write-Manifest -Repo $Repo -Manifest $manifest
        $wrongToolkitRoot = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo, '--dry-run') -ExpectedExitCode 1
        Assert-TextContains -Text $wrongToolkitRoot.Text -Pattern '安全のため、現在は agent-skills/toolkit だけを管理対象にする' -Message 'toolkitSourceRoot=agent-skills を拒否していない。'

        $manifest.toolkitSourceRoot = $originalToolkitSourceRoot
        $manifest.repoSourceRoot = '../outside-repo-source'
        Write-Manifest -Repo $Repo -Manifest $manifest
        $outsideRepoSource = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo, '--dry-run') -ExpectedExitCode 1
        Assert-TextContains -Text $outsideRepoSource.Text -Pattern 'repo 外のパスは使えない' -Message 'repoSourceRoot=../outside を拒否していない。'
    } finally {
        $manifest.toolkitSourceRoot = $originalToolkitSourceRoot
        $manifest.generatedRuntimeRoot = $originalGeneratedRuntimeRoot
        $manifest.repoSourceRoot = $originalRepoSourceRoot
        Write-Manifest -Repo $Repo -Manifest $manifest
    }
}

function Test-ReparsePointIsRejected {
    param([string]$Repo)

    $toolkitLayer = Join-Path $Repo 'agent-skills/toolkit'
    $junctionTarget = Join-Path $Repo 'agent-skills/toolkit-junction-target'

    if (Test-Path -LiteralPath $toolkitLayer) {
        Remove-Item -LiteralPath $toolkitLayer -Recurse -Force
    }
    [void](New-Item -ItemType Directory -Path $junctionTarget -Force)

    try {
        [void](New-Item -ItemType Junction -Path $toolkitLayer -Target $junctionTarget -ErrorAction Stop)
    } catch {
        Write-TestStep "junction を作れないため reparse point 拒否テストを skip: $($_.Exception.Message)"
        [void](New-Item -ItemType Directory -Path $toolkitLayer -Force)
        return
    }

    $result = Invoke-CodexKit -Arguments @('sync', '--repo-root', $Repo, '--dry-run') -ExpectedExitCode 1
    Assert-TextContains -Text $result.Text -Pattern 'reparse point / symlink は削除対象にできない' -Message 'reparse point の toolkit layer を拒否していない。'

    Remove-Item -LiteralPath $toolkitLayer -Force
    [void](New-Item -ItemType Directory -Path $toolkitLayer -Force)
}

function Test-ProfileBasic {
    $repo = New-SmokeRepo -Name 'basic'

    Invoke-CodexKit -Arguments @('init', '--repo-root', $repo, '--preset', 'basic', '--non-interactive') | Out-Null

    $manifest = Read-Manifest -Repo $repo
    Assert-True -Condition ($manifest.manifestPreset -eq 'basic') -Message 'basic manifestPreset が違う。'
    Assert-True -Condition (@($manifest.profiles) -contains 'global') -Message 'basic manifest に global profile がない。'
    Assert-True -Condition (@($manifest.profiles).Count -eq 1) -Message 'basic manifest に global 以外の profile が入っている。'

    Assert-GitignoreContainsGeneratedPaths -Repo $repo
    Assert-AgentsManagedBlock -Repo $repo
    Assert-BasicRuntime -Repo $repo

    $status = Invoke-CodexKit -Arguments @('status', '--repo-root', $repo)
    Assert-TextContains -Text $status.Text -Pattern 'profiles: global' -Message 'status に global profile が出ていない。'

    $syncDryRun = Invoke-CodexKit -Arguments @('sync', '--repo-root', $repo, '--dry-run')
    Assert-TextContains -Text $syncDryRun.Text -Pattern '削除して再生成: .*agent-skills\\toolkit' -Message 'sync dry-run に toolkit layer 再生成が出ていない。'
    Assert-TextContains -Text $syncDryRun.Text -Pattern '削除して再生成: .*\\.agents' -Message 'sync dry-run に runtime 再生成が出ていない。'

    $doctor = Invoke-CodexKit -Arguments @('doctor', '--repo-root', $repo)
    Assert-TextContains -Text $doctor.Text -Pattern 'manifest: OK' -Message 'doctor が manifest OK を出していない。'

    $updateDryRun = Invoke-CodexKit -Arguments @('update', '--repo-root', $repo, '--dry-run')
    Assert-TextContains -Text $updateDryRun.Text -Pattern 'git pull --ff-only を実行予定' -Message 'update dry-run が self-update 予定を出していない。'

    $blockPayload = @{
        tool_name = 'shell_command'
        cwd = $repo
        tool_input = @{
            command = 'Set-Content .agents/test.txt hello'
        }
    }
    $block = Invoke-HookDispatcher -Repo $repo -Payload $blockPayload -ExpectedExitCode 2
    Assert-TextContains -Text $block.Text -Pattern '生成・管理する場所への直接変更を止めた' -Message 'generated layer guard の block message がない。'

    $allowPayload = @{
        tool_name = 'shell_command'
        cwd = $repo
        tool_input = @{
            command = 'Get-ChildItem'
        }
    }
    Invoke-HookDispatcher -Repo $repo -Payload $allowPayload -ExpectedExitCode 0 | Out-Null

    $gitAddAllPayload = @{
        tool_name = 'shell_command'
        cwd = $repo
        tool_input = @{
            command = 'git add .'
        }
    }
    Invoke-HookDispatcher -Repo $repo -Payload $gitAddAllPayload -ExpectedExitCode 0 | Out-Null

    $hooksJsonStagePayload = @{
        tool_name = 'shell_command'
        cwd = $repo
        tool_input = @{
            command = 'git add .codex/hooks.json'
        }
    }
    $hooksJsonBlock = Invoke-HookDispatcher -Repo $repo -Payload $hooksJsonStagePayload -ExpectedExitCode 2
    Assert-TextContains -Text $hooksJsonBlock.Text -Pattern '生成・管理する場所への直接変更を止めた' -Message 'generated layer guard が .codex/hooks.json の直指定 stage を止めていない。'

    $dispatcherStagePayload = @{
        tool_name = 'shell_command'
        cwd = $repo
        tool_input = @{
            command = 'git add .codex/hooks/codex-kit-dispatch.ps1'
        }
    }
    $dispatcherBlock = Invoke-HookDispatcher -Repo $repo -Payload $dispatcherStagePayload -ExpectedExitCode 2
    Assert-TextContains -Text $dispatcherBlock.Text -Pattern '生成・管理する場所への直接変更を止めた' -Message 'generated layer guard が dispatcher の直指定 stage を止めていない。'

    Test-RepoLayerOverride -Repo $repo
    Test-SyncRejectsManagedPathChanges -Repo $repo
    Test-ReparsePointIsRejected -Repo $repo
}

function Test-ProfileScheduledBatch {
    $repo = New-SmokeRepo -Name 'scheduled-batch'

    Invoke-CodexKit -Arguments @('init', '--repo-root', $repo, '--preset', 'scheduled-batch', '--non-interactive') | Out-Null

    $manifest = Read-Manifest -Repo $repo
    $expectedProfiles = @('global', 'scheduled-batch')
    foreach ($profile in $expectedProfiles) {
        Assert-True -Condition (@($manifest.profiles) -contains $profile) -Message "scheduled-batch manifest に $profile がない。"
    }
    Assert-True -Condition (@($manifest.profiles).Count -eq $expectedProfiles.Count) -Message 'scheduled-batch preset に追加機能 profile が混ざっている。'

    Assert-GitignoreContainsGeneratedPaths -Repo $repo
    Assert-AgentsManagedBlock -Repo $repo
    Assert-ScheduledBatchRuntime -Repo $repo

    $status = Invoke-CodexKit -Arguments @('status', '--repo-root', $repo)
    Assert-TextContains -Text $status.Text -Pattern 'profiles: global, scheduled-batch' -Message 'scheduled-batch status の profile 表示が違う。'
}

function Test-ProfileAndroidMobile {
    $repo = New-SmokeRepo -Name 'android-mobile'

    Invoke-CodexKit -Arguments @('init', '--repo-root', $repo, '--preset', 'android-mobile', '--non-interactive') | Out-Null

    $manifest = Read-Manifest -Repo $repo
    Assert-True -Condition ($manifest.manifestPreset -eq 'android-mobile') -Message 'android-mobile manifestPreset が違う。'
    foreach ($profile in @('global', 'android-mobile')) {
        Assert-True -Condition (@($manifest.profiles) -contains $profile) -Message "android-mobile manifest に $profile がない。"
    }

    Assert-GitignoreContainsGeneratedPaths -Repo $repo
    Assert-AgentsManagedBlock -Repo $repo
    Assert-AndroidMobileRuntime -Repo $repo

    $status = Invoke-CodexKit -Arguments @('status', '--repo-root', $repo)
    Assert-TextContains -Text $status.Text -Pattern 'profiles: global, android-mobile' -Message 'android-mobile status の profile 表示が違う。'
}

function Test-HardenDryRun {
    $repo = New-SmokeRepo -Name 'harden'
    $target = Join-Path $repo 'requirements.toml'
    $result = Invoke-CodexKit -Arguments @('harden', '--dry-run', '--target', $target)

    Assert-TextContains -Text $result.Text -Pattern 'codex-kit harden --dry-run' -Message 'harden dry-run の見出しが出ていない。'
    Assert-TextContains -Text $result.Text -Pattern (ConvertTo-RegexLiteral "requirements.toml 反映候補: $target") -Message 'harden dry-run が target を表示していない。'
    Assert-TextContains -Text $result.Text -Pattern 'requirements\.toml: missing' -Message 'harden dry-run が target の missing 状態を表示していない。'
    Assert-TextContains -Text $result.Text -Pattern 'permissions\.filesystem\.deny_read' -Message 'harden dry-run が deny_read の公式確認結果を表示していない。'
    Assert-TextContains -Text $result.Text -Pattern 'native Windows|repo hook' -Message 'harden dry-run が Windows / repo hook 併用の注意を表示していない。'
}

function Test-RelativeRepoRootResolution {
    $repo = New-SmokeRepo -Name 'relative-root'
    $leaf = Split-Path -Leaf $repo
    $relativeRepo = ".\$leaf"
    $expectedRepoPattern = ConvertTo-RegexLiteral "- repo: $repo"
    $wrapperPath = Join-Path $repo 'invoke-codex-kit-from-location.ps1'

    Set-Content -LiteralPath $wrapperPath -Encoding UTF8 -Value @'
param(
    [string]$PowerShellLocation,
    [string]$CliPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArguments
)

Set-Location -LiteralPath $PowerShellLocation
& $CliPath @CliArguments
exit $LASTEXITCODE
'@

    $result = Invoke-ProcessChecked `
        -FilePath 'pwsh' `
        -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $wrapperPath, $script:RepoRoot, $script:CliPath, 'init', '--repo-root', $relativeRepo, '--preset', 'basic', '--dry-run', '--no-sync') `
        -WorkingDirectory $HOME `
        -Label 'codex-kit mismatched-cwd'
    Assert-TextContains -Text $result.Text -Pattern $expectedRepoPattern -Message 'relative --repo-root が PowerShell の現在地基準で解決されていない。'
}

function Test-InteractiveInit {
    $repo = New-SmokeRepo -Name 'interactive'
    $answers = @(
        '2,8 9 10' # 定期実行 + 外部データ取得 + 通知 + 設定管理
    ) -join "`n"
    $answers = $answers + "`n"

    $result = Invoke-CodexKit -Arguments @('init', '--repo-root', $repo) -InputText $answers
    Assert-TextContains -Text $result.Text -Pattern '作るもの・盛り込む機能に近い番号を選んでください。' -Message 'interactive init の説明文が出ていない。'
    Assert-TextContains -Text $result.Text -Pattern '複数ある時は、カンマかスペースで区切って入力できます。' -Message 'interactive init の複数選択案内が出ていない。'
    Assert-TextContains -Text $result.Text -Pattern '  4. Godot 4 / C#ゲーム' -Message 'interactive init の選択肢番号が想定外。'
    Assert-TextContains -Text $result.Text -Pattern ' 11. デプロイ / migration / IaC / DB権限変更' -Message 'interactive init の選択肢末尾が想定外。'
    Assert-TextNotContains -Text $result.Text -Pattern 'Webアプリ / SaaS' -Message 'interactive init に Webアプリ / SaaS 選択肢が残っている。'
    Assert-TextNotContains -Text $result.Text -Pattern '番号（複数可。例: 5,2,6） [1]' -Message 'interactive init に旧デフォルト表記が残っている。'
    Assert-TextNotContains -Text $result.Text -Pattern '追加で盛り込む機能' -Message 'interactive init に旧追加質問が残っている。'
    Assert-TextContains -Text $result.Text -Pattern '選ばれた profile: global, scheduled-batch, provider-integration, notifications, persisted-config' -Message 'interactive init の profile 組み立て表示が想定外。'

    $manifest = Read-Manifest -Repo $repo
    Assert-True -Condition ($manifest.manifestPreset -eq 'custom') -Message 'interactive init の manifestPreset は custom の想定。'
    foreach ($profile in @('global', 'scheduled-batch', 'provider-integration', 'notifications', 'persisted-config')) {
        Assert-True -Condition (@($manifest.profiles) -contains $profile) -Message "interactive manifest に $profile がない。"
    }

    Assert-ScheduledBatchRuntime -Repo $repo
    Assert-ProfileRuntimeSkills -Repo $repo -Skills @(
        'provider-dry-run',
        'discord-alert-message-polish',
        'persisted-settings-change'
    )
}

try {
    Assert-PathExists -Path $script:CliPath
    Assert-PathExists -Path $script:InstallPath
    if ($script:RunningOnWindows) {
        Assert-PathExists -Path $script:CliCmdPath
    }

    Invoke-CodexKit -Arguments @('--help') | Out-Null
    Invoke-ProcessChecked -FilePath 'pwsh' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:InstallPath, '-DryRun') -Label 'install-codex-kit' | Out-Null
    if ($script:RunningOnWindows) {
        Invoke-ProcessChecked -FilePath 'cmd.exe' -Arguments @('/c', $script:CliCmdPath, '--help') -Label 'codex-kit.cmd' | Out-Null
    }
    Invoke-CodexKit -Arguments @('list-profiles') | Out-Null
    Invoke-CodexKit -Arguments @('harden', '--dry-run') | Out-Null

    Test-HardenDryRun
    Test-ProfileBasic
    Test-ProfileAndroidMobile
    Test-ProfileScheduledBatch
    Test-RelativeRepoRootResolution
    Test-InteractiveInit

    Write-Host 'codex-kit smoke test passed.'
} finally {
    Remove-SmokeRepos
}
