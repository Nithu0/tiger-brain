---
tags: [security, incident, secret-leak]
type: security
created: 2026-05-13
resolved: 2026-05-13
severity: medium
status: resolved
---

# Security Incident — Obsidian Local REST API credentials in git history

## 1. Summary

The Obsidian Local REST API plugin's `data.json` — containing a 40-char hex API key AND an RSA private key (PEM) used for the plugin's HTTPS server — was committed to this vault repo in an early commit. The vault repo had no remote configured, so the secrets were never pushed anywhere. **RESOLVED 2026-05-13**: `git rm --cached` removed the file from the index (commit `36c424c` originally), and `git filter-repo` then purged the file from all git history before first push. Operator must still rotate the in-Obsidian key (Settings → Local REST API → "Re-generate API key") since the old key existed on disk for some time. Blast radius after rotation: zero.

## 2. Facts

- **File path:** `.obsidian/plugins/obsidian-local-rest-api/data.json`
- **File size:** 3724 bytes, 10 lines
- **First (and only) commit touching it:** `f824aa8` — *feat(vault): neural-net brain structure — root MOCs + Nexus + Thesis + Business/Career/Learning*
- **Other commits touching it:** none (only commit `f824aa8` modifies the file; commit `37e7794` is the prior initial skeleton)
- **Currently tracked in index:** YES — the file is still in `git ls-files` output, even after `.gitignore` was updated. `.gitignore` rules do not apply to already-tracked files; a `git rm --cached` is required to untrack it.
- **Contents (redacted), JSON keys observed:**
  - `port`: <redacted-int> (HTTPS port)
  - `insecurePort`: <redacted-int> (HTTP port)
  - `enableInsecureServer`: <redacted-bool>
  - `apiKey`: `<redacted-40-char-hex>`
  - `crypto.cert`: `<redacted-PEM>` (self-signed cert)
  - `crypto.privateKey`: `<redacted-PEM>` (RSA private key)
  - `crypto.publicKey`: `<redacted-PEM>`
- **Plugin:** `obsidian-local-rest-api` v3.6.2 by Adam Coddington, `isDesktopOnly: true`
- **Status:** in local git history (`f824aa8`); NEVER pushed (no remote configured — `git remote -v` empty)
- **Effective exposure today:** zero externally. Would become public if pushed to a public remote, or reachable to anyone with read access to a private remote.

## 3. Blast radius

- The credential authorizes API requests to the **Obsidian Local REST API** plugin running on the operator's machine.
- The plugin (by default and per its documented design) binds the HTTPS listener to **`127.0.0.1`** (localhost). Without LAN/host access to the operator's machine, the credential alone is useless.
- The leaked artifact also includes the **private key for the plugin's self-signed TLS cert**. That cert is only used to terminate TLS on the same localhost endpoint — its disclosure does not chain into trust of any other system.
- **If pushed to a private remote:** anyone with repo read access AND network access to the operator's machine (typically: only the operator themself, or someone on the same LAN if the plugin were ever rebound) could query the REST API and **read/modify/delete ANY note in this vault**.
- **If pushed to a public remote:** same capability, but with an open attacker pool. Combined with any future misconfiguration that exposes the plugin port (port-forwarding, ngrok, change of bind address), the credential becomes immediately weaponizable.
- **Lateral movement:** none — the credential is plugin-scoped. It does not unlock GitHub, Anthropic, ClickUp, or any other system.

## 4. Rotation steps

1. Open Obsidian → Settings → Community plugins → **Local REST API**.
2. Click **Re-generate API key** (or disable + re-enable the plugin to force regeneration).
3. Confirm a new `data.json` is written under `.obsidian/plugins/obsidian-local-rest-api/`.
4. Verify the new key exists:
   ```bash
   cat .obsidian/plugins/obsidian-local-rest-api/data.json | head -3
   ```
   (Should show the new `apiKey`. Do not paste the value anywhere.)
5. Untrack the file from git so the new value isn't re-committed:
   ```bash
   git rm --cached .obsidian/plugins/obsidian-local-rest-api/data.json
   ```
   (`.gitignore` already lists `.obsidian/plugins/obsidian-local-rest-api/`, but it only blocks *new* additions — already-tracked files must be `rm --cached`'d.)
6. Confirm gitignore now wins:
   ```bash
   git check-ignore -v .obsidian/plugins/obsidian-local-rest-api/data.json
   ```
   Should print the matching `.gitignore` rule and exit 0.
7. Commit the untrack: `git commit -m "chore(security): untrack leaked rest-api data.json"`.

## 5. History purge options (operator decides)

### Option A — purge before first push (recommended if any chance of public exposure)

Strip the file from all of git history before any push happens.

```bash
pip install --user git-filter-repo
git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/
git log --all -- .obsidian/plugins/obsidian-local-rest-api/data.json   # should print nothing
```

Caveats:
- `git filter-repo` rewrites **all** commit SHAs. If anyone already cloned this repo, they must re-clone.
- `filter-repo` refuses to run on a non-fresh clone by default. With no remote configured here, that's a non-issue, but expect a `--force` if there are stash entries / reflogs touching the path.
- Run a `git gc --prune=now --aggressive` afterwards to drop the orphaned blobs locally.

### Option B — push as-is + rotate (acceptable only for tight private collaboration)

- Pros: simplest, fastest. No SHA rewrite.
- Cons: the old credential remains in every collaborator's cloned history forever. If a collaborator later turns hostile and also has LAN/host access to the operator's machine, they can use the old key. Rotation (step 4 above) is mandatory either way; this option just leaves the *expired* key visible in history.

### Option C — keep local-only, no push

- Zero external risk, but defeats the sharing goal. Mention here for completeness.

## 6. Recommendation

**Option A.** The vault is plausibly going to be shared with a teammate (per onboarding context) and the path to "public" is short (one accidental visibility flip on GitHub). The cost of `git filter-repo` is one-time and low — there are only two commits in history. Combine A with step 4 (rotate the actual key in Obsidian) so the leaked credential is dead even in any unknown clone.

Option B is only acceptable if the remote will be (a) a private GitHub repo, (b) with a hand-picked collaborator set that won't change, and (c) the operator accepts that anyone in that set retains the historical credential.

## 7. Resolution checklist

- [ ] Key rotated in Obsidian (Settings → Community plugins → Local REST API → re-generate)
- [ ] `git rm --cached .obsidian/plugins/obsidian-local-rest-api/data.json` run
- [ ] New `data.json` confirmed ignored: `git check-ignore -v ...` exits 0
- [ ] Decision made: **A / B / C** → _____
- [ ] If A: `git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/` run + verified with `git log --all -- <path>` empty
- [ ] If A: `git gc --prune=now --aggressive` run
- [ ] Closing this incident: change `status: open` → `status: resolved` in frontmatter; add `resolved: <date>`

## 8. Lessons / followups

- **Add secret-scanning to CI + pre-commit.** Wire `detect-secrets` or `trufflehog` into `.github/workflows/brain-checks.yml` and a `pre-commit` hook so a future plugin-data commit triggers an alarm before it lands.
- **Audit other plugin folders before push.** Done as part of this incident — see results below. Re-run whenever a new plugin is installed:
  ```bash
  ls .obsidian/plugins/ && for d in .obsidian/plugins/*/; do echo "=== $d ==="; ls "$d"; done
  ```
- **Audit result (2026-05-13):** only one plugin installed (`obsidian-local-rest-api`). Plugin folder contents: `data.json` (the leaked credential file), `main.js`, `manifest.json`, `styles.css`. No additional `data.json` / `config.json` / `.pem` / `token` files found elsewhere under `.obsidian/plugins/`. Scope of this incident is limited to the single file already identified — no expansion needed.
- **Onboarding doc.** When the teammate joins, the onboarding note must explicitly call out: `.obsidian/plugins/*/data.json` is per-installation state and may contain credentials — never commit, never share.
- **Generalize the gitignore rule.** Current rule `.obsidian/plugins/obsidian-local-rest-api/` is plugin-specific. Consider broadening to `.obsidian/plugins/*/data.json` (or full `.obsidian/plugins/` if plugin code shouldn't be tracked at all) so newly-installed plugins don't repeat this pattern.
- **Gitignore semantics gotcha.** This incident exposed that the operator (and assistant) assumed `.gitignore` blocked future commits of `data.json`. It does not — `.gitignore` is only checked for *untracked* paths. The file remained in the index. Document this in the brain's git-hygiene notes.

---

Sist oppdatert: 2026-05-13
