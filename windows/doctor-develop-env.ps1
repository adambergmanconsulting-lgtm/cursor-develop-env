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
$hidden = $action -and ($action.Arguments -match '-WindowStyle Hidden')
Write-Check -Ok ([bool]$hidden) -Message 'Task action uses -WindowStyle Hidden'

Write-Check -Ok (Test-Path -LiteralPath $StartScriptPath) -Message "Start script exists: $StartScriptPath"

if (Test-Path -LiteralPath $StartScriptPath) {
    $startText = Get-Content -LiteralPath $StartScriptPath -Raw
    Write-Check -Ok ($startText -match 'cursor-agent\.ps1' -and $startText -notmatch 'agent\.cmd') `
        -Message 'Start script invokes cursor-agent.ps1 in-process (not agent.cmd)'
}

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

$workers = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*cursor-agent*' -and $_.CommandLine -like '*worker*' }
Write-Check -Ok ([bool]$workers) -Message $(if ($workers) {
        "Worker process running (pid $($workers.ProcessId -join ','))"
    } else {
        'Worker process running'
    })

$visiblePs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq 'powershell.exe' -and
        $_.CommandLine -like '*cursor-agent.ps1*' -and
        $_.CommandLine -like '*worker*'
    }
Write-Check -Ok (-not $visiblePs) -Message 'No intermediate powershell.exe hosting cursor-agent.ps1 worker'

Write-Host ''
if ($failed -gt 0) {
    Write-Host "Doctor finished with $failed failure(s)."
    exit 1
}
Write-Host 'Doctor passed.'
exit 0
