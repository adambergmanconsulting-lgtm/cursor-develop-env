# Re-apply user-level always-on power settings (same as enroll).
# Enroll already runs this; use again after Windows resets a power plan.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\apply-never-sleep-user.ps1

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\_WorkerAutostartCommon.ps1"
Set-DevelopEnvNeverSleep
