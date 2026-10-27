# Optional: My Machines worker tied to one git checkout (repo= routing).
# Prefer install-my-machines-autostart.ps1 (machine-scoped) for normal enroll.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\install-repo-worker-autostart.ps1 -WorkerDir 'E:\path\to\repo' -WorkerName desktop -PeerWorker laptop
#
# Optional:
#   .\install-repo-worker-autostart.ps1 -WorkerDir '...' -Uninstall

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $WorkerDir,
    [string] $WorkerName = $(if ($env:CURSOR_DEV_WORKER_NAME) { $env:CURSOR_DEV_WORKER_NAME } else { $env:COMPUTERNAME }),
    [string] $PeerWorker = $(if ($env:CURSOR_DEV_PEER_WORKER) { $env:CURSOR_DEV_PEER_WORKER } else { '' }),
    [string] $TaskName = 'Cursor Agent Worker (repo)',
    [switch] $Uninstall,
    [switch] $SkipAuthCheck,
    [switch] $SkipNeverSleep
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_WorkerAutostartCommon.ps1"

$WorkerDir = (Resolve-Path -LiteralPath $WorkerDir).Path
$agentCmd = Get-AgentCmdPath
$startScriptPath = Join-Path $env:LOCALAPPDATA 'cursor-agent\start-repo-worker.ps1'
$autostartLog = Join-Path $env:LOCALAPPDATA 'cursor-agent\worker-autostart-repo.log'

if ($Uninstall) {
    Uninstall-WorkerAutostartTask -Name $TaskName
    exit 0
}

Write-InstallStep 'Checking Git for Windows...'
Ensure-GitBash

Write-InstallStep 'Checking Cursor CLI...'
Ensure-AgentCli -AgentCmd $agentCmd

if (-not $SkipAuthCheck) {
    Write-InstallStep 'Checking Cursor login...'
    Test-AgentAuth -AgentCmd $agentCmd
}

if (-not (Test-Path -LiteralPath $WorkerDir)) {
    throw "WorkerDir does not exist: $WorkerDir"
}

Write-InstallStep "Repo worker root: $WorkerDir"
Write-InstallStep "Writing startup script: $startScriptPath"
Write-WorkerStartScript -Path $startScriptPath -Agent $agentCmd -Root $WorkerDir -Name $WorkerName -Log $autostartLog -ScopeNote 'repo-scoped'

Write-InstallStep "Registering scheduled task: $TaskName (at logon for $env:USERNAME)"
Register-WorkerAutostartTask -Name $TaskName -ScriptPath $startScriptPath -Description "Cursor My Machines worker at logon for repo checkout: $WorkerDir"

Write-InstallStep 'Setting personal fleet user env...'
Set-DevelopEnvUserVars -WorkerName $WorkerName -PeerWorker $PeerWorker

if (-not $SkipNeverSleep) {
    Write-InstallStep 'Configuring always-on power (never idle sleep)...'
    Set-DevelopEnvNeverSleep
} else {
    Write-InstallStep 'Skipped always-on power (-SkipNeverSleep).'
}

Write-InstallStep ''
Write-InstallStep 'Done.'
Write-InstallStep "  Worker name:     $WorkerName"
if ($PeerWorker) {
    Write-InstallStep "  Peer worker:     $PeerWorker"
}
Write-InstallStep "  Worker root:     $WorkerDir"
Write-InstallStep "  Task:            $TaskName"
Write-InstallStep "  Autostart log:   $autostartLog"
Write-InstallStep ''
Write-InstallStep 'Verify:'
Write-InstallStep "  & '$startScriptPath'"
Write-InstallStep '  agent worker debug'
Write-InstallStep '  Expect a repo= label when WorkerDir has a git remote Cursor recognizes.'
