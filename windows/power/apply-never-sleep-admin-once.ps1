# Optional: run once in an elevated PowerShell (right-click -> Run as administrator).
# Reinforces never-sleep at machine scope, disables hibernate, and blocks Windows
# Update auto-reboot while a user is logged on.
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$schemeLine = powercfg /getactivescheme
if ($schemeLine -notmatch '([0-9a-f-]{36})') {
    throw "Could not read active power scheme: $schemeLine"
}
$scheme = $Matches[1]

function Set-PowerBoth($sub, $set, $val) {
    powercfg /setacvalueindex $scheme $sub $set $val | Out-Null
    powercfg /setdcvalueindex $scheme $sub $set $val | Out-Null
}

powercfg /hibernate off
Set-PowerBoth SUB_SLEEP HYBRIDSLEEP 0
Set-PowerBoth SUB_SLEEP RTCWAKE 0
Set-PowerBoth SUB_SLEEP STANDBYIDLE 0
Set-PowerBoth SUB_SLEEP HIBERNATEIDLE 0
Set-PowerBoth SUB_VIDEO VIDEOIDLE 0
Set-PowerBoth SUB_DISK DISKIDLE 0
powercfg /setactive $scheme | Out-Null

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoRebootWithLoggedOnUsers' -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "Admin power settings applied on scheme ${scheme}: hibernate off, idle sleep/display/disk never, no auto-reboot while logged on."
