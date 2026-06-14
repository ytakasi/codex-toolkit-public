# codex-kit CLI の入口。
# 実装本体は lib/codex-kit 配下に分け、生成される hook 振り分けスクリプトは templates/codex-kit を正本にする。

$ErrorActionPreference = 'Stop'

# bin から repository root と lib root を逆算する。
# install 後に PATH から呼ばれても、このファイル位置を基準に実装を読み込む。
$script:CodexKitRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$script:CodexKitLibRoot = Join-Path $script:CodexKitRoot 'lib/codex-kit'

# lib は関数定義だけを持つ薄い module 群。
# PowerShell module 化する前段階なので、依存順に dot-source してから Invoke-Main に渡す。
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
    # 入口では例外を短く表示する。詳細な判断や副作用は lib 側の command 実装に閉じ込める。
    Invoke-Main -RawArgs $args
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
