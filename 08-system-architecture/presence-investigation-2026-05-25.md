---
title: PRESENCE.md investigation — why sparse?
date: 2026-05-25
status: v1.0
purpose: Diagnose why firm-bus PRESENCE.md doesn't get populated per spec
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
tags:
  - investigation
  - firm-bus
  - presence
---

# PRESENCE.md investigation

## Current state

- File: `/home/nithu/Obsidian/Brain/00-firm-bus/PRESENCE.md`
- Size: 639 bytes (header + table-head + zero data rows)
- Last modified: **2026-05-13 16:44:55 +0200** — unchanged for ~12 days despite many pane launches in that window
- Content (verbatim):

  ```md
  ---
  tags: [meta, firm-bus, presence]
  type: meta
  auto-updated: true
  ---

  # firm-bus presence

  Live "who's here" snapshot. Updated automatically by `firm-tab-init.sh` each
  time a firm tab boots. Append-only — every tab launch adds one row.

  To find the current state for a given role, read the LAST row that matches
  that `(user, role)` pair. Rows older than 2h should be considered stale
  (treat the role as offline). A sweeper may annotate stale rows with a
  `stale` marker in the Status column.

  Synced across machines via the Obsidian Git plugin (auto-pull every 2-5 min).

  | Time | User | Role | Project | Status |
  |---|---|---|---|---|
  ```

- For contrast: `feed.md` last modified 2026-05-25 17:01:57 (same day) and is 29 322 bytes. Many pane-start lines present.

## Expected per spec

From `~/Obsidian/Brain/00-firm-bus/README.md`:

> `PRESENCE.md` — "who's online" snapshot. **Each firm-tab boot appends a row.** Read the LAST row per `(user, role)` pair for current state; rows older than 2h are stale.

And §"Convention" line 37:

> On session start — your launcher already appended `<ISO-time> [<git-user>] <role> online in <project>` to `feed.md` and **a row to `PRESENCE.md`**.

PRESENCE.md's own header (line 9–10):

> Updated automatically by `firm-tab-init.sh` each time a firm tab boots. Append-only — every tab launch adds one row.

So three independent specs (README §Files, README §Convention, PRESENCE.md self-header) all assert: **firm-tab-init.sh appends to PRESENCE.md on every pane boot**.

## Diagnosis

### 1. Does `firm-tab-init.sh` write to PRESENCE.md? — No.

Inspected `/home/nithu/code/command-center/_bin/firm-tab-init.sh` (the canonical, version-controlled launcher, mirrored at `~/Obsidian/Brain/firm-launcher/bin/firm-tab-init.sh`). Bus-writing lines are:

```sh
bus_dir="$HOME/Obsidian/Brain/00-firm-bus"
inbox_dir="$bus_dir/inbox"
feed_file="$bus_dir/feed.md"

mkdir -p "$inbox_dir"
touch "$inbox_dir/${role}.md"

# Append online marker to the shared feed (one line, no heredoc).
printf -- '- %s %s online in %s\n' "$FIRM_TAB_OPENED_AT" "$role" "$project" >> "$feed_file"
```

There is **no `PRESENCE.md` write** anywhere in the script. Confirmed by `grep -n PRESENCE /home/nithu/code/command-center/_bin/*.sh`: only one hit, a comment in `firm-inbox-watch.sh` (and `firm-launcher/bin/firm-inbox-watch.sh`) saying it *must not* touch PRESENCE.md.

While at it, the same `printf` shows the feed-write also doesn't include `[<git-user>]` — so feed format is likewise out of sync with README §Convention. Out of scope for this investigation; flagging.

### 2. Does any other firm-* script write to PRESENCE.md? — No.

Grepped all of `_bin/` and `~/Obsidian/Brain/firm-launcher/bin/`. The only `PRESENCE` reference is the "never touch" comment in `firm-inbox-watch.sh`. None of `firm-wt-split.sh`, `firm-wt-tabs.sh`, `firm-zellij.sh`, `firm-heartbeat.sh`, `firm-session-context.sh`, `firm-statusline.sh`, `firm-git-snapshot.sh`, `firm-worktree-*.sh`, `firm-task-claim.sh`, `firm-task-complete.sh`, or `brain-preflight.sh` writes a row.

Note: `firm-heartbeat.sh` *does* exist and produces per-pane status (intended for `~/Obsidian/Brain/00-firm-bus/pane-status/<role>.{json,md}`), but `pane-status/` contains only `.gitkeep` (May 14) — heartbeat is not wired into the launcher either. Different mechanism, also dormant; separate problem.

### 3. Does command-center write PRESENCE.md? — No, and it must not.

`grep -rn PRESENCE /home/nithu/code/command-center/` confirms every reference is read-side:

- `packages/bus/src/presence.ts` — `readPresenceTable()` + `presencePathOf()`; pure reader, no `writeFile`.
- `apps/api/src/routes/terminals.ts` (lines 26–33) and `apps/api/src/routes/orchestrator.ts` (lines 60–74) — read PRESENCE.md, **fall back to `derivePresenceFromFeed()`** when the table has zero rows.
- `apps/api/src/ws.ts` — chokidar watcher fires `presence` events on PRESENCE.md *changes* (read-side notifier).
- `apps/api/INTEGRATION_NOTES_realtime.md:147` — web client subscribes to `["presence", "feed"]` because "presence falls back to feed when PRESENCE.md is empty".
- `docs/ADR-001-architecture.md:42` — explicit binding: "**`feed.md` and `PRESENCE.md` — read-only observation.** Command-center only reads these." The sole sanctioned `feed.md` write is the Slice 11 inbox-watcher receipt. **No** `PRESENCE.md` write is sanctioned.
- `command-center/CLAUDE.md` Boundary #1 repeats the same: PRESENCE.md is read-only observation from CC.

So PRESENCE.md write is firmly the pane-side launcher's responsibility, per architecture.

### 4. feed.md vs PRESENCE.md write pattern

The spec says **both** writes should fire on pane boot. In reality only the feed write happens. This is consistent across:

- All pane launches since 2026-05-13 (feed.md timestamp moves; PRESENCE.md timestamp doesn't).
- Both operator and Karri sides (PRESENCE.md table has 0 rows total; if Karri ran it on his side the obsidian-git push would land a row here within the 5min sync window).
- The brain-upgrade-plan inventory `~/Obsidian/Brain/08-system-architecture/2026-05-25-brain-upgrade-plan.md:178` already independently noted: "PRESENCE.md: sparse (mekanikken populerer ikke per pane-start)".

So the gap is reproducible, persistent, and known.

### 5. Web/API behaviour confirms the read-side gracefully degrades

`/api/terminals/presence` checks the table, finds 0 rows, falls back to `derivePresenceFromFeed()` and returns `{ source: "feed-derived" }`. The web client subscribes to `["presence", "feed"]` for the same reason. So **no user-visible breakage** today — the dashboard works fine off feed.md. PRESENCE.md is purely vestigial in the current data flow.

## Root cause

**Missing implementation.** The PRESENCE.md write was specified (in README §Files line 22, README §Convention line 37, and PRESENCE.md's own header line 9), but `firm-tab-init.sh` was only ever wired to write `feed.md` + `touch` the inbox. The `feed-derived` fallback in `packages/bus` and `routes/terminals.ts` was added later to keep the dashboard working when PRESENCE.md was empty — which masked the gap and removed pressure to wire the launcher.

Bonus finding: the `[<git-user>]` prefix in feed entries (README §Files line 20) and `FIRM_USER_TAG` env var (README §Layout para 3) are also unimplemented in `firm-tab-init.sh`. Same class of spec-vs-impl drift.

This is not a runtime bug or race condition — `firm-tab-init.sh` runs to completion successfully every launch; it just doesn't have the relevant `printf >> PRESENCE.md` line.

## Proposed fix

### Option A: Pane-side write (matches spec; minimal change)

Add ~5 lines to `firm-tab-init.sh` after the existing `feed_file` append:

```bash
presence_file="$bus_dir/PRESENCE.md"
user_tag="$(git config --global user.name 2>/dev/null | tr -d ' ' || echo unknown)"
printf -- '| %s | %s | %s | %s | online |\n' \
  "$FIRM_TAB_OPENED_AT" "$user_tag" "$role" "$project" >> "$presence_file"
```

Pros: matches the spec exactly (each pane boot appends a row); zero new components; no server-side write to PRESENCE.md (still respects ADR-001 — the launcher is *not* command-center). Resolves `[<git-user>]` gap simultaneously if `$user_tag` is also threaded into the feed line.

Cons: requires re-launching panes for new rows; assumes the launcher is the only writer (which is the existing spec anyway).

Risk: low. Append-only. Worst case PRESENCE.md grows a row per boot, exactly as documented. Stale rows already get the "older than 2h" handling in `packages/bus/src/presence.ts:classify`.

### Option B: Server-side aggregation in command-center

Have `apps/api` (e.g. an executor-worker tick or a new ws-side hook) periodically rewrite PRESENCE.md from feed-derived presence.

Pros: works without re-launching panes; covers panes launched outside the firm-launcher.

Cons: **violates ADR-001 boundary #1** and `command-center/CLAUDE.md` boundary #1 ("`PRESENCE.md` is read-only observation; command-center only reads these"). Would also conflict with append-only semantics in README §Anti-patterns line 52 ("Don't edit old `PRESENCE.md` rows. Append-only."). Operator-gated boundary change required.

### Option C: Cron-driven scan

A systemd/cron job runs `feed-derive → append-rows-to-PRESENCE`.

Pros: decouples from launcher.

Cons: adds a new process to maintain; still effectively a write-from-derived loop with stale-detection complexity; same boundary question as Option B if anything other than the pane writes the file. Heaviest option.

## Recommendation

**Option A.** Smallest patch, matches three independent specs, zero boundary violations, low risk. The `feed-derived` fallback can stay in place as belt-and-braces (and continues to cover ad-hoc shells launched without `firm`).

While editing the launcher, also fix the `[<git-user>]` tag drift in the feed write (one extra `$user_tag` interpolation) — same root cause, one PR.

## Operator decision needed?

**Yes, light gate.** Trivial edit, but it's the firm-bus protocol surface — operator should ACK before landing because (a) the user-tag scheme will produce new feed.md format and Karri's tooling may parse the old format, and (b) Option A vs B is genuinely architectural (we're choosing pane-side over server-side; reaffirming ADR-001). Suggested message: "OK kjør firm-tab-init.sh PRESENCE write + user-tag" — then implement Option A in `_bin/firm-tab-init.sh` and ship.
