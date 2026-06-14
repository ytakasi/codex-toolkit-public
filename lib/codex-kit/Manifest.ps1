# codex-kit CLI の manifest と toolkit state。
# manifest は対象 repo の選択 profile と生成先 root を記録する小さな契約ファイル。

function Get-ToolkitCommit {
    param([string]$ToolkitRoot)

    # 配布元 toolkit の revision を manifest に残し、status で更新差分を見やすくする。
    $commit = & git -C $ToolkitRoot rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($commit -join ''))) {
        return [string](@($commit)[0])
    }

    $global:LASTEXITCODE = 0
    return $null
}

function Read-Manifest {
    param([string]$RepoRoot)

    $manifestPath = Join-Path $RepoRoot '.codex-kit/manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "manifest がない。先に codex-kit init を実行して。path: $manifestPath"
    }

    return Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
}

function Get-ManifestProfiles {
    param([object]$Manifest)

    # global は常に基礎 profile として含める。manifest が古くても最低限の共通 skill を落とさない。
    $profiles = New-Object 'System.Collections.Generic.List[string]'
    Add-Unique -List $profiles -Value 'global'
    foreach ($profile in @($Manifest.profiles)) {
        Add-Unique -List $profiles -Value ([string]$profile)
    }

    return $profiles
}

function Set-ManifestProperty {
    param(
        [object]$Manifest,
        [string]$Name,
        [object]$Value
    )

    # ConvertFrom-Json で得た PSCustomObject に対し、既存 key 更新と新規 key 追加を同じ関数で扱う。
    if ($Manifest.PSObject.Properties.Name -contains $Name) {
        $Manifest.$Name = $Value
    } else {
        $Manifest | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function New-Manifest {
    param(
        [string[]]$Profiles,
        [string]$Preset,
        [string]$ToolkitCommit
    )

    # 生成先 root は現状固定値で始める。
    # sync 側で再度 guard し、manifest 手編集による危険な削除先変更を防ぐ。
    [ordered]@{
        version = 1
        manifestPreset = if ([string]::IsNullOrWhiteSpace($Preset)) { 'custom' } else { $Preset }
        profiles = @($Profiles)
        toolkitSourceRoot = 'agent-skills/toolkit'
        repoSourceRoot = 'agent-skills/repo'
        generatedRuntimeRoot = '.agents'
        hookEntrypoint = '.codex/hooks.json'
        hookDispatcher = '.codex/hooks/codex-kit-dispatch.ps1'
        toolkitCommit = $ToolkitCommit
    }
}
