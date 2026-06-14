# codex-kit CLI の表示と引数 parse。

function Write-Step {
    param([string]$Message)

    Write-Host "- $Message"
}

function Write-Usage {
    @'
codex-kit

使い方:
  codex-kit list-profiles
  codex-kit init [--preset <name>] [--profile <name>] [--repo-root <path>] [--non-interactive] [--dry-run] [--force] [--no-sync]
  codex-kit sync [--repo-root <path>] [--dry-run]
  codex-kit status [--repo-root <path>]
  codex-kit doctor [--repo-root <path>]
  codex-kit update [--repo-root <path>] [--dry-run]
  codex-kit self-update [--dry-run]
  codex-kit harden --dry-run [--target <path>]

例:
  .\bin\codex-kit.ps1 init
  .\bin\codex-kit.ps1 init --preset scheduled-batch
  .\bin\codex-kit.ps1 sync --dry-run
'@ | Write-Host
}

function Read-CliArgs {
    param([string[]]$RawArgs)

    $command = 'help'
    $index = 0
    if ($RawArgs.Count -gt 0 -and $RawArgs[0] -notmatch '^-') {
        $command = $RawArgs[0]
        $index = 1
    }

    $options = @{}
    $profiles = New-Object 'System.Collections.Generic.List[string]'
    $positionals = New-Object 'System.Collections.Generic.List[string]'

    while ($index -lt $RawArgs.Count) {
        $arg = $RawArgs[$index]
        switch ($arg) {
            { $_ -in @('--dry-run', '-DryRun') } {
                $options['dry-run'] = $true
                $index += 1
                continue
            }
            { $_ -in @('--non-interactive', '-NonInteractive') } {
                $options['non-interactive'] = $true
                $index += 1
                continue
            }
            { $_ -in @('--force', '-Force') } {
                $options['force'] = $true
                $index += 1
                continue
            }
            { $_ -in @('--no-sync', '-NoSync') } {
                $options['no-sync'] = $true
                $index += 1
                continue
            }
            { $_ -in @('--preset', '-Preset') } {
                if ($index + 1 -ge $RawArgs.Count) {
                    throw '--preset には値が必要。'
                }
                $options['preset'] = $RawArgs[$index + 1]
                $index += 2
                continue
            }
            { $_ -in @('--profile', '-Profile') } {
                if ($index + 1 -ge $RawArgs.Count) {
                    throw '--profile には値が必要。'
                }
                [void]$profiles.Add($RawArgs[$index + 1])
                $index += 2
                continue
            }
            { $_ -in @('--repo-root', '-RepoRoot') } {
                if ($index + 1 -ge $RawArgs.Count) {
                    throw '--repo-root には値が必要。'
                }
                $options['repo-root'] = $RawArgs[$index + 1]
                $index += 2
                continue
            }
            { $_ -in @('--target', '-Target') } {
                if ($index + 1 -ge $RawArgs.Count) {
                    throw '--target には値が必要。'
                }
                $options['target'] = $RawArgs[$index + 1]
                $index += 2
                continue
            }
            default {
                [void]$positionals.Add($arg)
                $index += 1
                continue
            }
        }
    }

    [pscustomobject]@{
        Command = $command
        Options = $options
        Profiles = $profiles
        Positionals = $positionals
    }
}

function Test-Option {
    param(
        [pscustomobject]$Parsed,
        [string]$Name
    )

    return $Parsed.Options.ContainsKey($Name) -and [bool]$Parsed.Options[$Name]
}

function Get-Option {
    param(
        [pscustomobject]$Parsed,
        [string]$Name,
        [object]$Default = $null
    )

    if ($Parsed.Options.ContainsKey($Name)) {
        return $Parsed.Options[$Name]
    }

    return $Default
}
