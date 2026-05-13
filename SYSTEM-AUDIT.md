---
tags: [meta, audit, source-of-truth]
type: meta
created: 2026-05-13
---

# SYSTEM-AUDIT

Strict audit of the Brain vault. This file is the canonical truth about *how the vault is organised, what is risky, and what to fix before sharing with a teammate*. Both humans and Claude should read this when they need to reason about the vault as a whole.

**Last audited**: 2026-05-13 (post-cleanup pass; previous audit 2026-05-11)

**Health score**: **8/10**

Reasoning for 8/10:
- Plus: clear top-level folder layout, README hub exists, `_maps/` MOC layer is rich (46 files), runbooks and decisions are separated, archive folder exists. Root artifacts gone. Path-prefix duplicate resolved. `.gitignore` hardened against the obvious accidental commits. Inbox archive automation now exists. Audit script no longer false-positives on code-fence wikilinks.
- Minus: API key + RSA private key were committed in `f824aa8` before `.gitignore` was hardened — gitignore prevents *future* leaks, but the secret is in **git history**. Operator must rotate and decide purge-vs-accept (see "Currently risky" below). Plus: 30 uncommitted modifications still in working tree, no git remote yet, CODEOWNERS placeholders unfilled.
- Once the API-key-in-history item is resolved and the remote is up with branch protection, the vault should score 9/10. See "What's left to push to 9/10" below.

---

## Folder map

| Path | Purpose (one line) |
|---|---|
| `00-claude-inbox/` | Raw notes Claude (or operator) drops in during sessions. Lifecycle: triage → promote into project folder or archive within ~30 days. 107 files currently in `nexus/` subfolder. |
| `01-nexus/` | Nexus XAUUSD trading firm. Strategies, journal, risk, post-mortems. Source of truth: `Nexus-MOC.md`. |
| `02-thesis/` | Master's thesis on ML for solid-state electrolytes. Source of truth: `Thesis-MOC.md`. Code lives in sister repo `battery-electrolyte-predictor`. |
| `03-business/` | Business / company / operator-side notes that aren't Nexus-specific. |
| `04-career/` | Career planning, applications, CV, interviews. |
| `05-learning/` | Long-form learning notes (courses, books, technical deep-dives). Not project-bound. |
| `90-archive/` | Frozen state. Do NOT cite as current. Read-only by convention. |
| `_decisions/` | Architecture / strategy / operator-decision records (ADR-style). 8 files currently. Append-only by convention. |
| `_maps/` | Maps Of Content (MOCs). The navigation layer over the project folders. 46 files — this is the heavy spine of the vault. |
| `_runbooks/` | Step-by-step runbooks: ops, recovery, weekly review, deployment. 6 files currently. |
| `_promote-candidates/` | Staging area for notes graduating out of `00-claude-inbox/`. Mostly empty right now. |
| `claude-context/` | Entry-point folder for Claude Code sessions. `START-HERE.md`, `CURRENT.md`, and similar. |
| `scripts/` | Python + bash helpers for the vault. `path_guard.py`, `brain_audit.py`, `archive_old_inbox.py`, `sanity.sh`, `setup-from-scratch.sh`. |
| `prompts/` | Reusable prompt fragments / templates for Claude. |
| `.github/` | GitHub workflows (`brain-checks.yml`, `path-guard.yml`) + CODEOWNERS. |
| `handoffs/` | Multi-session / multi-operator handoff notes. |
| Root MD files | `README.md` (central hub), `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`, `BRAIN-RULES.md`, `CONTRIBUTING.md`, `TEAMMATE-ONBOARDING.md`, `FINAL-SHARING-CHECKLIST.md`, `OPERATOR-NEXT-STEPS.md`, `SYSTEM-AUDIT.md` (this file). |

---

## Source-of-truth files

When two notes disagree, these win. Listed roughly from "most general" to "project-specific":

1. `README.md` — central hub. Points to everything else.
2. `00-DASHBOARD.md` — current state across all projects (one-pager).
3. `01-CURRENT-FOCUS.md` — what the operator is actively working on right now.
4. `BRAIN-RULES.md` — conventions for the vault (naming, folders, lifecycle, frontmatter).
5. `claude-context/CURRENT.md` — short-lived working context for Claude sessions.
6. `_decisions/*.md` — append-only ADRs. If a decision is recorded here it overrides any project note.
7. `01-nexus/Nexus-MOC.md` — Nexus project map (source of truth for the Nexus folder).
8. `02-thesis/Thesis-MOC.md` — thesis project map.
9. `_maps/*-MOC.md` — domain-specific MOCs for cross-cutting topics.

If a note in `00-claude-inbox/` contradicts any of the above, the inbox note is wrong by default — it is raw input, not truth.

---

## Which files Claude should read first

Strict order. Stop as soon as you have enough context for the task at hand.

1. `claude-context/START-HERE.md` — orientation, "what is this vault, what is the operator working on, what are the rules".
2. `BRAIN-RULES.md` — conventions you MUST follow when writing into the vault.
3. `00-DASHBOARD.md` — current state across projects.
4. `01-CURRENT-FOCUS.md` — what the operator is on right now.
5. The relevant MOC for the task:
   - Nexus work → `01-nexus/Nexus-MOC.md`
   - Thesis work → `02-thesis/Thesis-MOC.md`
   - Cross-cutting topic → the matching `_maps/<topic>-MOC.md`
6. This file (`SYSTEM-AUDIT.md`) only if the question is *about the vault itself* (structure, hygiene, risk).

If you are tempted to read `00-claude-inbox/` first: don't. Treat it as raw input, not truth.

---

## Old / archive

- `90-archive/**` is frozen. Treat it as historical. Do **not** cite anything inside it as the current state of a project.
- Files under `90-archive/` may contradict current notes — that is expected and OK.
- If you find yourself wanting to *modify* anything under `90-archive/`, stop. The right move is almost always to write a new note in the active project folder instead.

---

## Fixed since 2026-05-11 audit

- `Untitled.canvas` (2 bytes, `{}`) — **DELETED**.
- `Untitled.base` (39 bytes, empty table view) — **DELETED**.
- `2026-05-11.md` (0 bytes, root daily note) — **DELETED**.
- Duplicate `Brain/Brain/01-nexus/strategies/scalp-overlap-losses-2026-05-11.md` — **MOVED** to canonical `01-nexus/strategies/scalp-overlap-losses-2026-05-11.md`. The `Brain/Brain/` parent path no longer exists; the note is now properly linkable.
- `.gitignore` **extended** to block: `.obsidian/plugins/obsidian-local-rest-api/`, `__pycache__/`, `*.pyc`, `.DS_Store`, `Thumbs.db`.
- `scripts/archive_old_inbox.py` **added** — implements the 30-day inbox lifecycle promised in `00-claude-inbox/README.md`. Moves files older than 30 days from `00-claude-inbox/` into `90-archive/<year>/inbox/`.
- `scripts/brain_audit.py` **improved** — skips wikilinks inside fenced code blocks, eliminating a class of false-positive warnings.

---

## Currently risky

Specific findings as of 2026-05-13. Each item has a recommendation; the operator decides.

1. **API key + RSA private key in git history (`f824aa8`)** — CRITICAL
   - `.obsidian/plugins/obsidian-local-rest-api/data.json` was committed in commit `f824aa8` *before* `.gitignore` was hardened. The file contains an API key and an RSA private key.
   - `.gitignore` now blocks this path so future commits are safe, **but the secret is still in git history**. Anyone who clones the repo can read it.
   - Operator must choose:
     - **(a)** Rotate the key + purge history with `git filter-repo --path .obsidian/plugins/obsidian-local-rest-api/data.json --invert-paths` *before the first push to GitHub*. Cleanest option while the repo is still local-only.
     - **(b)** Rotate the key and accept that the old key remains in the cloned history forever. Acceptable only if the key is fully revoked first.
   - See `OPERATOR-NEXT-STEPS.md` step 3 for the exact commands.

2. **30 uncommitted modified files**
   - Mix of intentional work-in-progress and accidental changes is likely. Operator should `git status` + `git diff` and decide what to commit, what to stash, what to revert.
   - Do this *before* setting up the remote — otherwise the first push includes noise.

3. **No git remote configured**
   - Cannot share via GitHub yet. See fix-before-share checklist step 4.

4. **107 files in `00-claude-inbox/nexus/`**
   - `scripts/archive_old_inbox.py` now exists but is not yet wired into CI. Operator should run it manually for now, or accept that the inbox will keep growing until the scheduled workflow lands (see "What's left to push to 10/10").

5. **CODEOWNERS still has `@OWNER` / `@TEAMMATE` placeholders**
   - Branch protection will rely on this file. Fill in real GitHub handles before enabling protection.

---

## Missing → created (this session and the previous one)

Already in place:

- `claude-context/` (folder + `START-HERE.md`, `CURRENT.md`)
- `scripts/` (`path_guard.py`, `brain_audit.py`, `archive_old_inbox.py`, `sanity.sh`, `setup-from-scratch.sh`)
- `prompts/`
- `.github/` (`workflows/brain-checks.yml`, `workflows/path-guard.yml`, `CODEOWNERS`)
- `handoffs/`
- `00-DASHBOARD.md`
- `01-CURRENT-FOCUS.md`
- `BRAIN-RULES.md`
- `CONTRIBUTING.md`
- `TEAMMATE-ONBOARDING.md`
- `FINAL-SHARING-CHECKLIST.md`
- `OPERATOR-NEXT-STEPS.md`
- `SECURITY-INCIDENT-API-KEY.md` *(if another agent has created it; verify on next audit)*

This file (`SYSTEM-AUDIT.md`) is one of the deliverables in that list.

---

## Fix-before-share checklist

Numbered, ordered. Do not skip ahead — earlier steps protect later ones.

1. **Resolve the API-key-in-history incident.** Rotate the key. Decide purge vs accept. See `OPERATOR-NEXT-STEPS.md` step 3.
2. **Operator reviews the 30 uncommitted modifications.** `git status`, `git diff`. Commit what is intentional. Stash or revert what isn't.
3. **Replace `@OWNER` and `@TEAMMATE` placeholders** in `.github/CODEOWNERS` with the actual GitHub handles.
4. **Create GitHub remote (private repo)** and `git push -u origin main`. (Only after step 1 is resolved.)
5. **Enable branch protection** on `main` per `FINAL-SHARING-CHECKLIST.md` (require PR, require status checks `brain-checks` and `path-guard` to pass).
6. **Run `python scripts/brain_audit.py`** locally. Output must be green (no errors). Iterate until it is.
7. **Invite teammate as a collaborator**: read access to the whole vault, write access only to folders listed in `CODEOWNERS`.
8. **Send teammate `TEAMMATE-ONBOARDING.md`** as the one link they need. That file should walk them to everything else.

---

## What's automated now

- `scripts/brain_audit.py` — verifies vault structure (expected folders exist, root artifacts absent, no `Brain/Brain/` prefix bug, no empty MOCs, frontmatter on key files). Now skips wikilinks inside code fences. Run locally or via CI.
- `scripts/path_guard.py` — inspects PR diffs to reject paths outside the allowed folder set, files with no frontmatter, and the `Brain/Brain/` prefix bug.
- `scripts/archive_old_inbox.py` — moves `00-claude-inbox/` files older than 30 days into `90-archive/<year>/inbox/`. Currently run manually; CI scheduling listed under "What's left to push to 10/10".
- `scripts/sanity.sh` — quick local pre-push sanity sweep (audit + path guard + git status check).
- `.github/workflows/brain-checks.yml` — runs `brain_audit.py` on every PR and on push to `main`.
- `.github/workflows/path-guard.yml` — runs `path_guard.py` on every PR.

---

## What's still manual

- Branch protection settings on GitHub (one-time, GUI).
- Inviting the teammate as a collaborator (one-time, GUI).
- Deciding which `_promote-candidates/` notes graduate into a project folder.
- Running `scripts/archive_old_inbox.py` (until CI scheduling lands).
- Secret rotation if any secret ever leaks into a note (one already has — see "Currently risky" #1).
- Updating this file when the vault's structure changes meaningfully.

---

## What's left to push to 9/10

- Resolve the API-key-in-history incident (operator decision: purge vs accept).
- Replace `@OWNER` / `@TEAMMATE` placeholders in `.github/CODEOWNERS`.
- Decide and commit the 30 modified files in operator's working tree.
- Create GitHub remote + push + enable branch protection.
- Once teammate is onboard, expand `_decisions/` with teammate-relevant entries (review process, escalation, on-call expectations).

---

## What's left to push to 10/10

- Inbox automation in CI: run `archive_old_inbox.py` monthly via a scheduled workflow (cron in GitHub Actions).
- Stronger secret-scan in CI: e.g. `detect-secrets` or `trufflehog` as a required check on every PR. Would have caught the API-key incident.
- Coverage report for `scripts/`: pytest + coverage, with a minimum threshold enforced in CI.
- Automated weekly refresh of `claude-context/CURRENT.md` from `docs/ops/phase-status.md` (scheduled workflow or local cron).

---

## Notes on running the helpers

- `scripts/brain_audit.py` is intended to be runnable as `python scripts/brain_audit.py` from the vault root. Exit code 0 = clean, non-zero = findings to address.
- `scripts/archive_old_inbox.py` runs from the vault root. Dry-run by default; pass `--apply` to actually move files.
- `scripts/sanity.sh` is the one-shot pre-push check. `chmod +x scripts/sanity.sh` once, then `./scripts/sanity.sh`.
- `scripts/setup-from-scratch.sh` is intended for a teammate (or operator on a fresh machine) to clone and verify the vault. After cloning, `chmod +x scripts/setup-from-scratch.sh` once, then run it. See the file's header comment for arguments.

---

Run `python scripts/brain_audit.py` to refresh findings. Update this file manually if structure changes.
