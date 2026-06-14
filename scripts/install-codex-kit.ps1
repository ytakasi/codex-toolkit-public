[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet('User', 'Process')]
    [string]$Scope = 'User'
)

# codex-kit を PATH から呼べるようにする installer。
# 実体は bin/codex-kit.cmd / codex-kit.ps1 なので、この script は PATH への追記だけを担当する。

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolkitRoot = Split-Path -Parent $scriptDir
$binPath = [System.IO.Path]::GetFullPath((Join-Path $toolkitRoot 'bin'))
$shimPath = Join-Path $binPath 'codex-kit.cmd'
$pathSeparator = [string][System.IO.Path]::PathSeparator

function Write-Step {
    param([string]$Message)

    Write-Host "- $Message"
}

function Normalize-PathText {
    param([string]$Path)

    # PATH 比較では末尾 slash や相対 path の差を吸収する。
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    try {
        return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    } catch {
        return $Path.Trim().TrimEnd('\', '/')
    }
}

function Split-PathList {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @($Value -split [regex]::Escape($pathSeparator) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-PathListContains {
    param(
        [string]$Value,
        [string]$TargetPath
    )

    # PATH は文字列列挙なので、正規化してから case-insensitive に比較する。
    $target = Normalize-PathText $TargetPath
    foreach ($entry in Split-PathList $Value) {
        if ((Normalize-PathText $entry).Equals($target, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Add-PathEntry {
    param(
        [string]$Value,
        [string]$Entry
    )

    $entries = New-Object 'System.Collections.Generic.List[string]'
    foreach ($current in Split-PathList $Value) {
        [void]$entries.Add($current)
    }
    [void]$entries.Add($Entry)
    return [string]::Join($pathSeparator, $entries)
}

if (-not (Test-Path -LiteralPath $shimPath)) {
    throw "codex-kit.cmd が見つからない: $shimPath"
}

$currentPath = if ($Scope -eq 'User') {
    [Environment]::GetEnvironmentVariable('Path', 'User')
} else {
    $env:PATH
}

$alreadyInstalled = Test-PathListContains -Value $currentPath -TargetPath $binPath

# User scope は次の terminal から効く。Process scope は今の terminal だけで試すための安全な導線。
Write-Host 'codex-kit install'
Write-Step "toolkit root: $toolkitRoot"
Write-Step "bin path: $binPath"
Write-Step "scope: $Scope"
if ($DryRun) {
    Write-Step 'mode: dry-run'
}

if ($alreadyInstalled) {
    Write-Step 'PATH は既に設定済み。'
    return
}

$nextPath = Add-PathEntry -Value $currentPath -Entry $binPath

if ($DryRun) {
    Write-Step "PATH に追加予定: $binPath"
    Write-Step '実反映する場合は -DryRun を外す。現在の terminal だけで試す場合は -Scope Process を使う。'
    return
}

if ($Scope -eq 'Process') {
    $env:PATH = $nextPath
    Write-Step '現在の PowerShell process の PATH に追加した。'
    Write-Step 'この terminal で codex-kit --help を試せる。'
    return
}

[Environment]::SetEnvironmentVariable('Path', $nextPath, 'User')
Write-Step 'User PATH に追加した。'
Write-Step '新しい terminal を開くと codex-kit を PATH から実行できる。'
