# Verifies personal develop-env enrollment on this Windows machine.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\doctor-develop-env.ps1

[CmdletBinding()]
param(
    [string] $TaskName = 'Cursor Agent Worker',
    [string] $WorkerRoot = (Join-Path $env:LOCALAPPDATA 'cursor-agent\machine-workspace'),
    [string] $StartScriptPath = (Join-Path $env:LOCALAPPDATA 'cursor-agent\start-my-machines-worker.ps1')
)

$ErrorActionPreference = 'Continue'
$failed = 0

function Write-Check {
    param([bool] $Ok, [string] $Message)
    if ($Ok) {
        Write-Host "OK   $Message"
    } else {
        Write-Host "FAIL $Message"
        $script:failed++
    }
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Write-Check -Ok ($null -ne $task) -Message "Scheduled task '$TaskName' registered"

$action = $task.Actions | Select-Object -First 1
$vbsLauncher = [System.IO.Path]::ChangeExtension($StartScriptPath, '.vbs')
$silentLaunch = $action -and ($action.Execute -match 'wscript\.exe$') -and (Test-Path -LiteralPath $vbsLauncher)
Write-Check -Ok ([bool]$silentLaunch) -Message 'Task launches via wscript silent VBS (no console)'

Write-Check -Ok (Test-Path -LiteralPath $StartScriptPath) -Message "Start script exists: $StartScriptPath"

if (Test-Path -LiteralPath $StartScriptPath) {
    $startText = Get-Content -LiteralPath $StartScriptPath -Raw
    Write-Check -Ok ($startText -match 'cursor-agent\.ps1' -and $startText -notmatch 'agent\.cmd') `
        -Message 'Start script invokes cursor-agent.ps1 in-process (not agent.cmd)'
    Write-Check -Ok ($startText -match 'Hide-AutostartConsole|ShowWindow') `
        -Message 'Start script force-hides console (ShowWindow)'
    Write-Check -Ok ($startText -match 'Enable-WorkerStayAwake|SetThreadExecutionState') `
        -Message 'Start script enables stay-awake while worker runs'
}

. "$PSScriptRoot\_WorkerAutostartCommon.ps1"
Write-Check -Ok (Test-DevelopEnvNeverSleep) -Message 'Always-on power: AC standby timeout is never (0)'

$legacyKeepAwake = Get-ScheduledTask -TaskName 'CursorSelfHosted-KeepAwake' -ErrorAction SilentlyContinue
Write-Check -Ok ($null -eq $legacyKeepAwake) -Message 'No legacy CursorSelfHosted-KeepAwake task'

Write-Check -Ok (Test-Path -LiteralPath $WorkerRoot) -Message "Machine workspace exists: $WorkerRoot"
Write-Check -Ok (-not (Test-Path -LiteralPath (Join-Path $WorkerRoot '.git'))) `
    -Message 'Machine workspace is not a git repo'

$userName = [Environment]::GetEnvironmentVariable('CURSOR_DEV_WORKER_NAME', 'User')
$userPeer = [Environment]::GetEnvironmentVariable('CURSOR_DEV_PEER_WORKER', 'User')
Write-Check -Ok ([bool]$userName) -Message "User env CURSOR_DEV_WORKER_NAME=$userName"
if ($userPeer) {
    Write-Host "OK   User env CURSOR_DEV_PEER_WORKER=$userPeer"
} else {
    Write-Host "WARN User env CURSOR_DEV_PEER_WORKER unset (ok for single-machine)"
}

$workers = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*cursor-agent*' -and $_.CommandLine -like '*worker*' })
Write-Check -Ok ($workers.Count -ge 1) -Message $(if ($workers.Count -ge 1) {
        "Worker process running (pid $($workers.ProcessId -join ','))"
    } else {
        'Worker process running'
    })
Write-Check -Ok ($workers.Count -le 1) -Message $(if ($workers.Count -le 1) {
        'Exactly one worker process on this machine'
    } else {
        "Exactly one worker process (found $($workers.Count): pid $($workers.ProcessId -join ','))"
    })

$machineOk = $workers.Count -eq 1 -and
    ($workers[0].CommandLine -like "*$WorkerRoot*") -and
    ($workers[0].CommandLine -notlike '*TeamResume*')
Write-Check -Ok $machineOk -Message "Worker is machine-scoped at $WorkerRoot"

$agentCmdHost = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and
        $_.CommandLine -like '*cursor-agent.ps1*' -and
        $_.CommandLine -like '*worker*' -and
        $_.CommandLine -notlike '*start-my-machines-worker.ps1*' -and
        $_.CommandLine -notlike '*start-repo-worker.ps1*'
    }
Write-Check -Ok (-not $agentCmdHost) -Message 'No agent.cmd-style powershell hosting cursor-agent.ps1 worker'

$repoTask = Get-ScheduledTask -TaskName 'Cursor Agent Worker (repo)' -ErrorAction SilentlyContinue
Write-Check -Ok ($null -eq $repoTask) -Message 'No repo-scoped autostart task registered'

Write-Host ''
if ($failed -gt 0) {
    Write-Host "Doctor finished with $failed failure(s)."
    exit 1
}
Write-Host 'Doctor passed.'
exit 0
