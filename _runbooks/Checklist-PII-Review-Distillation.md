---
title: Checklist — PII / Secrets Review for Memory Distillation (brain-G4 precondition)
type: checklist
created: 2026-06-03
audience: operator
purpose: The binding pre-G4 review — which content categories must NEVER be distilled into the brain (secrets, financial figures, health data, customer PII per the AS / Personlig rules), and how to spot-check a distilled batch before flipping brain-G4 ON.
related:
  - "[[Runbook-Autonomy-Gates-G4-G6]]"
  - "[[Secrets-Policy]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
  - "[[2026-06-03-node-migration-MOC]]"
tags: [checklist, pii, secrets, distillation, brain-G4, safety]
---

# Checklist — PII / Secrets Review for Memory Distillation

> **When to run this.** Before flipping **brain-G4** (nightly-distill) ON, and on every spot-check thereafter (per the G4 verification + weekly observe steps in [[Runbook-Autonomy-Gates-G4-G6]]). A distill layer that auto-writes nightly must never absorb secrets or PII. This checklist is the binding G4 precondition "PII review of distilled content".

> **Why it matters (binding).** The distill pipeline writes MemoryObjects into the brain, which is git-synced (tiger-brain) and shared with a collaborator (Karri), and is the corpus the RAG engine embeds. Anything distilled is therefore (a) committed, (b) cross-machine synced, and (c) embedding-eligible. Category-A content below must never reach any of those. The privacy requirement is also exactly *why* embedding/LLM run local-first on the node — see [[2026-06-03-node-migration-MOC]] §5.

---

## Part 1 — Categories that must NEVER be distilled (Category A: hard block)

If a distilled MemoryObject contains any of these, it is a **leak**. Reject the batch and do not open G4.

### A1 — Secrets / credentials (per [[Secrets-Policy]])
- [ ] No `.env` / `.env.*` **values** (tokens, API keys, DB URLs, passwords). Variable *names* are fine; values are not.
- [ ] No GitHub / cloud / broker / exchange tokens or session cookies.
- [ ] No contents of `.git/config`, `~/.ssh/**`, or any private key material.
- [ ] No connection strings with embedded credentials.

### A2 — Financial figures (AS rules)
- [ ] No concrete revenue / income amounts, bank balances, or account numbers.
- [ ] No payslip (lønnsslipp) figures, invoice amounts tied to a named party, or receipt (kvittering) line-item totals.
- [ ] No skattemelding / regnskap numbers (tax-return or bookkeeping figures). General *strategy* notes ("ENK→AS overgang") are fine; specific kroner-figures are not.

### A3 — Health data (Personlig rules)
- [ ] No medical conditions, diagnoses, medication, or clinical measurements.
- [ ] No raw health/biometric logs (sleep, weight, training metrics tied to identity) beyond non-identifying general habit notes.

### A4 — Customer / third-party PII
- [ ] No customer or partner full names tied to financial/contractual detail (refi-pilot customers, regnskapsfører clients, AS counterparties).
- [ ] No personal identifiers: fødselsnummer / personnummer, org-numbers tied to private parties, phone, private email, home address.
- [ ] No third party's private content quoted verbatim without their being a public source.

### A5 — Trading strategy specifics that are operator-confidential
- [ ] No live position sizes, account balances, or broker credentials (Nexus). Strategy *concepts* are brain-appropriate; live capital state is not.

> The distill pipeline already reduces this risk structurally: it operates on `exchange_core` (1–2 sentences) + `specific_context` (single detail), never on raw secrets (`MEMORY_DISTILLATION_SPEC` §line-402), and the §8.1 walk EXCLUDEs `00-firm-bus/feed.md`, `_library/raw/**`, `90-archive/**`, `**/.obsidian/**`. This checklist verifies the structural reduction actually held on a real batch.

---

## Part 2 — Category B: distill only if flagged `sensitive` (local-only routing)

These may legitimately live in the brain but **must carry the `sensitive:` source-type** so RAG routes them local-only (never embedded with an external provider, never sent to a cloud LLM — `MEMORY_DISTILLATION_SPEC` §line-57, `RAG_ENGINE_SPEC` §5.4/§6.3/§12).

- [ ] Operator-confidential business reasoning (pricing logic, partner negotiations) — present? then `sensitive:` set?
- [ ] Internal Nexus strategy rationale not meant for external eyes — `sensitive:` set?
- [ ] Anything the operator would not want auto-embedded by an external API — `sensitive:` set?

If a Category-B item is **missing** the `sensitive` flag, treat it as a Category-A risk for this review: reject the batch, fix the flagging, re-run, do not open G4 yet.

---

## Part 3 — How to spot-check a distilled batch (before opening G4)

Run after `brain-distill-daily` has produced a sample batch (dry-run or a manual run; do this *before* the cron is armed).

1. **Locate the batch.** Read the latest `08-system-architecture/distill-report-<date>.md` and the MemoryObjects it lists. If a `pre-distill-manifest` exists, cross-ref folder counts.
2. **Sample size.** Review **every** object if the batch is < 30; otherwise a random 30 + **all** objects whose `project` is `AS`, `Personlig`, or `Nexus` (the three highest-PII-risk projects) — review those exhaustively, not by sample.
3. **Per object, scan for Category A (Part 1).** Read `exchange_core` + `specific_context` + any quoted snippet. One category-A hit = batch fails.
4. **Per object, check Category B flagging (Part 2).** Confirm every operator-confidential item carries `sensitive:`.
5. **Check source-path provenance.** Confirm no object was distilled from an EXCLUDE path (`feed.md`, `_library/raw/**`, `90-archive/**`). If one slipped in, the walk rules regressed — file a `10-tasks/_open/` ticket and block G4.
6. **Grep sanity (mechanical backstop).** Over the distilled output, scan for high-signal leak patterns: digit-heavy strings near currency words (`kr`, `NOK`, `kroner`), `fnr`/`personnummer`, `password`/`token`/`secret`/`api_key`/`Bearer`, `.env`, 11-digit numbers (personnummer shape), IBAN-like strings. Any hit → manual confirm → if real, batch fails. (Grep is a backstop, not a substitute for the human read in step 3.)
7. **Record the result.** Log PASS/FAIL + sample size + any findings as a line in `00-firm-bus/feed.md` (or a dated drop in `00-claude-inbox/workspace/` if findings are long). Per the binding principle: this REPORTS; the operator decides whether to open G4.

### Pass criterion to open brain-G4
- [ ] Zero Category-A hits across the reviewed sample (with AS / Personlig / Nexus reviewed exhaustively).
- [ ] Every Category-B item correctly `sensitive:`-flagged.
- [ ] No object sourced from an EXCLUDE path.
- [ ] Result logged.

If any fails: **do not open G4.** Fix the distill prompt / flagging / walk-rules, re-run, re-review. A failed PII review is a normal outcome, not a blocker to be worked around.

---

## On a leak found after G4 is already ON

Per the no-auto-disable principle ([[Runbook-Autonomy-Gates-G4-G6]] §binding-principle): the health-check / spot-check **reports**; it does not auto-flip G4. The operator decides — but a confirmed category-A leak in a live nightly batch is a strong operator-action signal: flip `BRAIN_NIGHTLY_DISTILL_ENABLED=0` (30s revert), purge the leaked MemoryObject(s), and — because the brain is git-synced + shared — treat it as a secret-exposure incident (rotate any exposed credential; the value is now in git history). Re-open only after the distill prompt/flagging is fixed and a fresh batch passes this checklist.

---

## Related

- [[Runbook-Autonomy-Gates-G4-G6]] — the gate this checklist is a precondition for; §G4 references it.
- [[Secrets-Policy]] — the binding allowed / never-allowed secret-handling list (Category A1).
- [[MEMORY_DISTILLATION_SPEC]] — §line-57 (`sensitive` source-type), §line-402 (distill operates on short fields, not raw secrets), §8.1 (include/exclude walk rules).
- [[2026-06-03-node-migration-MOC]] — §5 (privacy = why embedding/LLM run local-first).
- `~/.claude/CLAUDE.md` — operator secret-handling baseline (binding).

---

Sist oppdatert: 2026-06-03 — v1.0, first issue, alongside [[Runbook-Autonomy-Gates-G4-G6]].
