---
tags: [nexus, infra, bootstrap, cognitive-os]
created: 2026-05-11
type: session-report
---

# Clone-guide bootstrap — 2026-05-11

## What landed

- `scripts/setup/bootstrap-cognitive-os.sh` — 92 LoC idempotent bash, syntax-clean. Stages: prereq check → clone → npm install → vault skeleton + symlink → minimal `~/.claude/settings.json` (only if missing) → MCP-registration template print → next-step checklist.
- `docs/architecture/cognitive-os-clone-guide.md` — inventory (portable vs operator-specific), one-liner, walkthrough, MCP template, memory starter-pack vs accumulated, verify checklist, gotchas.

## Design choices

- **Refuses to overwrite an existing `settings.json`** — too easy to wipe operator's hook config on a re-run. Prints a merge hint instead.
- **MCP registration is print-only** — script never embeds keys. Operator copies the four `claude mcp add` lines into their terminal with their own values.
- **Vault skeleton is bare** — directory tree + repo-docs symlink + stub README only. No operator content carried.
- **No Railway / Postgres / Discord creation** — explicit constraint: clone = workstation clone, not infra clone. Both PCs point at the same SaaS.
- **No memory auto-copy** — distillation hook builds new memory natively over the first week. Starter pack in clone-guide §"Memory" lists files worth manually copying (anonymized list).

## Operator-friendliness after running script

~5 manual steps remain:
1. `cp .env.example apps/{api,worker}/.env` and paste keys (operator-only by safety rules).
2. Run the four `claude mcp add` commands with their own keys.
3. Install the Obsidian Local REST API community plugin (GUI-only, no CLI path exists).
4. `bash scripts/ops/env-doctor.sh` + `bash scripts/ops/verify-cognitive-os.sh` for green-light.
5. Optionally alias `firm-up`.

## Top 3 gotchas

1. **settings.json merge** — bootstrap won't overwrite a pre-existing one. Operator must hand-merge `SessionStart` + `Stop` hook entries. Hint printed.
2. **Obsidian plugin install is GUI-only** — `docs/ref/obsidian-setup.md` documents this. The MCP registration command in the template will fail to connect until the plugin runs.
3. **SSH key prereq** — `git clone git@github.com:...` needs the operator's SSH key on the new PC, or swap to HTTPS / `gh auth setup-git` first.

## Not done (out of scope)

- Memory starter-pack as a literal file — only documented as a list to copy by hand. Avoids stale snapshots in the repo.
- Automatic Railway env-export (would leak secrets).
- Windows-Obsidian symlink fallback (rsync) — referenced in `obsidian-bridge.md` but not scripted.
