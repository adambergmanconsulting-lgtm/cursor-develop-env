# cursor-develop-env

Personal **develop environment** config for Cursor: how agents, My Machines workers, and local CI runners should behave across your desks (for example a desktop + laptop pair).

Formerly `cursor-my-machines` (Windows worker autostart only). Same scripts; broader purpose.

## Relation to product repos (like Railkit)

Same posture as [railkit](https://github.com/adambergmanconsulting-lgtm/railkit): **apply** this to your desks, **improve** how you work, optionally **graduate** a practice into a host repo as that host's own docs/checks.

| Do | Do not |
|----|--------|
| Install and run this on each develop PC | Add this repo as a submodule, package, or required clone of TeamResume (or any product) |
| Keep worker installers and peer topology here | Make product CI, skills, or `npm` scripts fail if this repo is missing |
| When a habit proves useful, copy a **thin native** rule into the product (product-owned, no link required) | Import or `require()` this repo from product code |
| Improve process here first (pair policy, autostart, handoff helpers) | Treat product release/doctor/runner **implementation** as belonging here |

**TeamResume (and other hosts) must stay fully usable without `cursor-develop-env`.** Single-machine defaults, `/release`, and local runners remain product-owned. This repo is optional operator tooling and process R&D.

## Idea

Configure a develop environment once. After that, day-to-day prompts should not restate machine choice, worker names, or runner placement.

| Role | Meaning |
|------|---------|
| **Coding host** | Where you (or an IDE agent) are actively developing. Often has `dev` / Next or `CURSOR_DEV_I_AM_CODING=1`. |
| **Ship peer** | The other machine in the pair. Preferred for exclusive build / ship / long CI work so the coding host stays free. |

Busy-host detection → prefer peer for **build-class** work is **policy invented and iterated here**. A product may later adopt an equivalent thin rule in its own tree; until then, behavior comes from this env + how you start agents, not from a product dependency.

## What lives here

- Windows autostart for Cursor [My Machines](https://cursor.com/docs/cloud-agent/my-machines) workers
- Stable worker names and peer env vars
- Develop-env policy: coding vs ship peer, local-runner *placement* habits when a product supports self-hosted CI
- Verify / uninstall helpers; optional generic handoff helpers (no product imports)

## What stays in product repos

- Product skills (`/release`, feedback, commit shape), with or without any mention of this repo
- Product runner labels, `npm run release`, Azure / doctor gates
- Any graduated thin adapter the product chooses to own (optional; never required to clone this repo)

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
