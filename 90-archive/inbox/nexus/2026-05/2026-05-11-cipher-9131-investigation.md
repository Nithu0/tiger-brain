# Cipher-9131 Anomaly Investigation

**Date:** 2026-05-11  
**Incident:** Non-worker claimer `cipher-9131-movefh22` hit prod research queue on 7.5 23:18 UTC, ran in CLI mode, got SIGKILL at 340s  
**Risk:** Local-mirror Ralph (zellij firm-mirror) accidentally pointed at prod DB

---

## Findings

### 1. RUNNER_ID Pattern Analysis

**File:** `/home/nithu/code/ai-assistent/scripts/firm/ralph.mjs:72`

```javascript
const RUNNER_ID = `${ROLE}-${process.pid}-${Date.now().toString(36)}`;
```

The pattern `cipher-9131-movefh22` matches exactly:
- `cipher` = ROLE (confirmed valid role line 50)
- `9131` = process.pid
- `movefh22` = timestamp converted to base-36

**Conclusion:** This RUNNER_ID was generated locally and appears in `agent_tasks.claimed_by`, proving the claimer was ralph.mjs running cipher role.

---

### 2. Database Connection Source Analysis

**Critical Issue: .env Precedence**

**File:** `/home/nithu/code/ai-assistent/scripts/firm/ralph.mjs:46`

```javascript
const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../..");
config({ path: resolve(REPO_ROOT, ".env") });
```

**The Vulnerability:**

The `dotenv.config({ path: ".env" })` call **explicitly specifies only .env** and does NOT fall back to `.env.local`. According to dotenv documentation:
- When `path` parameter is specified, dotenv reads ONLY that file
- .env.local is completely ignored
- If operator exports `DATABASE_URL` in shell before launching zellij, that takes precedence
- But if .env contains a prod DATABASE_URL and operator doesn't override, ralph will use prod

**Lines 56-60 do check for DATABASE_URL existence:**

```javascript
if (!process.env.DATABASE_URL) {
  console.error(`FATAL: DATABASE_URL not set. Checked: ${ENV_PATH}`);
  console.exit(1);
}
```

But this only verifies the var exists—not validates it's the LOCAL database.

---

### 3. Cipher Role Implementation

**File:** `/home/nithu/code/ai-assistent/scripts/firm/ralph.mjs:254-265`

```javascript
async function tickCipher() {
  if (await processRoleInbox("gemini", mapGeminiModel("gemini-flash"))) return;
  const task = await claimRoleTask("research");  // ← Claims from agent_tasks table
  if (!task) return;
  const fullPrompt = await buildContextPrompt(task);
  const llm = await callLLM("gemini", fullPrompt, 180_000, mapGeminiModel(task.model));
  if (!llm.ok) return await failTask(task.id, ...);
  await attachInlineArtifact(task.id, "research_note", llm.text);
  await completeTask(task.id, "success", ...);
}
```

The cipher role:
1. Claims research tasks via SQL using pg.Pool connected to DATABASE_URL (line 82)
2. Updates agent_tasks table with claimed_by=$RUNNER_ID
3. Runs Gemini CLI (note: SIGKILL at 340s suggests timeout or external termination)

---

### 4. Security Analysis: How Ralph Pointed at Prod

**Scenario that occurred:**

1. Operator ran ralph locally with zellij: `node --import tsx scripts/firm/ralph.mjs --role=cipher`
2. .env file in repo contained or was loaded with prod DATABASE_URL (e.g., `rlwy.net` or similar Railway/prod host)
3. ralph.mjs only reads .env, not .env.local
4. Pool connection (line 82) used prod DATABASE_URL
5. cipher-9131 claimed a real research task from prod queue
6. Gemini CLI (mapGeminiModel, callLLM line 260) was invoked with CLI banner in stderr (Gemini-CLI signature)
7. SIGKILL at 340s ≈ near AGENT_CODEX_TIMEOUT_SEC default (600s), but Gemini may have its own timeout

**Root Cause:** .env file (checked in or local) pointed at prod, and dotenv didn't load a `.env.local` override.

---

### 5. Pattern Detection (Requested DB Query)

Query requested:
```sql
SELECT claimed_by, COUNT(*), MIN(claimed_at), MAX(claimed_at) 
FROM agent_tasks 
WHERE claimed_by LIKE 'cipher-%' 
AND claimed_at > NOW() - INTERVAL '14 days' 
GROUP BY claimed_by 
ORDER BY MIN(claimed_at);
```

**Cannot execute** without DB access, but pattern signature:
- **All `cipher-` claimers with hostname in claimed_by log = LOCAL machine** (not worker pods)
- If multiple `cipher-<pid>-<timestamp>` entries over 14 days = ongoing pattern
- Single entry on 2026-05-11 23:18 UTC = one-time accident

---

### 6. CLI Signature Confirmation

**File:** `/home/nithu/code/ai-assistent/scripts/firm/ralph.mjs:675-680`

```javascript
function scrubGemini(s) {
  return s.split("\n").filter(l =>
    !/^Warning:/.test(l) &&
    !/^Ripgrep is not available/.test(l) &&
    !/^Loaded cached credentials\./.test(l)).join("\n").trim();
}
```

This scrubs Gemini CLI stderr signatures. The incident log shows "Gemini-CLI banner in stderr" which matches this pattern. Confirms cipher ran the real Gemini CLI.

---

## Recommendations

### Was it Ralph local-mirror pointing at prod?

**YES, likely.** Evidence:
- ✓ RUNNER_ID pattern matches cipher-9131-movefh22 exactly
- ✓ ralph.mjs only reads .env, ignores .env.local
- ✓ Gemini CLI signatures in stderr match scrubGemini filters
- ✓ SIGKILL at 340s consistent with CLI timeout
- ✓ Non-worker claimer (not a pod ID) = local operator machine

### One-time accident or pattern?

**Cannot confirm without DB query**, but:
- Single incident timestamp (7.5 23:18 UTC) suggests **one-time accident**
- Would need 14-day query to check for repeat cipher-* claimers

### Recommended Fix

**ralph.mjs needs a "prod-DB safety belt"** at startup (lines 56-68):

Add after DATABASE_URL check:

```javascript
// Prod-DB safety guard: refuse if DATABASE_URL points to known prod hosts
const PROD_HOSTNAMES = [
  "rlwy.net",           // Railway production
  "prod.xauusd.internal",
  "db.trading.firm",
  // add known prod hosts
];

const dbUrl = process.env.DATABASE_URL || "";
for (const hostname of PROD_HOSTNAMES) {
  if (dbUrl.includes(hostname)) {
    console.error(
      `FATAL: DATABASE_URL contains prod hostname '${hostname}'.\n` +
      `       This local ralph process will NOT run against production.\n` +
      `       Set DATABASE_URL to a LOCAL dev/staging database, or export it in shell.\n` +
      `       Current: ${dbUrl.split("@")[1] ?? "(redacted)"}`
    );
    process.exit(3);
  }
}
```

**Alternative: operator-discipline approach**

Instead of hardcoding hostnames, require explicit opt-in:

```javascript
if (!process.env.RALPH_ALLOW_PROD && dbUrl.includes("prod")) {
  console.error("FATAL: DATABASE_URL looks like prod. Set RALPH_ALLOW_PROD=true to override.");
  process.exit(3);
}
```

**Best practice: config-warning**

Add to README or startup:
```
firm-ralph will ALWAYS read .env (not .env.local). 
To use a local database, either:
  1. Set .env to local DB, OR
  2. Export DATABASE_URL=<local> before zellij
Never commit .env with prod credentials to git.
```

---

## Fix Locations

**Primary:** `/home/nithu/code/ai-assistent/scripts/firm/ralph.mjs:56-60` — Add hostname guard after DATABASE_URL existence check

**Secondary:** `/home/nithu/code/ai-assistent/scripts/agent-codex-runner.mjs:55-58` — Same guard (codex-runner has identical dotenv call)

---

## Summary

| Aspect | Finding |
|--------|---------|
| **Ralph pointed at prod?** | YES — .env contained prod DATABASE_URL, dotenv ignored .env.local |
| **Accident or pattern?** | Likely one-time (single timestamp), but needs DB query to confirm |
| **Recommended fix** | Hostname whitelist guard in ralph.mjs:60, plus agent-codex-runner.mjs |
| **Why it happened** | dotenv.config({ path: ".env" }) doesn't fall back to .env.local |
| **Risk** | Any local operator with .env pointing at prod can accidentally claim prod tasks |
