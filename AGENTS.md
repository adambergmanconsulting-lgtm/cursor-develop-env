# Agent handover: cursor-develop-env

## Purpose

Version-controlled **personal develop environment** for Cursor across one or more Windows desks: My Machines workers, peer topology, and policy for where agents vs local CI runners should run.

**Railkit-like apply/improve:** operators apply this to machines and improve process here. Product hosts (TeamResume, etc.) must **not** depend on this repo (no submodule, no required clone, no failing skill if absent). Optionally graduate a proven habit into the host as **native** docs/skills the host owns. Same separation as [railkit](https://github.com/adambergmanconsulting-lgtm/railkit) kit vs host: change the way of working; leave the product self-sufficient.

This is **not** application code. Do not merge wholesale into product repos.

Rename history: was `cursor-my-machines` (worker autostart only).

## Layout

```text
cursor-develop-env/
  README.md                 # user-facing: pair topology, policy, install
  AGENTS.md                 # this file
  .gitignore
  windows/
    _WorkerAutostartCommon.ps1
    install-my-machines-autostart.ps1   # default: machine-scoped worker
    install-repo-worker-autostart.ps1   # optional: one git checkout
```

Installers **write** generated start scripts and register a **per-user** scheduled task at logon. They do not run the worker during install (except the user may run the generated script manually).

## Develop-env policy (canonical here)

1. **Coding host** vs **ship peer:** see README pair topology (`CURSOR_DEV_WORKER_NAME`, `CURSOR_DEV_PEER_WORKER`, optional `CURSOR_DEV_I_AM_CODING`).
2. **Build-class work** (release cut, long verify packs, starting self-hosted runners for a ship) prefers the **peer** when this host is coding-busy. Escape: `CURSOR_DEV_SHIP_HERE=1` or explicit “on this machine.”
3. **Local runners:** prefer on the ship peer when the product supports local-first CI. Product repos own runner implementation; this repo owns the placement rule.
4. **Day-to-day prompts** should not restate worker names once env + autostart are installed.

If a product later adds peer handoff, keep it optional (honor env when set; no-op / single-machine path when unset). Never gate product ship on this repo existing.

## Design rules (workers)

1. **Machine-scoped default:** `WorkerRoot` is `%LOCALAPPDATA%\cursor-agent\machine-workspace`, must **not** contain `.git`. Avoids `repo=` routing labels.
2. **Repo-scoped optional:** `-WorkerDir` must be an existing checkout; git remote drives Cursor routing labels.
3. **Idempotent start:** generated start script skips if a `node.exe` process with `cursor-agent` and `worker` in its command line is already running.
4. **Auth:** rely on persisted `agent login` on that Windows user. Task uses `LogonType Interactive` for the installing user. Do not store tokens in this repo.
5. **Scheduled task:** name `Cursor Agent Worker` (machine) or `Cursor Agent Worker (repo)` (repo). Unlimited runtime (`ExecutionTimeLimit` zero), restart on failure, `MultipleInstances IgnoreNew`.
6. **Secrets:** never commit API keys, auth tokens, or machine-specific paths unless parameterized with defaults.
7. **Worker names:** prefer stable pair names (`desktop` / `laptop`) matching `CURSOR_DEV_*` env.

## Adding a new script

- Put shared logic in `_WorkerAutostartCommon.ps1`.
- Keep each installer thin: validate env, call `Write-WorkerStartScript`, call `Register-WorkerAutostartTask`.
- Document new behavior in `README.md` (user-facing) and this file (agent-facing).
- Test on Windows with `Set-ExecutionPolicy -Scope Process Bypass` only; do not weaken system execution policy permanently.

## Common extensions (not implemented unless asked)

| Request | Approach |
| --- | --- |
| Installer writes `CURSOR_DEV_*` user env | Add optional `-PeerWorker` to installers; set via `[Environment]::SetEnvironmentVariable` for the user |
| `ops:ship-peer` status / Cloud Agents API spawn | Small script **here** (generic). Products do not call into this git URL; operators run it, or a graduated copy lives in the host |
| Linux / macOS autostart | New folder `linux/` or `macos/` with systemd/launchd; do not overload Windows scripts |
| Team pool (`--pool`) | Separate script; requires Enterprise + service account key; different auth model than My Machines |
| `--connect-workspace` | Add switch to generated start line; Linux only per Cursor docs |
| Multiple repo roots on one worker | Extend generated script to pass repeated `--worker-dir` flags; document routing in README |
| Product runner bootstrap | Do **not** vendor TeamResume (or other) runner compose here; link policy only |

## Verify after changes

On a Windows machine with Git and Cursor CLI:

```powershell
cd windows
.\install-my-machines-autostart.ps1 -SkipAuthCheck   # only if login already verified separately
Get-ScheduledTask -TaskName 'Cursor Agent Worker'
& "$env:LOCALAPPDATA\cursor-agent\start-my-machines-worker.ps1"   # expect skip or start
agent worker debug
```

Confirm user env: `CURSOR_DEV_WORKER_NAME`, `CURSOR_DEV_PEER_WORKER`.

## Out of scope

- Cursor Cloud Agent `environment.json` / VM builds (see Cursor env-setup docs).
- Product-specific hooks in `.cursor/hooks.json` or skills inside app repos (host-owned; optional graduation only).
- Committing `%LOCALAPPDATA%\cursor-agent\` state.
- Azure / GitHub product release scripts.
- Any hard dependency from a product repo onto this one.
