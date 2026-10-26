# cursor-my-machines

Personal Windows setup for [Cursor My Machines](https://cursor.com/docs/cloud-agent/my-machines) (self-hosted Cloud Agent workers). Not tied to any product repo.

## What this repo is for

- Start `agent worker start` automatically when you sign in to Windows.
- **Machine-scoped** worker: neutral folder, no `repo=` routing label (default installer).
- **Repo-scoped** worker: optional second installer when you need `worker=` / GitHub routing for one checkout.

Generated files (scheduled task target, logs) live under `%LOCALAPPDATA%\cursor-agent\`. Scripts in this repo are the source of truth; re-run an installer after pulling updates.

## Prerequisites (each PC)

1. [Git for Windows](https://git-scm.com/download/win) (includes Git Bash).
2. Cursor CLI: `irm 'https://cursor.com/install?win32=true' | iex`
3. One-time sign-in: `agent login` (same Cursor account as the desktop app).

Docs: [Bring your own machine](https://cursor.com/docs/cloud-agent/bring-your-own-machine), [My Machines](https://cursor.com/docs/cloud-agent/my-machines).

## Quick start (new machine)

```powershell
git clone https://github.com/adambergmanconsulting-lgtm/cursor-my-machines.git
cd cursor-my-machines\windows
Set-ExecutionPolicy -Scope Process Bypass
.\install-my-machines-autostart.ps1
# optional friendly name:
# .\install-my-machines-autostart.ps1 -WorkerName "AdamsLaptop"
```

Sign out and back in (or run the generated start script once). Then:

```powershell
agent worker debug
```

In [cursor.com/agents](https://cursor.com/agents), choose this machine under **My Machines**.

## Repo-scoped worker (optional)

For one git checkout (e.g. TeamResume) with `repo=` labels and trigger routing:

```powershell
.\install-repo-worker-autostart.ps1 -WorkerDir 'E:\path\to\your\repo'
```

Uses scheduled task name `Cursor Agent Worker (repo)` so it can coexist with the machine-scoped task only if you run both intentionally (two workers). Usually pick one pattern per machine.

## Uninstall

```powershell
.\install-my-machines-autostart.ps1 -Uninstall
# or
.\install-repo-worker-autostart.ps1 -WorkerDir '...' -Uninstall
```

## Logs and paths

| Item | Path |
| --- | --- |
| Machine autostart log | `%LOCALAPPDATA%\cursor-agent\worker-autostart.log` |
| Repo autostart log | `%LOCALAPPDATA%\cursor-agent\worker-autostart-repo.log` |
| Generated start script (machine) | `%LOCALAPPDATA%\cursor-agent\start-my-machines-worker.ps1` |
| Generated start script (repo) | `%LOCALAPPDATA%\cursor-agent\start-repo-worker.ps1` |
| Machine workspace (default) | `%LOCALAPPDATA%\cursor-agent\machine-workspace` |
| Worker startup (CLI) | `%LOCALAPPDATA%\cursor-agent\worker-startup.log` |

## Do not commit

- API keys, `agent login` state, or anything under `%LOCALAPPDATA%\cursor-agent\` except what these scripts generate locally.

## Maintainers

See [AGENTS.md](AGENTS.md) for how to extend this repo (another Cursor agent or future you).
