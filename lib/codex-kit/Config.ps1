# codex-kit CLI の共有設定。
# 文字列識別子は manifest や docs と揃える必要があるため、表示ラベルとは分けて管理する。

# Codex の標準 hook event。hooks.json 生成時に全 event へ同じ dispatcher を張る。
$script:HookEvents = @(
    'PreToolUse',
    'PermissionRequest',
    'PostToolUse',
    'PreCompact',
    'PostCompact',
    'SessionStart',
    'SubagentStart',
    'SubagentStop',
    'UserPromptSubmit',
    'Stop'
)

# preset は init の短縮指定。必ず global を含め、用途別 profile は必要最小限にする。
$script:PresetProfiles = [ordered]@{
    'basic' = @('global')
    'android-mobile' = @('global', 'android-mobile')
    'scheduled-batch' = @('global', 'scheduled-batch')
    'webhook-service' = @('global', 'webhook-worker')
    'godot-csharp' = @('global', 'godot-csharp')
    'narrative' = @('global', 'narrative')
    'codex-toolkit' = @('global', 'android-mobile', 'scheduled-batch', 'notifications', 'deploy-infra', 'provider-integration', 'persisted-config', 'webhook-worker', 'godot-csharp', 'narrative', 'toolkit-maintenance')
}
