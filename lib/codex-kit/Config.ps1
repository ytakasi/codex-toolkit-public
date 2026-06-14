# codex-kit CLI の共有設定。

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

$script:PresetProfiles = [ordered]@{
    'basic' = @('global')
    'android-mobile' = @('global', 'android-mobile')
    'scheduled-batch' = @('global', 'scheduled-batch')
    'webhook-service' = @('global', 'webhook-worker')
    'godot-csharp' = @('global', 'godot-csharp')
    'narrative' = @('global', 'narrative')
    'codex-toolkit' = @('global', 'android-mobile', 'scheduled-batch', 'notifications', 'deploy-infra', 'provider-integration', 'persisted-config', 'webhook-worker', 'godot-csharp', 'narrative', 'toolkit-maintenance')
}
