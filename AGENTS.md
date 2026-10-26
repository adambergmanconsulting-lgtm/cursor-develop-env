# Agent handover: cursor-my-machines

## Purpose

Version-controlled **personal** Windows automation for Cursor **My Machines** workers. This is not application code. Do not merge into product repos unless the team explicitly adopts identical worker policy.

## Layout

```text
cursor-my-machines/
  README.md
  AGENTS.md
  .gitignore
  windows/
    _WorkerAutostartCommon.ps1      # shared helpers (dot-sourced)
    install-my-machines-autostart.ps1   # default: machine-scoped
    install-repo-worker-autostart.ps1   # optional: one git checkout
```

Installers **write** generated start scripts and register a **per-user** scheduled task at logon. They do not run the worker during install (except the user may run the generated script manually).

## Design rules

1. **Machine-scoped default:** `WorkerRoot` is `%LOCALAPPDATA%\cursor-agent\machine-workspace`, must **not** contain `.git`. Avoids `repo=` routing labels.
2. **Repo-scoped optional:** `-WorkerDir` must be an existing checkout; git remote drives Cursor routing labels.
3. **Idempotent start:** generated start script skips if a `node.exe` process with `cursor-agent` and `worker` in its command line is already running.
4. **Auth:** rely on persisted `agent login` on that Windows user. Task uses `LogonType Interactive` for the installing user. Do not store tokens in this repo.
5. **Scheduled task:** name `Cursor Agent Worker` (machine) or `Cursor Agent Worker (repo)` (repo). Unlimited runtime (`ExecutionTimeLimit` zero), restart on failure, `MultipleInstances IgnoreNew`.
6. **Secrets:** never commit API keys, auth tokens, or machine-specific paths unless parameterized with defaults.

## Adding a new script

- Put shared logic in `_WorkerAutostartCommon.ps1`.
- Keep each installer thin: validate env, call `Write-WorkerStartScript`, call `Register-WorkerAutostartTask`.
- Document new behavior in `README.md` (user-facing) and this file (agent-facing).
- Test on Windows with `Set-ExecutionPolicy -Scope Process Bypass` only; do not weaken system execution policy permanently.

## Common extensions (not implemented unless asked)

| Request | Approach |
| --- | --- |
| Linux / macOS autostart | New folder `linux/` or `macos/` with systemd/launchd; do not overload Windows scripts. |
| Team pool (`--pool`) | Separate script; requires Enterprise + service account key; different auth model than My Machines. |
| `--connect-workspace` | Add switch to generated start line; Linux only per Cursor docs. |
| Multiple repo roots on one worker | Extend generated script to pass repeated `--worker-dir` flags; document routing in README. |
| Install from repo path without copy | Optional `-StartScriptPath` under clone; task must reference a stable path after clone moves. |

## Verify after changes

On a Windows machine with Git and Cursor CLI:

```powershell
cd windows
.\install-my-machines-autostart.ps1 -SkipAuthCheck   # only if login already verified separately
Get-ScheduledTask -TaskName 'Cursor Agent Worker'
& "$env:LOCALAPPDATA\cursor-agent\start-my-machines-worker.ps1"   # expect skip or start
agent worker debug
```

## Publish

Private GitHub repo under the owner's account. Initial create (human or agent with `gh`):

```powershell
cd cursor-my-machines
git init -b main
git add .
git commit -m "chore: initial My Machines Windows autostart scripts"
gh repo create cursor-my-machines --private --source=. --remote=origin --push
```

Update clone URL in README if org or repo name differs.

## Out of scope

- Cursor Cloud Agent `environment.json` / VM builds (see Cursor env-setup docs).
- Product-specific hooks in `.cursor/hooks.json` inside app repos (stay in those repos).
- Committing `%LOCALAPPDATA%\cursor-agent\` state.
