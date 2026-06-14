# codex-kit CLI の file IO helper。
# path の安全確認は呼び出し側で済ませ、ここでは dry-run と実 IO の差だけを扱う。

function Remove-AndRecreateDirectory {
    param(
        [string]$Path,
        [bool]$DryRun
    )

    # sync の generated layer を作り直すための helper。
    # 呼び出し前に Assert-ManagedDirectory を通す前提。
    if ($DryRun) {
        Write-Step "削除して再生成: $Path"
        return
    }

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }

    [void](New-Item -ItemType Directory -Path $Path -Force)
}

function Ensure-Directory {
    param(
        [string]$Path,
        [bool]$DryRun
    )

    if ($DryRun) {
        Write-Step "ディレクトリ作成: $Path"
        return
    }

    [void](New-Item -ItemType Directory -Path $Path -Force)
}

function Write-JsonFile {
    param(
        [string]$Path,
        [object]$Value,
        [bool]$DryRun
    )

    # manifest / hooks.json は機械が読むため、ConvertTo-Json で構造を保って書き出す。
    if ($DryRun) {
        Write-Step "JSON 更新: $Path"
        return
    }

    $parent = Split-Path -Parent $Path
    [void](New-Item -ItemType Directory -Path $parent -Force)
    $json = $Value | ConvertTo-Json -Depth 40
    Set-Content -LiteralPath $Path -Value ($json + "`n") -Encoding UTF8
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination,
        [bool]$DryRun,
        [bool]$NoOverwrite = $false
    )

    # toolkit layer 生成と repo template 初期化の両方で使う。
    # NoOverwrite は repo 固有の叩き台を既存ファイルで上書きしないためのもの。
    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    if ($DryRun) {
        Write-Step "コピー: $Source -> $Destination"
        return
    }

    [void](New-Item -ItemType Directory -Path $Destination -Force)
    $items = Get-ChildItem -LiteralPath $Source -Force -Recurse
    foreach ($item in $items) {
        $relative = ConvertTo-RelativePath -BasePath $Source -Path $item.FullName
        $target = Join-Path $Destination $relative

        if ($item.PSIsContainer) {
            [void](New-Item -ItemType Directory -Path $target -Force)
            continue
        }

        if ($NoOverwrite -and (Test-Path -LiteralPath $target)) {
            continue
        }

        $parent = Split-Path -Parent $target
        [void](New-Item -ItemType Directory -Path $parent -Force)
        Copy-Item -LiteralPath $item.FullName -Destination $target -Force
    }
}
