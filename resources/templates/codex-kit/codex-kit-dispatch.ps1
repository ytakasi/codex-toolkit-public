param(
    [string]$EventName = ''
)

$ErrorActionPreference = 'Stop'
$script:CodexHookRawInput = @($input) -join "`n"

function Read-HookPayload {
    $raw = $script:CodexHookRawInput
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $raw = [Console]::In.ReadToEnd()
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{
            Raw = ''
            Json = $null
        }
    }

    try {
        $json = $raw | ConvertFrom-Json
    } catch {
        $json = $null
    }

    [pscustomobject]@{
        Raw = $raw
        Json = $json
    }
}

function Get-RepoRoot {
    param([object]$Payload)

    $cwd = if ($null -ne $Payload -and $null -ne $Payload.cwd) { [string]$Payload.cwd } else { (Get-Location).Path }
    if (-not [string]::IsNullOrWhiteSpace($cwd) -and (Test-Path -LiteralPath $cwd)) {
        Set-Location -LiteralPath $cwd
    }

    $root = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($root -join ''))) {
        return [System.IO.Path]::GetFullPath(@($root)[0])
    }

    return [System.IO.Path]::GetFullPath((Get-Location).Path)
}

function Get-EventName {
    param(
        [string]$ExplicitEventName,
        [object]$Payload
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitEventName)) {
        return $ExplicitEventName
    }

    if ($null -ne $Payload -and $Payload.PSObject.Properties.Name -contains 'hook_event_name') {
        return [string]$Payload.hook_event_name
    }

    if ($null -ne $Payload -and $Payload.PSObject.Properties.Name -contains 'event') {
        return [string]$Payload.event
    }

    return ''
}

function ConvertTo-RelativePath {
    param(
        [string]$BasePath,
        [string]$Path
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath)
    if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $baseFull = $baseFull + [System.IO.Path]::DirectorySeparatorChar
    }

    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $baseUri = [Uri]$baseFull
    $pathUri = [Uri]$pathFull
    return ([Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Get-HookFiles {
    param(
        [string]$RepoRoot,
        [string]$EventName
    )

    $layers = @(
        (Join-Path $RepoRoot "agent-skills/toolkit/hooks.d/$EventName"),
        (Join-Path $RepoRoot "agent-skills/repo/hooks.d/$EventName")
    )
    $selected = @{}

    foreach ($layer in $layers) {
        if (-not (Test-Path -LiteralPath $layer)) {
            continue
        }

        Get-ChildItem -LiteralPath $layer -File -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
            $key = (ConvertTo-RelativePath -BasePath $layer -Path $_.FullName).ToLowerInvariant()
            $selected[$key] = $_.FullName
        }
    }

    return $selected.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value }
}

function Invoke-HookFile {
    param(
        [string]$HookPath,
        [string]$RawInput
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$HookPath`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.StandardInput.Write($RawInput)
    $process.StandardInput.Close()

    if (-not $process.WaitForExit(30000)) {
        try {
            $process.Kill()
        } catch {
        }
        [Console]::Error.WriteLine("hook が timeout した: $HookPath")
        exit 2
    }

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $process.StandardOutput.ReadToEnd()
        Stderr = $process.StandardError.ReadToEnd()
        Path = $HookPath
    }
}

$payload = Read-HookPayload
$event = Get-EventName -ExplicitEventName $EventName -Payload $payload.Json
if ([string]::IsNullOrWhiteSpace($event)) {
    exit 0
}

$repoRoot = Get-RepoRoot -Payload $payload.Json
$hookFiles = @(Get-HookFiles -RepoRoot $repoRoot -EventName $event)
if ($hookFiles.Count -eq 0) {
    exit 0
}

$messages = New-Object 'System.Collections.Generic.List[string]'
foreach ($hookFile in $hookFiles) {
    $result = Invoke-HookFile -HookPath $hookFile -RawInput $payload.Raw
    if ($result.ExitCode -ne 0) {
        if (-not [string]::IsNullOrWhiteSpace($result.Stdout)) {
            [Console]::Out.Write($result.Stdout)
        }
        if (-not [string]::IsNullOrWhiteSpace($result.Stderr)) {
            [Console]::Error.Write($result.Stderr)
        }
        exit $result.ExitCode
    }

    if ([string]::IsNullOrWhiteSpace($result.Stdout)) {
        continue
    }

    try {
        $json = $result.Stdout | ConvertFrom-Json
        if ($null -ne $json -and $json.PSObject.Properties.Name -contains 'systemMessage') {
            [void]$messages.Add([string]$json.systemMessage)
        } else {
            [void]$messages.Add($result.Stdout.Trim())
        }
    } catch {
        [void]$messages.Add($result.Stdout.Trim())
    }
}

if ($messages.Count -gt 0) {
    $output = [ordered]@{
        systemMessage = ($messages -join "`n")
    }
    [Console]::Out.WriteLine(($output | ConvertTo-Json -Compress))
}

exit 0
