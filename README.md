# cursor-develop-env

Personal **develop environment** config for Cursor: how agents, My Machines workers, and local CI runners should behave across your desks (for example a desktop + laptop pair).

Not tied to any product repo. Product repos (TeamResume, others) stay thin: they consume the env vars and conventions defined here; they do not own worker installers or peer topology.

Formerly `cursor-my-machines` (Windows worker autostart only). Same scripts; broader purpose.

## Idea

Configure a develop environment once. After that, day-to-day prompts should not restate machine choice, worker names, or runner placement.

| Role | Meaning |
|------|---------|
| **Coding host** | Where you (or an IDE agent) are actively developing. Often has `dev` / Next or `CURSOR_DEV_I_AM_CODING=1`. |
| **Ship peer** | The other machine in the pair. Preferred for exclusive build / ship / long CI work so the coding host stays free. |

Busy-host detection → prefer peer for **build-class** work is **policy in this repo**, not a product-repo skill invention.

## What lives here

- Windows autostart for Cursor [My Machines](https://cursor.com/docs/cloud-agent/my-machines) workers
- Stable worker names and peer env vars
- Develop-env policy: coding vs ship peer, local runners on the ship host when a product uses self-hosted CI
- Verify / uninstall helpers

## What stays in product repos

- Product skills (`/release`, feedback, commit shape)
- Product runner labels, `npm run release`, Azure / doctor gates
- Thin adapters that **read** `CURSOR_DEV_*` (or product aliases) and hand off ship work to the peer

## Prerequisites (each PC)

1. [Git for Windows](https://git-scm.com/download/win) (includes Git Bash).
2. Cursor CLI: `irm 'https://cursor.com/install?win32=true' | iex`
3. One-time sign-in: `agent login` (same Cursor account as the desktop app).

Docs: [Bring your own machine](https://cursor.com/docs/cloud-agent/bring-your-own-machine), [My Machines](https://cursor.com/docs/cloud-agent/my-machines).

## Pair topology (two machines)

On each PC, set user or machine env (not committed):

| Variable | Desktop example | Laptop example |
|----------|-----------------|----------------|
| `CURSOR_DEV_WORKER_NAME` | `desktop` | `laptop` |
| `CURSOR_DEV_PEER_WORKER` | `laptop` | `desktop` |

Optional sticky when you are coding without a long-lived `dev` server:

| Variable | Meaning |
|----------|---------|
| `CURSOR_DEV_I_AM_CODING=1` | Treat this host as the coding host until cleared |

**Ship / build-class default:** if the peer is set and this host is coding-busy (`dev` / Next, or `CURSOR_DEV_I_AM_CODING=1`), do not run exclusive build/ship work here. Hand off to `CURSOR_DEV_PEER_WORKER` (product agent prints a My Machines prompt, or spawns via Cloud Agents API when a user API key is configured).

**Escape:** `CURSOR_DEV_SHIP_HERE=1` or an explicit “on this machine” in the prompt.

Start workers with matching names:

```powershell
agent worker start --name desktop   # on the desktop
agent worker start --name laptop    # on the laptop
```

(Or pass `-WorkerName` into the installers below so autostart uses the same name.)

## Local runners

This repo does not install product-specific GitHub runners. Policy only:

- Prefer starting / registering a **self-hosted local runner on the ship peer** when the product supports `--runner=auto` / local-first CI.
- Do not stack release-class runner work on the coding host when the peer is available.
- Product docs own labels, compose files, and tokens (for example TeamResume `teamresume-local`).

## Quick start (new machine)

```powershell
git clone https://github.com/adambergmanconsulting-lgtm/cursor-develop-env.git
cd cursor-develop-env\windows
Set-ExecutionPolicy -Scope Process Bypass
.\install-my-machines-autostart.ps1 -WorkerName "desktop"   # or "laptop"
# set CURSOR_DEV_WORKER_NAME / CURSOR_DEV_PEER_WORKER in Windows user env to match
```

Sign out and back in (or run the generated start script once). Then:

```powershell
agent worker debug
```

In [cursor.com/agents](https://cursor.com/agents), choose this machine under **My Machines**.

## Repo-scoped worker (optional)

For one git checkout when you need `repo=` / `worker=` routing for that remote:

```powershell
.\install-repo-worker-autostart.ps1 -WorkerDir 'E:\path\to\your\repo' -WorkerName "desktop"
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
