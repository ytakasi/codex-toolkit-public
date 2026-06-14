# codex-kit CLI の profile / preset 選択。
# UI の選択肢は人間向け、profile id は manifest と resources path 用として分ける。

function Get-AvailableProfiles {
    param([string]$ToolkitRoot)

    # global は resources/skills/profiles には置かず、必ず先頭に出す特別な基礎 profile。
    $resourcesRoot = Get-ResourcesRoot -ToolkitRoot $ToolkitRoot
    $profilesRoot = Join-Path $resourcesRoot 'skills/profiles'
    $profiles = New-Object 'System.Collections.Generic.List[string]'
    [void]$profiles.Add('global')
    if (Test-Path -LiteralPath $profilesRoot) {
        Get-ChildItem -LiteralPath $profilesRoot -Directory | Sort-Object Name | ForEach-Object {
            [void]$profiles.Add($_.Name)
        }
    }

    return $profiles
}

function Add-Unique {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if (-not $List.Contains($Value)) {
        [void]$List.Add($Value)
    }
}

function Add-ProfilesFromPreset {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$PresetName
    )

    if (-not $script:PresetProfiles.Contains($PresetName)) {
        throw "unknown preset: $PresetName"
    }

    $script:PresetProfiles[$PresetName] | ForEach-Object {
        Add-Unique -List $List -Value $_
    }
}

function Get-InteractiveProfileChoices {
    # Label は init の表示文言。Adds は説明用で、実際の追加処理は Add-ProfilesFromInteractiveChoice に集約する。
    @(
        [pscustomobject]@{ Id = '1'; Label = '基本だけ / まだ未定'; Adds = 'global' }
        [pscustomobject]@{ Id = '2'; Label = '定期実行 / 巡回バッチ'; Adds = 'scheduled-batch' }
        [pscustomobject]@{ Id = '3'; Label = '署名付きwebhook受信 / bot'; Adds = 'webhook-worker' }
        [pscustomobject]@{ Id = '4'; Label = 'Godot 4 / C#ゲーム'; Adds = 'godot-csharp' }
        [pscustomobject]@{ Id = '5'; Label = 'ノベルゲーム / 分岐シナリオ'; Adds = 'narrative' }
        [pscustomobject]@{ Id = '6'; Label = 'codex-toolkit 自体'; Adds = 'toolkit-maintenance + all profiles' }
        [pscustomobject]@{ Id = '7'; Label = 'Androidアプリ'; Adds = 'android-mobile' }
        [pscustomobject]@{ Id = '8'; Label = '外部API / Webページからデータ取得'; Adds = 'provider-integration' }
        [pscustomobject]@{ Id = '9'; Label = 'Discord / Slack / Teams / webhook 通知'; Adds = 'notifications' }
        [pscustomobject]@{ Id = '10'; Label = '設定画面 / 管理画面 / 設定ファイル / CLIオプション'; Adds = 'persisted-config' }
        [pscustomobject]@{ Id = '11'; Label = 'デプロイ / migration / IaC / DB権限変更'; Adds = 'deploy-infra' }
    )
}

function Read-ConsoleProfileChoiceSelection {
    param([object[]]$Choices)

    # GUI / TUI ではなく素朴な番号入力にして、PowerShell 7 だけあれば動く形にしている。
    Write-Host '複数ある時は、カンマかスペースで区切って入力できます。'
    Write-Host '迷ったら何も入力せず Enter で基本構成にします。'
    foreach ($choice in $Choices) {
        Write-Host (' {0,2}. {1}' -f $choice.Id, $choice.Label)
    }

    $selection = Read-Host '番号（例: 4 2 5）'
    $choices = @($selection -split '[,\s、，]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($choices.Count -eq 0) {
        return @('1')
    }

    return $choices
}

function Add-ProfilesFromInteractiveChoice {
    param(
        [System.Collections.Generic.List[string]]$Profiles,
        [System.Collections.Generic.List[string]]$UnknownChoices,
        [string]$Choice
    )

    switch ($Choice) {
        '1' { Add-ProfilesFromPreset -List $Profiles -PresetName 'basic' }
        '2' { Add-ProfilesFromPreset -List $Profiles -PresetName 'scheduled-batch' }
        '3' { Add-ProfilesFromPreset -List $Profiles -PresetName 'webhook-service' }
        '4' { Add-ProfilesFromPreset -List $Profiles -PresetName 'godot-csharp' }
        '5' { Add-ProfilesFromPreset -List $Profiles -PresetName 'narrative' }
        '6' { Add-ProfilesFromPreset -List $Profiles -PresetName 'codex-toolkit' }
        '7' { Add-Unique -List $Profiles -Value 'android-mobile' }
        '8' { Add-Unique -List $Profiles -Value 'provider-integration' }
        '9' { Add-Unique -List $Profiles -Value 'notifications' }
        '10' { Add-Unique -List $Profiles -Value 'persisted-config' }
        '11' { Add-Unique -List $Profiles -Value 'deploy-infra' }
        default { Add-Unique -List $UnknownChoices -Value $Choice }
    }
}

function Invoke-InteractiveProfileSelection {
    $profiles = New-Object 'System.Collections.Generic.List[string]'
    $unknownChoices = New-Object 'System.Collections.Generic.List[string]'
    $choices = @(Get-InteractiveProfileChoices)
    Write-Host ''
    Write-Host '作るもの・盛り込む機能に近い番号を選んでください。'
    $selectedChoices = Read-ConsoleProfileChoiceSelection -Choices $choices
    $selectedChoices = @($selectedChoices)

    foreach ($choice in $selectedChoices) {
        Add-ProfilesFromInteractiveChoice -Profiles $profiles -UnknownChoices $unknownChoices -Choice $choice
    }

    if ($profiles.Count -eq 0) {
        Add-ProfilesFromPreset -List $profiles -PresetName 'basic'
    }

    if ($unknownChoices.Count -gt 0) {
        Write-Host "無視した番号: $($unknownChoices -join ', ')"
    }

    Write-Host ''
    Write-Host "選ばれた profile: $($profiles -join ', ')"

    return $profiles
}

function Resolve-SelectedProfiles {
    param(
        [pscustomobject]$Parsed,
        [string]$ToolkitRoot
    )

    $profiles = New-Object 'System.Collections.Generic.List[string]'
    $preset = Get-Option -Parsed $Parsed -Name 'preset' -Default $null
    $isNonInteractive = Test-Option -Parsed $Parsed -Name 'non-interactive'

    # 選択優先度は preset > 明示 --profile > non-interactive basic > interactive。
    # 最後に存在確認し、manifest に存在しない profile を保存しない。
    if (-not [string]::IsNullOrWhiteSpace($preset)) {
        Add-ProfilesFromPreset -List $profiles -PresetName $preset
    } elseif ($Parsed.Profiles.Count -gt 0) {
        Add-Unique -List $profiles -Value 'global'
    } elseif ($isNonInteractive) {
        Add-ProfilesFromPreset -List $profiles -PresetName 'basic'
    } else {
        $profiles = Invoke-InteractiveProfileSelection
    }

    foreach ($profile in $Parsed.Profiles) {
        Add-Unique -List $profiles -Value $profile
    }

    Add-Unique -List $profiles -Value 'global'
    $available = @(Get-AvailableProfiles -ToolkitRoot $ToolkitRoot)
    foreach ($profile in $profiles) {
        if ($available -notcontains $profile) {
            throw "unknown profile: $profile"
        }
    }

    return $profiles
}
