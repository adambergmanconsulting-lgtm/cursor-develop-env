# Enrolls this Windows machine into a personal Cursor develop environment
# (machine-scoped My Machines worker at logon).
#
# Prerequisites:
#   Git for Windows (Git Bash): https://git-scm.com/download/win
#   Cursor CLI (installed by this script if missing)
#   One-time: agent login
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\install-my-machines-autostart.ps1 -WorkerName desktop -PeerWorker laptop
#
# Optional:
#   .\install-my-machines-autostart.ps1 -Uninstall

[CmdletBinding()]
param(
    [string] $WorkerName = $(if ($env:CURSOR_DEV_WORKER_NAME) { $env:CURSOR_DEV_WORKER_NAME } else { $env:COMPUTERNAME }),
    [string] $PeerWorker = $(if ($env:CURSOR_DEV_PEER_WORKER) { $env:CURSOR_DEV_PEER_WORKER } else { '' }),
    [string] $WorkerRoot = (Join-Path $env:LOCALAPPDATA 'cursor-agent\machine-workspace'),
    [string] $TaskName = 'Cursor Agent Worker',
    [switch] $Uninstall,
    [switch] $SkipAuthCheck
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_WorkerAutostartCommon.ps1"

$agentCmd = Get-AgentCmdPath
$startScriptPath = Get-DefaultStartScriptPath
$autostartLog = Get-DefaultAutostartLogPath

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

Write-InstallStep "Ensuring machine workspace (not a git repo): $WorkerRoot"
New-Item -ItemType Directory -Path $WorkerRoot -Force | Out-Null
if (Test-Path -LiteralPath (Join-Path $WorkerRoot '.git')) {
    throw "Worker root must not be a git repo for machine-only scope. Remove .git or pick another -WorkerRoot."
}

Write-InstallStep "Writing startup script: $startScriptPath"
Write-WorkerStartScript -Path $startScriptPath -Agent $agentCmd -Root $WorkerRoot -Name $WorkerName -Log $autostartLog -ScopeNote 'machine-scoped'

Write-InstallStep "Registering scheduled task: $TaskName (at logon for $env:USERNAME)"
Register-WorkerAutostartTask -Name $TaskName -ScriptPath $startScriptPath -Description 'Cursor My Machines worker at logon (machine-scoped, neutral workspace).'

Write-InstallStep 'Setting personal fleet user env...'
Set-DevelopEnvUserVars -WorkerName $WorkerName -PeerWorker $PeerWorker

Write-InstallStep ''
Write-InstallStep 'Done. Machine enrolled (personal My Machines fleet).'
Write-InstallStep "  Worker name:     $WorkerName"
if ($PeerWorker) {
    Write-InstallStep "  Peer worker:     $PeerWorker"
}
Write-InstallStep "  Worker root:     $WorkerRoot"
Write-InstallStep "  Task:            $TaskName"
Write-InstallStep "  Autostart log:   $autostartLog"
Write-InstallStep ''
Write-InstallStep 'Verify:'
Write-InstallStep "  .\doctor-develop-env.ps1"
Write-InstallStep "  & '$startScriptPath'"
Write-InstallStep '  agent worker debug'
