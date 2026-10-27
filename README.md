# cursor-develop-env

Public **operator kit** that enrolls a Windows machine into your **personal** Cursor develop environment: silent [My Machines](https://cursor.com/docs/cloud-agent/my-machines) worker, stable names, and peer placement policy across your desks.

Formerly `cursor-my-machines`. Same idea; clearer purpose — **install on each desk**, not a product dependency.

## What you get

After enroll, you can start Cloud Agent tasks from the desktop IDE, [cursor.com/agents](https://cursor.com/agents), or [Cursor for iOS](https://cursor.com/docs/cloud-agent/mobile), and run them on any of **your** linked machines (you pick the target, e.g. `desktop` / `laptop`).

This kit is **one operator, many machines**. Shared multi-person machine fleets (Team Pools, cross-account workers) are **postponed** until there is a clearly safe access model.

## Relation to product repos (like Railkit)

Same posture as [railkit](https://github.com/adambergmanconsulting-lgtm/railkit): **apply** this to your desks, **improve** how you work, optionally **graduate** a practice into a host repo as that host's own docs/checks.

| Do | Do not |
|----|--------|
| Install and run this on each develop PC | Add this repo as a submodule, package, or required clone of TeamResume (or any product) |
| Keep worker installers and peer topology here | Make product CI, skills, or `npm` scripts fail if this repo is missing |
| When a habit proves useful, copy a **thin native** rule into the product | Import or `require()` this repo from product code |

**Hosts must stay fully usable without `cursor-develop-env`.**

## Enroll a machine (canonical)

Prerequisites on each PC: [Git for Windows](https://git-scm.com/download/win) (Git Bash), Cursor CLI (`irm 'https://cursor.com/install?win32=true' | iex`), then `agent login` (same Cursor account as the desktop app).

```powershell
git clone https://github.com/adambergmanconsulting-lgtm/cursor-develop-env.git
cd cursor-develop-env\windows
Set-ExecutionPolicy -Scope Process Bypass
.\install-my-machines-autostart.ps1 -WorkerName desktop -PeerWorker laptop
.\doctor-develop-env.ps1
```

On the other desk, swap the names (`-WorkerName laptop -PeerWorker desktop`). Upgrade later with `git pull` and re-run the installer (idempotent).

Installer effects:

- Silent logon worker (no visible PowerShell console)
- Neutral machine workspace under `%LOCALAPPDATA%\cursor-agent\machine-workspace` (not a git repo)
- User env: `CURSOR_DEV_WORKER_NAME`, `CURSOR_DEV_PEER_WORKER`
- Scheduled task `Cursor Agent Worker`
- **Always-on power:** never idle sleep / hibernate / display / disk off (user scheme). The worker host also holds `SetThreadExecutionState` while it runs. Cloud Agents only reach desks that are awake with an online worker — sleep-until-job is not reliable, so enroll keeps the PC up.

Escape hatch if this desk should still sleep: add `-SkipNeverSleep` (worker stay-awake still applies only while the host process is running).

Optional once as Administrator (hibernate fully off, no Windows Update auto-reboot while logged on):

```powershell
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PWD\power\apply-never-sleep-admin-once.ps1`""
```

Then open [cursor.com/agents](https://cursor.com/agents) and choose this machine under **My Machines**.

### Optional bootstrap one-liner

Pins a release tag, clones into `%LOCALAPPDATA%\cursor-develop-env\kit`, then enrolls:

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/adambergmanconsulting-lgtm/cursor-develop-env/v0.1.0/windows/bootstrap.ps1'))) -WorkerName desktop -PeerWorker laptop
```

Or download/run `bootstrap.ps1` with `-Ref v0.1.0` (prefer tags over floating `main`).

## Pair topology

| Variable | Desktop | Laptop |
|----------|---------|--------|
| `CURSOR_DEV_WORKER_NAME` | `desktop` | `laptop` |
| `CURSOR_DEV_PEER_WORKER` | `laptop` | `desktop` |

Optional: `CURSOR_DEV_I_AM_CODING=1` when this host is the coding host without a long-lived `dev` server.

**Ship / build-class default:** if the peer is set and this host is coding-busy, prefer `CURSOR_DEV_PEER_WORKER`. Escape: `CURSOR_DEV_SHIP_HERE=1` or “on this machine” in the prompt.

## Local runners

Policy only (product repos own runner implementation):

- Prefer self-hosted local runners on the **ship peer** when the product supports local-first CI
- Do not stack release-class runner work on the coding host when the peer is available

## Repo-scoped worker (escape hatch)

Default enroll is **machine-scoped**. Use a repo checkout only when you need `repo=` routing:

```powershell
.\install-repo-worker-autostart.ps1 -WorkerDir 'E:\path\to\your\repo' -WorkerName desktop -PeerWorker laptop
```

## Uninstall

```powershell
.\install-my-machines-autostart.ps1 -Uninstall
```

## Logs and paths

| Item | Path |
| --- | --- |
| Machine autostart log | `%LOCALAPPDATA%\cursor-agent\worker-autostart.log` |
| Generated start script | `%LOCALAPPDATA%\cursor-agent\start-my-machines-worker.ps1` |
| Machine workspace | `%LOCALAPPDATA%\cursor-agent\machine-workspace` |
| Bootstrap kit clone | `%LOCALAPPDATA%\cursor-develop-env\kit` |

## Do not commit

API keys, `agent login` state, or anything under `%LOCALAPPDATA%\cursor-agent\` / generated kit state.

## Maintainers

See [AGENTS.md](AGENTS.md).
