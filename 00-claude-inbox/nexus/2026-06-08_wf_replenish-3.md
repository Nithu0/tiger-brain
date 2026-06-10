# WF lane replenish-3 — Reddit ingestion backfill/repair

Date: 2026-06-08
Branch: `feat/wf-replenish-3-reddit-oauth` (commit `c01e66f`)
Verdict: ROOT-CAUSED + FIX BUILT (default-OFF, behaviour-neutral). Activation gated on operator.

## Task
Backfill reddit_posts ingestion — dead since 2026-05-27, foundation YELLOW blocking
new-strategy activation. Ops, not strategy.

## Root cause (confirmed live)
Reddit's anonymous `www.reddit.com/*.json` endpoint returns **persistent HTTP 429**
from Railway's shared datacenter IP. Verified directly over 443:

```
generic UA (current code):  HTTP 429 size=0
no UA:                       HTTP 429 size=0
descriptive UA:              HTTP 429 size=0
```

Reddit deprecated free anonymous JSON access in 2023; datacenter/shared IPs are
rate-limited to ~0. The code swallowed it silently:

- `sentiment-sources.service.ts:fetchSubredditSentiment` did `if (!res.ok) return null`
- herald (`fact-agents.ts:runNewsIntake`) then published `reddit: []`
- `raw-data-persistence.ts:persistRedditPosts` / `persistRedditSubreddits`
  early-return on `flat.length === 0` / `reddit.length === 0`
- → zero rows in `reddit_posts`, `reddit_subreddit_snapshots`, and empty
  `sentiment_snapshots.reddit_*` since ~2026-05-27. No error anywhere.

The code path was fully wired end-to-end; nothing was broken in our code — the
upstream source went dark and we never noticed because the failure was silent.
`docs/ref/data-sources.md §6` had literally predicted this ("Legg til rate-limit
overvåking hvis vi ser 429-responses").

NOTE: could not confirm exact row-count / last-row date via DB — the read-only PG
MCP is firewalled from this network (`EHOSTUNREACH 66.33.22.236:58688`), and the
443 pull-set has no sentiment/reddit endpoint. The 429 reproduction + the silent-
swallow code path is conclusive on the mechanism; the 2026-05-27 date is from the
lane brief.

## Fix (branch `feat/wf-replenish-3-reddit-oauth`, commit c01e66f)
Two changes, both behaviour-neutral for trading, no Karri gate (pure ingestion ops):

1. **Observability (always on):** non-OK Reddit responses now `logWarn`
   (`sentiment/reddit-fetch`, with HTTP status + authed flag) and the catch block
   logs network/timeout errors, instead of silently returning null. Dead
   ingestion is now attributable and alert-able.

2. **OAuth path behind `REDDIT_OAUTH_ENABLED` (default OFF):**
   - OFF (today's state): identical behaviour — anonymous fetch, still 429.
   - ON + `REDDIT_CLIENT_ID` + `REDDIT_CLIENT_SECRET`: requests route through
     `oauth.reddit.com` (script-app client-credentials, ~100 QPM, no 429),
     restoring ingestion. In-process token cache w/ 60s expiry margin.

Files: `apps/worker/src/services/sentiment-sources.service.ts` (+113/-8),
`docs/ref/env-vars.md`, `docs/ref/data-sources.md`.

## Verification
- `packages/shared` built, worker `tsc --noEmit` clean.
- Worker test suite: **1178/1178 pass**, exit 0 (husky pre-commit tsc also green).
- Did NOT touch ADX/regime/indicator code (ai-1's lane). Did NOT touch
  strategy/risk/gate logic. No Railway flips, no push, no merge.

## Branch-hygiene note
First commit accidentally landed on `fix/wf-replenish-2-mr-adx-surface` (branch
state confusion across cwd-resetting bash calls). Corrected: reset replenish-2
back to its own HEAD `5527eb6` (lane-2 work intact, untouched) and cherry-picked
my commit onto `feat/wf-replenish-3-reddit-oauth`. Verified clean — only my 3
files on my branch; replenish-2 unaffected.

## Operator action required to actually restore ingestion (NOT done by me)
1. Create a free Reddit "script" app at https://www.reddit.com/prefs/apps
2. Railway (API/Worker): set `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`
3. Set `REDDIT_OAUTH_ENABLED=true`
4. (after merge of this branch) confirm `reddit_posts` rows resume + foundation
   YELLOW clears on the reddit dimension.

Until then ingestion stays dead — but now it logs the 429 so it's visible.

## New follow-up tasks
- After OAuth activation: verify reddit_posts row resumption on real data
  (periodic check, per the live-fix verification cadence memory).
- Consider an alert on the new `sentiment/reddit-fetch` 429 logWarn so future
  source-death is caught within a cycle, not weeks later.
- Audit OTHER silent `return null`/`catch {}` data-source swallows (news, tavily,
  fear&greed) for the same silent-death class of bug.
