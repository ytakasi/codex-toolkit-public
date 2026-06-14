# codex-kit CLI の path 解決と安全確認。

function Get-FullPath {
    param(
        [string]$Path,
        [string]$BasePath = (Get-Location).ProviderPath
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'path が空。'
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Get-ToolkitRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_TOOLKIT_ROOT)) {
        return Get-FullPath $env:CODEX_TOOLKIT_ROOT
    }

    if (-not [string]::IsNullOrWhiteSpace($script:CodexKitRoot)) {
        return Get-FullPath $script:CodexKitRoot
    }

    return Get-FullPath (Join-Path $PSScriptRoot '../..')
}

function Get-ResourcesRoot {
    param([string]$ToolkitRoot)

    return Join-Path $ToolkitRoot 'resources'
}

function Get-GitRootOrCurrent {
    param([string]$StartPath)

    $full = Get-FullPath $StartPath
    $gitRoot = & git -C $full rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($gitRoot -join ''))) {
        return Get-FullPath (@($gitRoot)[0])
    }

    $global:LASTEXITCODE = 0
    return $full
}

function Get-RepoRootFromOptions {
    param([pscustomobject]$Parsed)

    $repoRootOption = Get-Option -Parsed $Parsed -Name 'repo-root' -Default $null
    if ([string]::IsNullOrWhiteSpace($repoRootOption)) {
        return Get-GitRootOrCurrent (Get-Location).Path
    }

    if (-not (Test-Path -LiteralPath $repoRootOption)) {
        throw "repo root が存在しない: $repoRootOption"
    }

    return Get-GitRootOrCurrent $repoRootOption
}

function Normalize-RelativePathText {
    param([string]$Path)

    return (($Path -replace '\\', '/') -replace '^(\./)+', '').Trim('/')
}

function ConvertTo-RelativePath {
    param(
        [string]$BasePath,
        [string]$Path
    )

    $baseFull = Get-FullPath $BasePath
    if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $baseFull = $baseFull + [System.IO.Path]::DirectorySeparatorChar
    }

    $pathFull = Get-FullPath $Path
    $baseUri = [Uri]$baseFull
    $pathUri = [Uri]$pathFull
    return ([Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Test-PathInside {
    param(
        [string]$BasePath,
        [string]$Path
    )

    $base = (Get-FullPath $BasePath).TrimEnd('\', '/')
    $target = (Get-FullPath $Path).TrimEnd('\', '/')
    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    return $target.Equals($base, $comparison) -or $target.StartsWith($base + [System.IO.Path]::DirectorySeparatorChar, $comparison)
}

function Get-RepoPath {
    param(
        [string]$RepoRoot,
        [string]$RelativePath
    )

    $path = Get-FullPath (Join-Path $RepoRoot $RelativePath)
    if (-not (Test-PathInside -BasePath $RepoRoot -Path $path)) {
        throw "repo 外のパスは使えない: $RelativePath"
    }

    return $path
}

function Assert-ManagedDirectory {
    param(
        [string]$RepoRoot,
        [string]$RelativePath,
        [string]$ExpectedRelativePath
    )

    $normalized = Normalize-RelativePathText $RelativePath
    $expected = Normalize-RelativePathText $ExpectedRelativePath
    if ($normalized -ne $expected) {
        throw "安全のため、現在は $ExpectedRelativePath だけを管理対象にする。指定値: $RelativePath"
    }

    $path = Get-RepoPath -RepoRoot $RepoRoot -RelativePath $RelativePath
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "reparse point / symlink は削除対象にできない: $path"
        }
    }

    return $path
}
