# Claude Code Effectiveness Playbook
Created 2026-06-23 · research drop (code-2 lane) · firm-wide
Scope: 8-pane firm, code-1/code-2 lanes, firm-bus, memory.db brain, vast-job dispatch.

The one constraint behind almost everything: Claude's context window fills fast and
performance degrades as it fills. Most tips below are downstream of "protect context."

## TOP 10 NEW tips to adopt (ranked by firm impact)
1. **Adversarial review subagent on the diff before "done"** — fresh context, sees only diff + criteria. Formalize `/code-review` per lane. Tell it to flag only correctness/requirement gaps (or it over-engineers). Enforces our binding "verify before declaring done". (high)
2. **Stop hooks as a deterministic done-gate** — CLAUDE.md is advisory; a Stop hook runs typecheck/build/test as a script and blocks turn-end until it passes. Makes unattended panes finish *correctly*. (high)
3. **`/clear` between unrelated tasks — default, not last resort.** Kitchen-sink session = #1 failure mode. After 2 failed corrections, `/clear` + rewrite the prompt. (high)
4. **Subagents for investigation to protect main context** — research reads many files; offload it, get a summary back, keep the implementation window clean. (high)
5. **`/init` then prune CLAUDE.md with the deletion test** — "would removing this line cause a mistake?" If no, cut. Bloated CLAUDE.md makes Claude IGNORE rules. (high)
6. **Skills vs CLAUDE.md: load-on-demand beats always-loaded** — situational/domain workflows → `.claude/skills/*/SKILL.md`, not CLAUDE.md. Shrinks always-on token cost. (high)
7. **"Let Claude interview you" → SPEC.md → fresh session to implement** (AskUserQuestion-driven) for genuinely novel features. (medium)
8. **`/rewind` + checkpoints** — every prompt is a checkpoint; take risky shots, rewind if they fail, instead of over-planning. NOT a git replacement. (medium)
9. **Match subagent count to task breadth** — simple=1, comparison=2-4, complex=10+. Multi-agent ≈ 15× chat token cost; our "5-10 default" is sometimes overkill (tune for vast-job economics). (medium)
10. **Worker output → artifacts (files/inbox), not through the lead's context** — make `00-claude-inbox/` the rule for all fan-out; lead reads summaries only. (medium)

## Already do (don't re-adopt)
Parallel sessions / worktrees · 3-level memory hierarchy + memory.db · firm-bus (= "agent teams") · CLI-over-MCP habit · verification-before-done (binding) · custom subagents + skills.

---

## 1. Context management
- `/clear` between unrelated tasks (default). After 2 failed corrections → `/clear` + rewrite. (high)
- Subagents for investigation/research → returns summary, saves main context. (high)
- `/compact <instructions>` (e.g. "preserve modified-files + test commands"); `/btw` for side-questions that never enter history. (medium)
- Track context with a status line (we have statusLine wiring). (medium)

## 2. CLAUDE.md / project memory
- `/init` → prune with deletion test. Keep short + human-readable. (high)
- Include: non-guessable bash cmds, non-default style, test runner, branch/PR etiquette, env quirks. Exclude: anything inferable from code, fast-changing info, file-by-file descriptions. (high)
- Hierarchy: `~/.claude/CLAUDE.md` → project `./CLAUDE.md` → `./CLAUDE.local.md`; `@path` imports. (already-do)
- Situational/domain → SKILLS not CLAUDE.md (skills load on demand). Migrate reference/history out. (high, NEW)
- `#` mid-session writes a correction back to CLAUDE.md. (medium)

## 3. Subagents & parallelism
- Count to breadth: simple=1, comparison=2-4, complex=10+. Multi-agent ~15× tokens; token usage ≈ 80% of perf variance. (medium, NEW)
- Orchestrator gives each worker explicit objective + output format + tool guidance + scope boundary (vague delegation → duplicated work). (high)
- Worker output → artifacts, not funnelled through lead. (medium, NEW)
- Parallelism wins breadth-first/low-interdependency; hurts when all share context. Most single coding tasks aren't parallelizable. (high)

## 4. Multi-agent orchestration (firm-bus analog)
- Agent teams = multi-session + shared tasks + lead. firm-bus = our version. (already-do)
- Writer/Reviewer: Session A implements, Session B reviews in fresh context. code-1 writes / code-2 reviews. (high, NEW framing)
- Resume-from-checkpoint over full restart; evaluate state-mutating agents on end-state. (medium)

## 5. MCP & tools
- CLI tools are the most context-efficient interface (install gh/aws/gcloud). Teach unknown CLIs via `--help`. (high)
- `claude mcp add`; check an MCP JSON into the repo for team auto-provision. (medium)
- Tool descriptions matter as much as the tools (one team: +40% completion time from better docs). (medium)

## 6. Planning / spec-first
- Explore → Plan → Confirm → Code → Commit for non-trivial; skip plan if diff fits one sentence. (high)
- Interview → SPEC.md (names files/interfaces, states out-of-scope, ends with e2e check) → fresh session. (high, NEW)

## 7. Verification / TDD
- Always give Claude a check it can run (tests/build exit/linter/screenshot). (high)
- Gate the stop hardest-first: in-prompt iterate → `/goal` (re-checked each turn) → Stop hook → second-opinion subagent. (high)
- Adversarial review subagent on diff vs PLAN.md before "done"; flag only correctness gaps. (high, NEW)
- Show evidence (test output/command result/screenshot), not just assert. Address root causes, not symptoms. (high)
- TDD: tests → commit → code → iterate → commit. UI: code → screenshot → iterate. (medium)

## 8. Cost control
- Token usage ≈ 80% of perf variance; agents ~4× chat, multi-agent ~15×. Spend on high-value parallelizable work. (high)
- A model upgrade beat doubling token budget — optimize efficiency before scaling agent count. (medium)
- Single tests over full suite (put in CLAUDE.md). `/clear` = cost control. Route non-PII heavy compute to vast GPU; never PII/memory.db on rented GPU. (already-do)

## 9. Permissions / safety
- Cut prompt fatigue: auto mode (classifier blocks only risky), `/permissions` allowlists, `/sandbox`. `--allowedTools` to scope unattended runs. (high)
- FIRM OVERRIDE: operator-gated actions (push, trades, migrations, deletes) stay manual regardless — do NOT auto-allowlist those. (binding)

## 10. Prompt patterns
- Be specific (file, scenario, test prefs, "fixed" state). Point to sources + existing patterns to follow. (high)
- Codebase Q&A is the best onboarding accelerant. "think hard" for edge-case reasoning. Start wide then narrow. (high/medium)
- Rich input: `@file`, images, URLs (allowlist domains), `cat x | claude`. (medium)

## 11. Session mechanics
- Esc = stop (context kept). `/rewind` = restore code/convo/both (not a git replacement). `--continue`/`--resume`, `/rename`. (medium)
- Headless: `claude -p "..." --output-format json|stream-json` for CI/hooks. Fan-out: file list → loop `claude -p` per file with scoped `--allowedTools` → test on 3, then scale. (medium)

## Named failure patterns
Kitchen-sink session → `/clear`. Correct-over-and-over → `/clear` + better prompt. Over-specified CLAUDE.md → prune + convert hard rules to hooks. Trust-then-verify gap → always provide a check. Infinite exploration → scope it / use subagents.

## Sources & honesty
- Official: [Claude Code best practices](https://code.claude.com/docs/en/best-practices) + [multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system) — full primary text, highest confidence.
- Boris Cherny "Mastering Claude Code in 30 min" (https://www.youtube.com/watch?v=6eBSHbLKuN0): **UPDATE 2026-06-23 — real verbatim transcript now pulled** (12-youtube/transcripts/6eBSHbLKuN0.md, 5556 words). The summary-derived tips above were substantially correct; specific corrections + additions are in the verified section below.
- Verbatim transcripts now also pulled for: SDK workshop (TqC1qOfiVcQ, Thariq Shihipar), agentic-coding interview (iF9iV4xponk, Boris), Agent Teams demo (-1K_ZWDKpU0).
- ~60-line CLAUDE.md figure is a community rule of thumb; official guidance is the deletion test, not a number. Boris (verbatim) only says "try to keep it as short as you can" — confirms no official number.

---

## Video-tips (verifisert mot ekte transkript 2026-06-23)
Extracted from the four full verbatim WORKSPACE transcripts. Tips here are NEW vs the summary-built playbook above, or they CORRECT it. Format: tip — WHY — [video] — confidence.

### Corrections to the playbook above
- **Multi-agent token multiplier: TWO different numbers, don't conflate them.** Old tips #9/§3/§8 cite "~15× chat". That 15× is the Anthropic *research-system* blog figure. The **Agent Teams** feature is **~2–4× tokens** vs solo CC (shared task-list + lead↔agent chatter). — use 2–4× for the agent-teams/firm-bus analog, 15× only for the deep research-orchestrator pattern — [-1K_ZWDKpU0] — high.
- **A subagent IS "a slash command with a forked context window"** (Boris's own framing). The playbook treats subagents and slash commands as separate tools; per the verbatim they're "two sides of the same thing" — a slash command reuses your main context, an agent forks it. Mental model fix, not a behavior change. — [iF9iV4xponk] — high.
- **Codebase-Q&A onboarding number is concrete: 2–3 weeks → 2–3 days** at Anthropic (playbook §10 had the tip but no magnitude). Also: ~80% of technical staff use CC daily. — strengthens "Q&A is the best onboarding accelerant" — [6eBSHbLKuN0] — high.
- **CLAUDE.md "keep it short": no official line count, verbatim confirms.** Boris only says "try to keep it as short as you can ... if it gets too long it's just going to use up context and it's usually not that useful." The ~60-line figure stays a community heuristic. — [6eBSHbLKuN0] — high.

### NEW — context engineering (the SDK workshop is the goldmine here)
- **Save long tool-call output to a file, return the PATH not the bytes.** Keeps context from exploding; agent can grep across results and re-check its own work against the file. This is the single highest-leverage SDK pattern. Maps directly to our `00-claude-inbox/` artifact rule — formalize it for tool output too, not just worker summaries. — [TqC1qOfiVcQ] — high.
- **Keep state in the environment (files/git/sheet), not the context window — then CLEAR often instead of compacting.** Thariq "almost never compacts; I clear very often" then points CC at the git diff. Works because in code the state lives in the files. Sharpens our `/clear`-by-default tip with the *why*. — [TqC1qOfiVcQ] — high (his stated personal practice).
- **Bash is the most powerful agent tool — composable (grep/tail/pipe/gen-and-run-scripts), reuses existing software.** Reserve real "tools" only for atomic/irreversible/approval-needed actions (write-file so user can approve, send-email). Reframes our CLI-over-MCP habit: it's not just context-efficiency, it's composability. — [TqC1qOfiVcQ] — high.
- **`--help` on every CLI/script = progressive disclosure.** Agent self-discovers subcommands on demand instead of you front-loading them into context. We already say "teach CLIs via --help"; the verbatim adds the design directive: *build your own scripts with --help*. — [TqC1qOfiVcQ] — high.
- **Skills = folders the agent CDs into = progressive context disclosure.** SKILL.md is read only when the agent decides it needs that procedure. Confirms playbook §2's "skills load on demand" and gives the mechanism (file-system as context-engineering surface). — [TqC1qOfiVcQ] — high.
- **`!` bash-mode output enters the context window** (command + result), so Claude sees it next turn; and **Ctrl-R shows the full output Claude actually sees.** Neither is in the playbook's session-mechanics §11. Useful for getting a long command's result into context deliberately. — [6eBSHbLKuN0] — high.

### NEW — verification (this is where the transcripts most exceed the summaries)
- **Verify EVERYWHERE, not just at the end; prefer rule-based/deterministic checks over LLM-judge.** "First step is what can you do deterministically?" Insert checks at every loop step that has a rule. Our Stop-hook gate is the end-of-turn case; the verbatim says push checks earlier too. — [TqC1qOfiVcQ] — high.
- **Read-before-write guardrail: error out when the agent writes a file it hasn't read** ("you haven't read this file yet, try reading it first"). Concrete deterministic guardrail we could add as a hook for unattended panes. — [TqC1qOfiVcQ] — high.
- **Only build an agent for tasks whose output you can VERIFY; reversibility is a key intuition.** Code = great (lint/compile/git-undo). Add checkpoints where state isn't naturally reversible. Sharpens "always give Claude a check it can run" into a go/no-go test for whether to automate at all. — [TqC1qOfiVcQ] — high.
- **Adversarial review subagent: start a FRESH context, do NOT fork the main one, and role-prompt it harshly** ("this output was made by a junior analyst, critique it"). Playbook tip #1 says "fresh context" but the verbatim adds the don't-fork rule + the adversarial role-prompt, which materially changes the critique quality. — [TqC1qOfiVcQ] — high.

### NEW — workflow / triage
- **Triage easy/medium/hard with a different workflow each:** easy = tag @Claude on a GitHub issue, let it write the PR (frees your terminal); medium = Shift+Tab into plan mode, align on plan, then auto-accept to implement; hard = you stay driving, Claude does research/prototypes/unit-tests only. This is a cleaner operating rule than our blanket "plan for non-trivial". — [iF9iV4xponk] — high.
- **shift-tab = auto-accept-edits mode (bash still gated).** Switch into it once Claude is clearly on the right track (e.g. iterating on tests) so you stop OK-ing every edit; you can always ask it to undo later. Not in playbook's §11. — [6eBSHbLKuN0] — high.
- **A slash command should embed your standards AND pre-allow the bash cmd it needs** (Boris's `/commit`: instructions + pre-allowed `git commit` so it runs without a prompt). FIRM OVERRIDE still applies — never pre-allow operator-gated cmds (push/trade/migrate/delete). — [iF9iV4xponk] — high.
- **Give Claude a feedback loop and let it iterate 2–3×** (unit tests / Puppeteer screenshot / iOS-sim screenshot): "build this UI → gets it pretty good; iterate 2–3× → almost perfect." Confirms §7's UI loop with the concrete iteration count. — [6eBSHbLKuN0] — high.

### NEW — agent teams (firm-bus analog) — the -1K_ZWDKpU0 video
- **Decision rule: subagents for RESEARCH, agent teams for IMPLEMENTATION.** Subagents are context-isolated/token-cheap (you get only a summary). Implementation needs coordination so agents don't build against each other's wrong assumptions. Maps onto our firm-bus: fan-out research via subagents, coordinate builds via firm-bus. — [-1K_ZWDKpU0] — high.
- **Contract-first spawning: have the upstream agent emit its CONTRACT (e.g. DB schema) before downstream agents start — don't fire all in parallel.** Downstream (backend) building against an unfinalized schema wastes tokens redoing work. Upstream only needs to *publish the contract*, not finish. Directly improves our collision-prevention/lane rules. — [-1K_ZWDKpU0] — high.
- **The agent-teams feature isn't good unaided — author a skill to encode team-spawning conventions** (his `/build-with-agent-team` takes a plan path + agent count, or lets CC size the team). We already use firm-launcher scripts; if we adopt native agent-teams, wrap it in a skill, don't prompt it raw. — [-1K_ZWDKpU0] — high.

### NEW — building/operating agents (SDK, lower firm-priority but durable)
- **Read agent-run transcripts over and over — it's THE core skill for improving a loop.** "Why is it doing this, can I help it?" Log every tool call / assistant message while prototyping. We have session transcripts under ~/.claude/projects — this is an under-used debugging asset. — [TqC1qOfiVcQ] — high.
- **Prototype the whole agent in Claude Code first, then port the working recipe to the SDK (final agent file ≈ 50 lines).** Skips straight to the hard domain problems. — [TqC1qOfiVcQ] — high.
- **Rewrite agent code ~every 6 months; treat code as non-precious.** "Write code 10× faster → throw it out 10× faster." Models move fast enough that baked-in assumptions go stale — relevant to our brain-engine packages. — [TqC1qOfiVcQ] + [iF9iV4xponk] — high.
- **Make the problem in-distribution: translate data into formats the model knows (SQL, XML, spreadsheet ranges).** Query a CSV via SQLite instead of a bespoke reader. — [TqC1qOfiVcQ] — high.
- **Swiss-cheese security + sandbox the NETWORK specifically (lethal trifecta); scope agents with temporary/narrow API keys, host on a sandbox not your machine.** Reinforces our "never PII/memory.db on rented GPU" and operator-gated rules. — [TqC1qOfiVcQ] — high.
- **Use a `memories/` folder on the filesystem rather than waiting on a special memory tool; Bun runs TS directly (TS for generation = types, Bun to run = no compile step, lint built in).** — [TqC1qOfiVcQ] — med (tooling-specific).

### Honest notes
- Boris self-describes as a "Claude normie" — usually ONE session + a few terminal tabs; worktrees/tmux/parallel checkouts are what he sees *power users* do, and CC is "actively working on making this easier." So our 8-pane firm default is a power-user setup, not the baseline Anthropic ships — fine, but don't treat heavy parallelism as universally optimal (cost + most single coding tasks don't parallelize, per playbook §3). — [6eBSHbLKuN0] — high.
- iF9iV4xponk and -1K_ZWDKpU0 are thin on hooks/permissions/MCP/SDK specifics; nothing invented for those from those two videos.
