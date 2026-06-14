# codex-kit CLI の入口。
# 実装本体は lib/codex-kit 配下に分け、生成される hook 振り分けスクリプトは templates/codex-kit を正本にする。

$ErrorActionPreference = 'Stop'

$script:CodexKitRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$script:CodexKitLibRoot = Join-Path $script:CodexKitRoot 'lib/codex-kit'

foreach ($module in @(
    'Config.ps1',
    'Cli.ps1',
    'Paths.ps1',
    'Files.ps1',
    'Profiles.ps1',
    'Manifest.ps1',
    'RepoFiles.ps1',
    'Sync.ps1',
    'Commands.ps1'
)) {
    $modulePath = Join-Path $script:CodexKitLibRoot $module
    if (-not (Test-Path -LiteralPath $modulePath)) {
        [Console]::Error.WriteLine("codex-kit module が見つからない: $modulePath")
        exit 1
    }

    . $modulePath
}

try {
    Invoke-Main -RawArgs $args
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
