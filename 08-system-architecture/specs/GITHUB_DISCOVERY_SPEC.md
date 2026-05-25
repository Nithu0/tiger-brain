---
title: GitHub Discovery Spec
date: 2026-05-25
status: v1.0.2
spec_for: Module F (GitHub Discovery) — brain-upgrade-plan
author: A-5 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
tags:
  - spec
  - github
  - discovery
  - license
  - security
---

# GitHub Discovery Spec

## 1. Overview

**Purpose.** Discover public GitHub repositories that could accelerate the operator's projects (Nexus, command-center, research-os, thesis, AS, Personlig, Søking fulltid), distill the relevant signal into the Obsidian brain (`13-github-repos/`), and optionally propose implementation-tasks against the operator's own repos — without ever executing untrusted code.

**Non-goals.**
- Not a package manager. We never install discovered code.
- Not a clone-and-run sandbox. We never `git clone`.
- Not an automatic code-copier. Patterns are summarised conceptually; literal copy-paste requires operator OK kjør.

**Inputs.**
- Queue files in `13-github-repos/_queue/` (one per query).
- Operator goal-context from `00-DASHBOARD.md` + `01-CURRENT-FOCUS.md`.
- License-policy table (this spec, §5).
- Rate-limit state from `firm_state` KV store.

**Outputs.**
- One distilled repo-note per scored repo at `13-github-repos/<owner>-<name>.md`.
- (Optional, gated) Implementation-task proposals at `10-tasks/_open/T-YYYY-MM-DD-NNN-<slug>.md`.
- Learning events emitted to BrainOrchestrator on completion or failure.

**Binding constraints (operator-stated).**
- Most-advanced, safe (no execute), license-aware.
- All worker code in TypeScript. Shell out to `gh` CLI for all GitHub interaction.
- Implementation-task proposals always require operator OK kjør.

---

## 2. Pipeline architecture

```
13-github-repos/_queue/YYYY-MM-DDTHHMM-<slug>.md
   (contains: "search: <query>", optional "# limit: N", "# topic: <topic>")
       │
       ▼
BrainOrchestrator (trigger:github-discovery, fs-watch on _queue/)
       │
       ▼
agent_tasks INSERT {role: "research", payload: {query, limit, topic}}
       │
       ▼
packages/github-discovery worker
       │
       ├── (a) SEARCH
       │     gh search repos --topic <X> --stars '>=N' --updated '>=YYYY-MM-DD' \
       │            --limit <page-size> --json fullName,description,stargazersCount,...
       │     (paginated; rate-limit-checked against firm_state)
       │
       ├── (b) SCORE (per repo, all in result set)
       │     relevance_score  ← LLM(repo.description + first 800 chars of README
       │                          vs operator goal-context)
       │     activity_score   ← commits_30d / (commits_365d / 12)   (clamped [0,1])
       │     license_compatible ← license-policy table (§5)
       │     risk_score       ← aggregate(license + cve + maintainership + scripts)
       │
       ├── (c) EXTRACT (per top-N where N = min(limit, 10))
       │     gh repo view <full_name> --json ...
       │     gh api repos/<owner>/<name>/contents/README.md   (decode base64)
       │     gh api repos/<owner>/<name>/contents/package.json | Cargo.toml |
       │            pyproject.toml | requirements.txt | setup.py
       │     gh api /advisories?affects=<owner>/<name>
       │     NEVER clone. NEVER execute. Metadata + README + manifest only.
       │
       ├── (d) DISTILL
       │     LLM(metadata + README + manifest) → repo-note with frontmatter (§3)
       │     Write 13-github-repos/<owner>-<name>.md
       │
       ├── (e) TASK PROPOSAL (gated)
       │     if relevance_score > 0.7
       │        AND license_compatible == true
       │        AND risk_score < 0.4 :
       │            draft 10-tasks/_open/T-...-<slug>.md
       │            with operator-approval-required: true
       │     else: skip (note created, no task)
       │
       └── (f) EMIT learning-event
             {task_id, module:"github-discovery", outcome, surprising_finding?,
              suggested_skill?}
```

**Concurrency.** Worker processes queue files sequentially per pane (single writer per `13-github-repos/`). Parallelism is achieved by multiple queue files dispatched as separate `agent_tasks`.

**Idempotency.** If `13-github-repos/<owner>-<name>.md` already exists, the worker updates the existing note in place (preserving operator annotations beneath a `<!-- operator-notes -->` marker) and bumps `discovered` → `last_refreshed` field.

---

## 3. Frontmatter — repo note (`13-github-repos/<owner>-<name>.md`)

```yaml
---
title: <owner>/<name>
repo: https://github.com/<owner>/<name>
owner: <user_or_org>
name: <repo-name>
stars: <int>
forks: <int>
last_commit: <ISO-8601>
primary_language: <lang>            # e.g. TypeScript, Rust, Python
license: <SPDX-id>                  # e.g. MIT, Apache-2.0, GPL-3.0
license_compatible: <true|false|maybe>
discovered: <ISO-8601>
last_refreshed: <ISO-8601>          # = discovered on first write
query_source: "<original search query>"
relevance_score: <0.0-1.0>
activity_score: <0.0-1.0>
risk_score: <0.0-1.0>               # higher = riskier
integration_difficulty: <low|medium|high>
has_install_script: <bool>          # package.json scripts.install present
has_postinstall_hook: <bool>        # scripts.postinstall present
security_red_flags: [<string>, ...] # e.g. ["postinstall", "obfuscated-build", "recent-cve"]
needs_manual_review: <bool>         # true if license unknown or LGPL or risk>=0.6
tags: [github, <topic-tag>, <language-tag>]
---
```

**Field provenance.**
- `stars`, `forks`, `last_commit`, `primary_language` — `gh repo view --json`.
- `license` — `gh repo view --json licenseInfo.spdxId`. If absent or `NOASSERTION`, set `license: unknown`, `license_compatible: false`, `needs_manual_review: true`.
- `discovered` — first write; `last_refreshed` — every refresh.
- Scores — see §7.

---

## 4. Note body sections (markdown after frontmatter)

```markdown
# <owner>/<name>

> <one-line description from gh repo view>

## Summary
<LLM-generated, 2-3 sentences. Focus on what the repo DOES and why the operator
might care, NOT on stars/popularity.>

## Useful patterns to copy conceptually
- <pattern 1: e.g. "uses SQLite WAL + FTS5 for hybrid retrieval — same shape as
  our Module G">
- <pattern 2>
- <pattern 3>
(No literal code blocks longer than 10 lines. Conceptual only.)

## Dependencies + integration cost
- Runtime: <node>=18, etc.>
- Key deps: <top 5 from manifest>
- Estimated integration cost: low | medium | high
- Reasoning: <1-2 sentences>

## Install risk assessment
- has_install_script: <bool> — <if true, what it does>
- has_postinstall_hook: <bool> — <if true, what it does>
- security_red_flags: [...]
- CVE check: <none | CVE-YYYY-NNNNN listed in gh advisories>
- Verdict: SAFE_TO_READ | SAFE_TO_LIFT_PATTERNS | DO_NOT_INSTALL

## Suggested tasks for our repos
<Only populated if relevance_score > 0.7 AND license_compatible == true
 AND risk_score < 0.4. Otherwise: "None (gated out — see frontmatter).">
- [[10-tasks/_open/T-YYYY-MM-DD-NNN-<slug>]]

## Source refs
- Repo: <url>
- README fetched: <ISO>
- Manifest fetched: <ISO>
- gh advisories checked: <ISO>

<!-- operator-notes -->
<!-- preserved across refreshes; worker never edits below this marker -->
```

---

## 5. License policy (hardcoded, with operator-override)

| SPDX-id | `license_compatible` | Task-proposal allowed | Notes |
|---|---|---|---|
| MIT | true | yes | preferred |
| BSD-2-Clause, BSD-3-Clause | true | yes | preferred |
| Apache-2.0 | true | yes | preferred (incl. patent grant) |
| ISC | true | yes | |
| MPL-2.0 | true | yes | file-level copyleft — OK if we don't modify their files |
| Unlicense, CC0-1.0 | true | yes | public-domain-equivalent |
| LGPL-2.1, LGPL-3.0 | maybe | no (needs_manual_review) | depends on linking model |
| GPL-2.0, GPL-3.0 | false | no | would force our codebase to GPL on dependency use |
| AGPL-3.0 | false | no | network-copyleft — incompatible with SaaS use |
| SSPL-1.0, BSL-1.1, Elastic-2.0 | false | no | source-available, not OSI |
| Custom / proprietary | false | no (needs_manual_review) | flag for operator |
| Missing / `unknown` / `NOASSERTION` | false | no (needs_manual_review) | default-deny |

**Operator-override.** A queue file may include `# license_override: <SPDX>` to force a specific compat verdict for that query's results — used when operator manually vets a non-standard license. Logged in the learning-event with reason field.

**Effect on note creation.** Notes are ALWAYS created (so operator has the discovery record), even for GPL/AGPL repos. Only the implementation-task proposal is suppressed.

---

## 6. Security policy (binding)

This codifies §3.5 of the brain-upgrade-plan + operator's "no execute" directive.

1. **Never clone.** All repo content access goes through the `gh` CLI / GitHub REST API. No `git clone`, no `git fetch` against discovered repos.
2. **Never execute.** No `npm install`, `pip install`, `cargo build`, `make`, `./configure`, `bash <(curl ...)`. Worker has no shell-escape path that runs repo code.
3. **Never auto-copy executable code.** README/manifests/snippets land in the brain as quoted text inside markdown. Operator must explicitly lift code into a repo (separate OK kjør).
4. **Install-script block.** Parse the manifest:
   - `package.json`: if `scripts.install`, `scripts.preinstall`, `scripts.postinstall`, or `scripts.prepare` is non-empty → `has_install_script: true`, `has_postinstall_hook: true`, `security_red_flags += ["install-hook"]`, `risk_score: max(risk_score, 0.9)`. If the hook contains `curl|wget|eval|base64 -d|node -e|python -c` → `risk_score: 1.0`.
   - `setup.py`: if it contains anything other than `setuptools.setup(...)` (e.g. arbitrary top-level imports, subprocess calls, network I/O) → `risk_score: 1.0`, `security_red_flags += ["setup-py-arbitrary-code"]`.
   - `pyproject.toml`: check `[tool.poetry.scripts]` and `[build-system].requires` for unknown build backends.
   - `Cargo.toml`: check `[package].build` (custom build script) → `security_red_flags += ["cargo-build-script"]`, `risk_score: max(risk_score, 0.7)`.
5. **CVE cross-check.** `gh api /advisories?affects=<owner>/<name>` per top-N repo. Any open advisory in last 90 days → `security_red_flags += ["recent-cve:<id>"]`, `risk_score: max(risk_score, 0.8)`.
6. **Stale-and-targeted heuristic.** If `stars > 10000` AND `commits_365d < 5` → `security_red_flags += ["abandoned-popular"]`, `risk_score: max(risk_score, 0.7)`. Rationale: abandoned popular repos are common supply-chain attack vectors.
7. **Risk-score ≥ 0.4 ⇒ no task proposal** (combined with §5 license gate).
8. **Risk-score = 1.0 ⇒ note is annotated with `## DO NOT INSTALL` banner** at top of body.

---

## 7. Scoring (LLM-driven, formulas explicit)

### 7.1 Relevance score (0.0 – 1.0)

LLM call (Haiku-tier for cost):
```
SYSTEM: Score how relevant this repo is to the operator's stated goals.
Return a JSON object {score: 0.0-1.0, reason: "..."} only.
1.0 = directly solves a stated goal.
0.7 = strong conceptual overlap, worth lifting patterns.
0.4 = adjacent, might inspire.
0.0 = unrelated.

USER:
Operator goals (from 00-DASHBOARD.md + 01-CURRENT-FOCUS.md):
<dashboard excerpt, ≤500 tokens>

Repo: <owner>/<name>
Description: <gh description>
README opening (first 800 chars):
<readme excerpt>
```

`relevance_score` = parsed `score` field. LLM reasoning persisted in learning-event for audit.

### 7.2 Activity score (0.0 – 1.0)

```
commits_30d  = gh api repos/<o>/<n>/commits?since=<30d-ago> | length
commits_365d = gh api repos/<o>/<n>/commits?since=<365d-ago> | length   (paginated, cap 1000)

expected_monthly = commits_365d / 12
if expected_monthly == 0:
    activity_score = 0.0
else:
    raw = commits_30d / expected_monthly
    activity_score = min(1.0, raw)   # clamp; bursty repos can hit 1.0 easily
```

Rationale: rewards consistent ongoing activity relative to repo's own baseline (avoids penalising mature stable libs that get steady maintenance).

### 7.3 Risk score (0.0 – 1.0)

```
risk = 0.0

# License component
if license_compatible == false:        risk += 0.4
elif license_compatible == "maybe":    risk += 0.2

# CVE component
if any open advisory in last 90d:      risk = max(risk, 0.8)

# Maintainership component
if commits_365d < 5 and stars > 10000: risk = max(risk, 0.7)
if last_commit older than 730d:        risk = max(risk, 0.6)

# Install/build script component
if has_install_script:                 risk = max(risk, 0.9)
if install hook calls network/eval:    risk = 1.0
if cargo build script present:         risk = max(risk, 0.7)
if setup.py has arbitrary code:        risk = 1.0

risk_score = min(1.0, risk)
```

### 7.4 Integration difficulty (categorical)

```
deps = count of direct deps in manifest
if deps <= 5  and primary_language ∈ {our stack}:  low
if deps <= 20 and primary_language ∈ {our stack}:  medium
else:                                              high

(Our stack = TypeScript, Python, Rust, Bash. Anything else → at least medium.)
```

### 7.5 Task-proposal gate (combined)

```
propose_task =
    relevance_score > 0.7
    AND license_compatible == true
    AND risk_score < 0.4
    AND integration_difficulty != "high"      # soft gate; can override via queue
```

---

## 8. Queue file format

Path: `13-github-repos/_queue/YYYY-MM-DDTHHMM-<slug>.md`

Minimum:
```markdown
search: agent orchestration TypeScript
```

Full form:
```markdown
search: agent orchestration TypeScript
# limit: 5                          # default 10, max 25
# topic: ai-agents                  # passed to gh search --topic
# min_stars: 100                    # default 50
# updated_since: 2025-01-01         # default 365d ago
# license_override: BUSL-1.1        # operator-vetted exception
# notes: looking for state-machine patterns à la Conductor
```

**Slug rules.** `<slug>` is `[a-z0-9-]+`, derived from first 4 words of the query. Operator may set manually.

**Lifecycle.** On successful processing, the queue file is moved to `13-github-repos/_queue/_done/<original-name>.md` with appended footer `# processed: <ISO>`, `# results: <count>`, `# task_proposals: <count>`. On failure, moved to `_failed/` with error appended.

---

## 9. Rate limiting

Tracked in the `firm_state` KV store (shared with other workers):

| Key | Default cap | Reset |
|---|---|---|
| `github_discovery:daily_search_calls` | 50 | 00:00 local |
| `github_discovery:daily_extract_calls` | 20 | 00:00 local |
| `github_discovery:last_call_at` | — | rolling 60s cooldown |
| `github_discovery:gh_api_rate_remaining` | mirrors `X-RateLimit-Remaining` | per GitHub reset window |

**Enforcement.**
- Before any `gh` invocation, worker increments the appropriate counter; if cap exceeded, queue file is re-queued for tomorrow (filename rewritten with tomorrow's date) and a learning-event is emitted with `outcome: rate-limited`.
- 60s minimum cooldown between any two `gh` calls (avoid abuse-detection signals from GitHub's API).
- If `X-RateLimit-Remaining` < 50 on any response, worker pauses until reset and re-queues remaining items.

**Configuration override.** Caps live in `packages/github-discovery/config.ts` and may be raised by operator (requires OK kjør since cost-bearing).

---

## 10. Failure modes

| Failure | Detection | Action |
|---|---|---|
| `gh` CLI not installed | `which gh` fails at worker boot | operator-alert via firm-bus + Discord; worker exits 1 |
| `gh auth status` invalid / token expired | First `gh` call returns 401 | operator-alert "check `gh auth status`"; queue items re-queued; worker exits 1 |
| Primary rate-limit (5000/hr authenticated) | `X-RateLimit-Remaining` = 0 | back off until reset, re-queue, learning-event `outcome: rate-limited` |
| Secondary rate-limit (abuse detection) | HTTP 403 with `Retry-After` header | sleep `Retry-After`, then re-queue tomorrow |
| Repo deleted between search and fetch | `gh api ... contents/...` returns 404 | skip repo, learning-event `outcome: repo-disappeared`, continue batch |
| README missing | 404 on `contents/README.md` | use `description` only for distillation; flag in note body |
| Manifest missing | 404 on all known manifest paths | `integration_difficulty: high`, `security_red_flags += ["no-manifest"]` |
| LLM call fails | API error / timeout | retry once w/ exponential backoff; if still fails, persist partial note with `status: degraded` frontmatter |
| License field is `NOASSERTION` | gh returns null spdxId | `license: unknown`, `license_compatible: false`, `needs_manual_review: true` |
| Queue file malformed | YAML/parse error | move to `_failed/` with error footer; operator-alert via inbox |

All failures emit a learning-event so BrainOrchestrator can route systemic issues to `09-retrospectives/`.

---

## 11. Implementation-task proposals

Drafted to `10-tasks/_open/T-YYYY-MM-DD-NNN-<slug>.md` ONLY when all gates pass (§7.5).

**Frontmatter:**
```yaml
---
title: "Lift <pattern> from <owner>/<name>"
id: T-YYYY-MM-DD-NNN
source: github-discovery
source_repo: https://github.com/<owner>/<name>
source_note: [[13-github-repos/<owner>-<name>]]
relevance_score: <float>
target_project: <ai-assistent | command-center | research-os | thesis | as | personlig | soking | unknown>
estimated_effort: <S | M | L>
operator_approval_required: true       # binding — task does not start without OK kjør
status: proposed
discovered: <ISO>
tags: [task, github-lift, proposed]
---
```

**Body template:**
```markdown
# Lift <pattern> from <owner>/<name>

## Why
<1-2 sentences linking to operator goal-context.>

## What to lift (conceptually)
<bulleted summary — patterns, not code>

## Where it would land in our repos
- File: <suggested path>
- Touches: <list>

## Risk + license check
- license: <SPDX>, compatible: <bool>
- risk_score: <float>
- security_red_flags: <list>

## Acceptance criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Operator decision
- [ ] OK kjør — assign to: <role>
- [ ] Defer
- [ ] Reject (reason: ___)
```

Tasks remain in `_open/` until operator moves them. Worker never starts execution.

---

## 12. Acceptance tests

Pilot the worker with three queue files. All must pass for v1.0 sign-off.

### Test A — TypeScript agent orchestration (positive case)
```markdown
search: agent orchestration TypeScript
# limit: 5
# topic: ai-agents
# min_stars: 200
```
**Expected:**
- ≥ 3 repo-notes created at `13-github-repos/<owner>-<name>.md`.
- All notes have complete frontmatter (every field in §3 populated, no nulls except `last_refreshed` on first write).
- At least one repo with MIT/Apache license has a `relevance_score > 0.7` and produces a task proposal in `10-tasks/_open/`.
- Task proposal includes `operator_approval_required: true`.

### Test B — Vector database SQLite (positive case)
```markdown
search: vector database SQLite embedding
# limit: 5
# min_stars: 100
```
**Expected:**
- ≥ 3 repo-notes created.
- At least one note cross-links conceptually to `[[MEMORY_DISTILLATION_SPEC]]` or Module G of the upgrade plan (LLM should pick this up from `01-CURRENT-FOCUS.md`).
- Rate-limit counters incremented correctly (visible in `firm_state` KV).

### Test C — Obsidian plugin TypeScript with GPL-block case
```markdown
search: Obsidian plugin TypeScript
# limit: 8
```
**Expected:**
- ≥ 3 repo-notes created.
- At least one GPL-3.0 or AGPL-3.0 licensed repo present in result set.
- For that GPL repo:
  - Note is created (discovery preserved).
  - `license_compatible: false` in frontmatter.
  - Body section "Suggested tasks for our repos" says `None (gated out — see frontmatter).`
  - NO file appears in `10-tasks/_open/` referencing that repo.
- Verifies the license-gate + security-policy enforcement end-to-end.

### Test D — Cross-cutting verification
- Run `tsc --noEmit` clean across `packages/github-discovery/`.
- Run worker 5× over the same queue (idempotency): notes are updated in place, operator-notes section preserved, `last_refreshed` bumped.
- Inject a malformed queue file: confirm it moves to `_failed/` with error footer and operator-alert posted to firm-bus.

---

## 13. Code skeleton

```
packages/github-discovery/
  package.json
  tsconfig.json
  src/
    index.ts                   # worker entrypoint (consumed by BrainOrchestrator)
    config.ts                  # rate-limit caps, license table, paths
    queue.ts                   # read/parse/move queue files (_queue → _done | _failed)
    gh.ts                      # thin wrapper around `gh` CLI (exec, JSON parse,
                               # rate-limit header tracking, 60s cooldown)
    search.ts                  # gh search repos --topic ... (paginated)
    extract.ts                 # gh repo view + README + manifest fetch (NO clone)
    license.ts                 # SPDX → policy table lookup + override handling
    risk.ts                    # install-script parse, CVE check, maintainership
    score.ts                   # relevance (LLM) + activity (formula) + risk
    distill.ts                 # LLM → markdown body + frontmatter writer
    task-proposal.ts           # gated draft to 10-tasks/_open/
    state.ts                   # firm_state KV access (daily caps, cooldown)
    learning.ts                # emit learning-event to BrainOrchestrator
    types.ts                   # RepoMeta, Manifest, Scores, etc.
  test/
    fixtures/
      repo-mit.json
      repo-gpl.json
      repo-postinstall.json
      readme-sample.md
      package-with-postinstall.json
    search.test.ts
    license.test.ts            # incl. GPL-block + LGPL-maybe + unknown-deny
    risk.test.ts               # incl. postinstall → risk 1.0
    score.test.ts
    distill.test.ts            # frontmatter shape
    queue.test.ts
    integration.test.ts        # full pipeline w/ mocked gh CLI
  README.md                    # English, per §3.7 of upgrade plan
```

**Dependencies (minimal).**
- `execa` — `gh` subprocess
- `gray-matter` — frontmatter parse/serialise
- `zod` — schema validation for parsed `gh` JSON
- `@anthropic-ai/sdk` — LLM calls (Haiku for relevance/distill)
- Internal: `@cc/brain-orchestrator`, `@cc/firm-state`

**No transitive risk surface.** Worker has no `child_process.exec` paths other than `gh` and `git log` (local only, never against discovered repos). Network egress is GitHub API + Anthropic API only.

---

## 14. Cross-refs

- [[2026-05-25-brain-upgrade-plan]] — Module F (§2.F), security directive (§3.5), verify policy (§11)
- [[MEMORY_DISTILLATION_SPEC]] — distillation pattern reused for repo-note body
- [[AGENT_ORCHESTRATION_SPEC]] — how `agent_tasks` rows are produced/consumed
- [[OBSIDIAN_BRAIN_STRUCTURE]] — folder taxonomy (`13-github-repos/`, `10-tasks/_open/`, `_queue/`)
- Cross-module e2e integration suite (planned per INTEGRATION_NOTES v1.1 H.2) — at `command-center/packages/brain-orchestrator/tests/integration/`. End-to-end assertion: operator drops a search query → discovery worker fires → repo-note lands → license/risk gates respected → optional task-proposal appears in `10-tasks/_open/`. The §12 Test A/B/C/D matrix is the per-module unit; the cross-module suite chains it with MEMORY + AGENT.

---

## 15. 5× verification (per upgrade-plan §11)

1. **Security policy explicit + enforceable** — §6 enumerates 8 rules, each with detection mechanism and code-level enforcement point (manifest parser, CVE API call, risk-score floor). No "should" without a "how".
2. **License taxonomy complete** — §5 table covers MIT / BSD / Apache / ISC / MPL / LGPL / GPL / AGPL / SSPL / BSL / Elastic / Custom / Unknown. Default-deny for unknown.
3. **Scoring formulas concrete (numeric)** — §7 gives explicit formulas with clamping for relevance, activity, risk; categorical bins for integration_difficulty; combined gate for task-proposal.
4. **Frontmatter complete** — §3 lists 20 fields with provenance for each; §11 lists 9 task-frontmatter fields. All YAML keys English (per §3.7 of upgrade plan).
5. **Acceptance tests cover GPL-block case** — §12 Test C explicitly verifies GPL repo gets a note but no task; combined with Test D for idempotency + malformed-queue handling.

---

*End of spec — v1.0 draft, 2026-05-25; v1.0.1 B-2 MEDIUM pass by C-agent.*

## Changelog
- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 MEDIUM fixes:
  - H.2: §14 cross-refs gained a pointer to the planned cross-module e2e integration suite (`command-center/packages/brain-orchestrator/tests/integration/`) so the spec is wired into the workspace-wide acceptance loop alongside MEMORY/RAG/AGENT.
