# Bootstrap: clone/update this kit locally, then enroll a machine-scoped worker.
#
# Prefer a pinned release tag in docs (not floating main):
#   irm https://raw.githubusercontent.com/adambergmanconsulting-lgtm/cursor-develop-env/v0.1.0/windows/bootstrap.ps1 | iex
#
# Or run from a checkout:
#   .\bootstrap.ps1 -WorkerName desktop -PeerWorker laptop
#
# Auth is never passed here — run agent login on the machine if needed.

[CmdletBinding()]
param(
    [string] $WorkerName = 'desktop',
    [string] $PeerWorker = 'laptop',
    [string] $Ref = 'v0.1.0',
    [string] $RepoUrl = 'https://github.com/adambergmanconsulting-lgtm/cursor-develop-env.git',
    [string] $KitRoot = (Join-Path $env:LOCALAPPDATA 'cursor-develop-env\kit'),
    [switch] $SkipAuthCheck,
    [switch] $SkipEnroll
)

$ErrorActionPreference = 'Stop'

function Write-BootstrapStep {
    param([string] $Message)
    Write-Host $Message
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    throw 'Git for Windows is required. Install from https://git-scm.com/download/win'
}

$kitParent = Split-Path -Parent $KitRoot
New-Item -ItemType Directory -Path $kitParent -Force | Out-Null

if (Test-Path -LiteralPath (Join-Path $KitRoot '.git')) {
    Write-BootstrapStep "Updating kit at $KitRoot (ref $Ref)..."
    Push-Location -LiteralPath $KitRoot
    try {
        git fetch --tags origin
        git checkout --force $Ref
        # If Ref is a branch tip, fast-forward; tags stay detached (ignore pull failure).
        git merge --ff-only "origin/$Ref" 2>$null | Out-Null
    } finally {
        Pop-Location
    }
} else {
    if (Test-Path -LiteralPath $KitRoot) {
        throw "Kit path exists but is not a git clone: $KitRoot"
    }
    Write-BootstrapStep "Cloning $RepoUrl ($Ref) -> $KitRoot"
    git clone --branch $Ref --single-branch $RepoUrl $KitRoot
}

$enroll = Join-Path $KitRoot 'windows\install-my-machines-autostart.ps1'
if (-not (Test-Path -LiteralPath $enroll)) {
    throw "Enroll script missing after clone: $enroll"
}

if ($SkipEnroll) {
    Write-BootstrapStep "Kit ready at $KitRoot (skipped enroll)."
    exit 0
}

Write-BootstrapStep "Enrolling machine: WorkerName=$WorkerName PeerWorker=$PeerWorker"
$enrollArgs = @{
    WorkerName = $WorkerName
    PeerWorker = $PeerWorker
}
if ($SkipAuthCheck) {
    $enrollArgs.SkipAuthCheck = $true
}

& $enroll @enrollArgs
exit $LASTEXITCODE
