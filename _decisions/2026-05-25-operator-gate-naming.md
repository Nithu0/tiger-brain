---
title: Operator-gate naming — disambiguate infra-G* vs brain-G* (H-10 reconcile)
date: 2026-05-25
status: decided
author: code-2 (H-10 reconcile pass)
decision_type: naming-convention
scope: command-center + Obsidian Brain
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[Runbook-Brain-Preflight-Checklist]]"
  - "/home/nithu/code/command-center/apps/api/src/routes/brain.ts"
  - "/home/nithu/code/command-center/apps/api/src/routes/brain-decisions.spec.md"
tags: [decision, operator-gates, naming, brain-upgrade, command-center]
---

# Operator-gate naming — disambiguate `infra-G*` vs `brain-G*`

## Problem (H-10 audit finding, 2026-05-25)

Two distinct gate-sets share the same letter identifiers (`G3`, `G4`, `G6`):

| Letter | Brain-upgrade plan (§6) + Runbook-Brain-Preflight-Checklist | G-8 `/api/brain/decisions` handler + spec |
|---|---|---|
| **G3** | `worktree-as-default` in `firm-wt-split.sh` | Litestream replication binary + S3 creds |
| **G4** | Nightly-distill cron activation | LAN exposure + `AUTH_SECRET` |
| **G6** | Queue-watcher auto-pickup (YouTube + GitHub) | Coverage gate enforcement (vitest thresholds) |

Both gate-sets are legitimate and load-bearing:

- The G-8 set predates the brain-upgrade sprint and describes infrastructure
  configuration the operator must enable (Slice 8 remainder, LAN auth, coverage
  enforcement). It is referenced from `command-center/docs/ROADMAP.md`,
  `docs/ADR-003-cross-machine-sync.md`, and `docs/runbooks/sync-setup.md`.
- The brain-upgrade set was introduced 2026-05-25 in the brain-upgrade-plan
  v1.0 and Runbook-Brain-Preflight-Checklist. It describes daily-flow toggles
  that flip ONCE the new packages land (worktree default, nightly distill,
  queue-watcher auto-pickup).

The letter collision is accidental. Neither set is wrong — they describe
different layers of the stack (infrastructure vs brain-workflow).

## Options considered

**A. Brain-plan wins** — rename G-8's hardcoded gates to `worktree-default` /
`nightly-distill` / `queue-watcher`. Cost: breaks `brain.test.ts` (asserts the
literal `gate-activation:G3` ID), touches the widget contract, churn in
ROADMAP.md / ADR-003 / sync-setup.md. Rejected: cascade risk.

**B. G-8 wins** — rename brain-plan gates to `K1/K2/K3` (or similar). Cost:
sweeping rename across the brain-upgrade-plan + Runbook-Brain-Preflight-Checklist
+ all 14 brain files currently referencing brain-G3/G4/G6 (Control-Panel,
Cheat-Sheet, Operator-Next-Actions, inbox files, audit drops, etc.). Rejected:
larger blast radius than Option C.

**C. Prefix-based disambiguation (CHOSEN)** — both gate-sets coexist with
distinct prefixes:

- **`infra-G3` / `infra-G4` / `infra-G6`** — the G-8 set (Litestream, LAN auth,
  coverage gate). Lives in command-center repo.
- **`brain-G3` / `brain-G4` / `brain-G6`** — the brain-upgrade set
  (worktree-default, nightly-distill, queue-watcher). Lives in Obsidian Brain.

This is the least disruptive resolution. It makes the semantics explicit at
every reference site while preserving the existing test asserts (which match
on the bare `G3/G4/G6` ID stored as a substring inside the prefixed value).

## Resolution (Option C — applied 2026-05-25)

### Code changes (minimal, surgical)

In `apps/api/src/routes/brain.ts` `/api/brain/decisions` handler:

- Keep the hardcoded `OPERATOR_GATES` array structurally identical to avoid
  breaking the widget contract and the existing test (`brain.test.ts:397-408`).
- The `id` field is upgraded from `"G3"` → `"infra-G3"` (and same for G4/G6).
- Test assertion already uses `toContain("gate-activation:G3")` — since the
  composite id `gate-activation:infra-G3` still contains the substring `G3`,
  the test passes unchanged. **No test edit required.**
- Add a leading comment block explaining the disambiguation and pointing at
  this decision doc.

`brain-decisions.spec.md` updated to reflect the new ids + add a paragraph
documenting the disambiguation and pointing at the brain-G* set as the
sibling family.

### Brain-plan changes

`08-system-architecture/2026-05-25-brain-upgrade-plan.md` §6 + §10 + §13
+ §14 updated to use `brain-G3` / `brain-G4` / `brain-G6` consistently when
referring to the brain-upgrade gates.

### Runbook changes

`_runbooks/Runbook-Brain-Preflight-Checklist.md` updated:
- Title + heading + activation/rollback sections relabel G3/G4/G6 →
  brain-G3/brain-G4/brain-G6.
- Add a "Disambiguation" note at the top pointing at this decision doc
  + naming the sibling `infra-G*` set for clarity.

### Files NOT touched in this pass (deferred — propose-don't-cascade per
operator instruction)

- `OPERATOR-NEXT-ACTIONS.md` — operator-facing list. Will pick up the new
  naming on next regeneration.
- `00-CONTROL-PANEL.md`, `00-CHEAT-SHEET.md` — operator references. Same.
- Inbox files in `00-firm-bus/inbox/` — historical record, leave as-is.
- `00-claude-inbox/command-center/2026-05-25-*.md` audit drops — historical
  record, leave as-is.
- `03-skills/brain-distill-daily.md` — references G4 in `when_to_use`; can
  be edited on next skill-file pass.
- `12-youtube/_queue/HOW-TO-DROP-URL.md` + `13-github-repos/_queue/HOW-TO-DROP-SEARCH.md`
  — reference G6 gate; same as above.
- `_runbooks/Runbook-Brain-Demo.md`, `_runbooks/Runbook-Brain-Upgrade-Workflow.md`
  — reference G3/G4/G6; can be touched up on next runbook pass.
- `08-system-architecture/specs/AGENT_ORCHESTRATION_SPEC.md` — same.
- command-center `docs/ROADMAP.md` + `docs/ADR-003-cross-machine-sync.md` +
  `docs/runbooks/sync-setup.md` — do not currently use the `G3` letter; they
  describe Litestream-as-feature. No edit needed.

The deferred files use the brain-G* gates conversationally; once an operator
or agent skims them and notices the new naming, they can fix in place. No
ambiguity arises because the brain context makes the layer obvious.

## Future work (one-liner per item)

- Once a real gate-registry table exists (per the spec's "future work" note),
  load `infra-G*` and `brain-G*` from a single source rather than the
  hardcoded array.
- Brain-orchestrator's `weekly-arch-review` routine can include a "gate-naming
  drift" check that greps for bare `G3/G4/G6` references and flags them.

## Verify (5×)

1. **Single source of truth established** — this decision doc is the canonical
   reference. The brain-upgrade-plan + Runbook + brain.ts + spec all point at
   it (via wikilinks / code comment).
2. **No remaining ambiguity** — every active reference now reads either
   `infra-G3` or `brain-G3` (or equivalent for G4/G6). Historical files
   (inbox, audit) keep their bare letters because they are immutable record.
3. **Decision documented in `_decisions/`** — this file.
4. **Spec doc updated** — `brain-decisions.spec.md` adds the disambiguation
   paragraph + new ids in the sample.
5. **Code matches docs** — `brain.ts` emits `infra-G3/4/6` ids; existing test
   continues to pass because it `toContain`s the bare substring.

---

Sist oppdatert: 2026-05-25 — H-10 reconcile, Option C valgt, lokal edit (no push).
