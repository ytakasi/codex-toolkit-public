# codex-kit CLI の manifest と toolkit state。

function Get-ToolkitCommit {
    param([string]$ToolkitRoot)

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
