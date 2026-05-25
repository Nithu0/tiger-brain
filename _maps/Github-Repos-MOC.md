---
title: Github-Repos-MOC
type: moc
created: 2026-05-25
purpose: Index of the 13-github-repos/ folder + search-query discovery pipeline (gh-search + score + license + distill)
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, github, discovery, license, security, brain-upgrade]
---

# Github-Repos-MOC

Curated index of `13-github-repos/` and its discovery pipeline per [[GITHUB_DISCOVERY_SPEC]] (Module F in [[2026-05-25-brain-upgrade-plan]]). **Operator flow**: drop a `search:<query>` file in the queue → BrainOrchestrator picks up → `gh search` runs → repos scored (relevance + activity + risk + integration difficulty) → license + security policies enforced → top-N distilled into `13-github-repos/<owner>-<name>.md` notes. **Read-only by design** — the pipeline never clones, never executes, never installs. This MOC points only — binding truth lives in the spec.

## Spec

- [[GITHUB_DISCOVERY_SPEC]] **v1.0.1** (post-fase-3 folder-rename sweep, was `07-github-repos/`) — pipeline architecture, frontmatter contract, license policy, security policy, scoring formulas, queue file format.

## Folder

- [[13-github-repos/README]] — folder conventions, `_queue/` lifecycle, naming (`<owner>-<name>.md`), references the forthcoming [[LICENSE_GUARD_SPEC]] stub for the SPDX enforcement detail.

## Skill

- [[github-discover]] — brain-tier skill that wraps the pipeline. Accepts a manual query string (operator-invoked) **or** drains pending items in `13-github-repos/_queue/` (orchestrator-invoked). Trigger keywords: "find repos", "gh search", "scout github".

## Queue mechanism

Per [[GITHUB_DISCOVERY_SPEC]] §8 (queue file format) + [[13-github-repos/README]]:

1. Operator (or any agent) drops a file in `13-github-repos/_queue/` whose content starts with `search:` followed by a `gh search`-compatible query (e.g. `search:language:rust topic:trading stars:>100`).
2. BrainOrchestrator (per [[AGENT_ORCHESTRATION_SPEC]] §8.1) polls the queue; non-empty triggers `github-discover --drain`.
3. Each query expands into N results; results are scored (§7) and filtered (§5 license, §6 security); top-K survive into notes. Processed queue files move to `_queue/_processed/<date>/`.

## License policy (hardcoded)

Per [[GITHUB_DISCOVERY_SPEC]] §5 — SPDX-identifier-based, no LLM judgement:

- **Pass** — MIT, Apache-2.0, MPL-2.0, BSD-2/3-Clause, ISC, Unlicense, CC0-1.0.
- **Block** — GPL-2.0, GPL-3.0, AGPL-3.0, SSPL-1.0, BUSL-1.1, proprietary, unlicensed.
- **Operator-override** — explicit override flag required to write a note for a blocked-license repo (audit-logged).

Forthcoming detail spec: [[LICENSE_GUARD_SPEC]] (stub — referenced from [[13-github-repos/README]] §62).

## Security policy (binding)

Per [[GITHUB_DISCOVERY_SPEC]] §6 — **NEVER clone + execute**. The pipeline:

- Reads repo metadata via `gh api` (no clone).
- Reads README + LICENSE + top-level package manifest via `gh api` content endpoints (no checkout).
- Computes scores from metadata only — no sandboxed execution, no install, no test-run.
- Writes a note with `back_ref` to the repo URL; cloning/installing is a separate, operator-gated action.

## Scoring (LLM-driven, formulas explicit)

Per [[GITHUB_DISCOVERY_SPEC]] §7:

- **Relevance** 0.0–1.0 — §7.1 — semantic match of README vs. operator's query intent.
- **Activity** 0.0–1.0 — §7.2 — recent commit cadence, issue resolution, release frequency.
- **Risk** 0.0–1.0 — §7.3 — supply-chain signals (transitive deps, maintainer count, security advisories).
- **Integration difficulty** — §7.4 — categorical (easy / medium / hard / fork-required).
- **Task-proposal gate** — §7.5 — combined score above threshold can propose a task into `10-tasks/_open/`.

## Frontmatter

Note frontmatter contract — [[GITHUB_DISCOVERY_SPEC]] §3 (`13-github-repos/<owner>-<name>.md`). Body sections — §4 (Summary / Useful patterns to copy / Dependencies + integration cost / Install risk assessment / Suggested tasks / Source refs). Template at [[00-templates/github-repo-note]].

## Related

- [[2026-05-25-brain-upgrade-plan]] §2.F — Module F (GitHub) within the upgrade graph.
- [[00-templates/github-repo-note]] — frontmatter + section template.
- [[AGENT_ORCHESTRATION_SPEC]] §8.1 — poll cadence that drains the queue.
- [[Memory-MOC]] — discovery events emit one verbatim row (raw repo metadata) + one distilled MemoryObject per repo note.
- [[RAG-MOC]] — distilled repo notes become retrieval substrate for T2 hybrid queries (e.g. "have we already seen a Rust trading lib?").
- [[Secrets-Policy]] — relevant because `gh api` runs with operator's GitHub token; pipeline must never echo headers / dump credentials.
- [[Skills-MOC]] — the `github-discover` brain-tier skill is the operator-facing wrapper around this pipeline.
- [[System-Architecture-MOC]] — parent context.
- [[Tasks-MOC]] — `task-proposal gate` (§7.5) writes candidate tasks into `10-tasks/_open/` when combined score crosses threshold.
- [[Youtube-MOC]] — sibling discovery pipeline; shares the queue-drain pattern, scoring philosophy, and per-ingest distillation trigger.

## Open questions

- **Stub** — [[LICENSE_GUARD_SPEC]] standalone spec for the SPDX matcher (currently inline in §5; promotion candidate per [[13-github-repos/README]] §62).
- **Stub** — rate-limit budget for `gh search` (per §9) — current limit is GitHub default; needs operator sign-off when batch sizes grow.
- **Stub** — fork-required heuristic in §7.4 — currently LLM-judged; consider hardcoding (`stars < 10 AND last_commit > 365d` → fork-required).
- **Stub** — re-discovery cadence: should the orchestrator re-run a query monthly to detect new top-N candidates, or are queries one-shot? Defaults to one-shot per [[Operator-Principles]].

---

*Spec is binding truth. This MOC is a navigation aid; folder conventions live in the README, scoring formulas in the spec.*
