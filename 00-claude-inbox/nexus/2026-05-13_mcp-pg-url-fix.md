# MCP `nexus-pg` warning fix — `NEXUS_READONLY_PG_URL` not loaded in WT tabs

**Date**: 2026-05-13
**Filed by**: parallel polish batch (audit agent)
**Severity**: low — cosmetic warning in `/doctor`; MCP still works when env var is present in shell

---

## Symptom

`claude /doctor` in any of the 4 `ai-*` Windows Terminal tabs prints:

```
[Warning] [nexus-pg] mcpServers.nexus-pg: Missing environment variables: NEXUS_READONLY_PG_URL
```

The 4 non-nexus panes (`code-*`, `thesis-*`) don't show it because they live outside `/home/nithu/code/ai-assistent` and don't load that `.mcp.json`.

---

## Root cause

`/home/nithu/code/ai-assistent/.mcp.json` declares:

```json
"args": ["-y", "@modelcontextprotocol/server-postgres", "${NEXUS_READONLY_PG_URL}"]
```

The var is expected to live in `/home/nithu/code/ai-assistent/.env.local` (per the description string in `.mcp.json` and the loader contract in `scripts/firm/run-with-env.sh`).

Two launch paths exist and they treat env differently:

| Launcher | Loads `.env.local`? | MCP warning? |
|---|---|---|
| `firm-up` zellij (uses `scripts/firm/run-with-env.sh`) | YES (`load_env .env.local`) | No |
| `/home/nithu/code/_bin/firm-tab-init.sh` (wt.exe `firm` / `firmt` / `firmz` tabs) | NO — `exec claude` directly | **Yes** |

The wt.exe-launched tabs go straight from `bash -lic "$INIT $role $project"` into `exec claude --dangerously-skip-permissions` without sourcing `.env.local`. So Claude's MCP launcher can't substitute `${NEXUS_READONLY_PG_URL}` and emits the warning. The MCP server itself is fine when actually invoked, because the operator's interactive shell tools (this conversation included) end up with the var set some other way (probably from another path or a previous session export).

Also: `NEXUS_READONLY_PG_URL` is **not documented** in `.env.example` (zero matches). It's referenced in `docs/ops/firehose-setup.md` and written by `scripts/firehose/setup-local.sh` but a fresh operator wouldn't find it from `.env.example` alone.

---

## Proposed fix (preferred — one-line in `firm-tab-init.sh`)

Add a single sourcing line right before `exec claude` in `/home/nithu/code/_bin/firm-tab-init.sh`:

```bash
# Load nexus secrets so .mcp.json ${NEXUS_READONLY_PG_URL} resolves.
# Only sourced for the ai-* role; other roles don't need it.
if [[ "$project" == "nexus" && -f "$HOME/code/ai-assistent/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$HOME/code/ai-assistent/.env.local" 2>/dev/null || true
  set +a
fi

exec claude --dangerously-skip-permissions
```

Notes:
- `set -a` / `set +a` ensures every var in `.env.local` is exported (so Claude's child MCP launcher sees it).
- Guarded by `$project == "nexus"` so `code-*` / `thesis-*` tabs don't pull in unrelated secrets.
- `|| true` so a missing file (fresh clone) doesn't break tab launch.
- Better than `.bashrc` export because secrets stay scoped to the tabs that need them.

---

## Alternative fixes (less ideal — flagged for completeness)

1. **Export in `~/.bashrc`**
   - Bash login would set the var for every shell.
   - **Downside**: leaks secrets to all WSL processes incl. non-nexus projects. Operator's CLAUDE.md secret-handling policy discourages this kind of broad leakage.

2. **Reuse `scripts/firm/run-with-env.sh` from wt.exe**
   - `firm-tab-init.sh` could `source run-with-env.sh` first.
   - **Downside**: that script is built for zellij (it `cd`s to repo root and `exec "$@"`), would need refactor to be reusable from wt.exe. More moving parts than the one-line fix.

3. **Inline the value into `.mcp.json`**
   - **Reject outright**: secret in committed file.

---

## Sub-task (orthogonal, recommended)

Add `NEXUS_READONLY_PG_URL` to `.env.example` with a comment line so new operators / fresh clones see it:

```
# Read-only Postgres URL for the nexus-pg MCP server (.mcp.json substitutes it).
# Provision via scripts/firehose/setup-local.sh or copy from Railway claude_readonly user.
NEXUS_READONLY_PG_URL=
```

Doesn't fix the warning, but closes the discoverability gap.

---

## Verification path after fix

1. Apply edit to `firm-tab-init.sh`.
2. Close all `ai-*` Windows Terminal tabs.
3. Relaunch via `firm` (or `firmt` / `firmz`).
4. In one `ai-*` tab: run `claude /doctor` → warning should be gone.
5. In same tab: `mcp__nexus-pg__query "SELECT 1"` → confirms the var actually substituted.

---

## Status

- **Proposed by**: parallel polish batch agent, 2026-05-13
- **Approved by**: pending operator review
- **Implemented**: not yet
- **Reviewer needed**: none (ops/infra change, no money-impact, operator owns)
