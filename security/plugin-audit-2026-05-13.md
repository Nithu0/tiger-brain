---
tags: [security, audit, plugins]
type: security-report
created: 2026-05-13
status: complete
---

# Plugin & .obsidian Secret Audit — 2026-05-13

## Summary

Audited every file under `.obsidian/` (top-level configs + plugin folder + git history) and every non-archived `.json` in the vault. **One plugin installed** (`obsidian-local-rest-api`) and it is the already-known leak source. **Zero NEW credentials discovered.** All currently tracked `.obsidian/*.json` files in git are clean (no API keys, tokens, certs, or private keys). The previously-known credential (`.obsidian/plugins/obsidian-local-rest-api/data.json`) is correctly gitignored and untracked in `HEAD`, but remains in commit `f824aa8` of local history; since the repo has **no git remote configured**, external exposure is still zero. Recommended action: no new gitignore lines required; existing `SECURITY-INCIDENT-API-KEY.md` already covers remediation (history purge before adding a remote).

## Plugins installed

| Name | Version | manifest.json | data.json | Secret hits | Severity |
|---|---|---|---|---|---|
| obsidian-local-rest-api | 3.6.2 | yes | yes (apiKey + RSA cert/privkey/pubkey) | 3 keys: `apiKey` (64-char hex), `crypto.cert` (PEM cert, 1216 B), `crypto.privateKey` (PEM RSA, 1702 B), `crypto.publicKey` (460 B) | HIGH (history-only) — already handled |

No themes installed (`.obsidian/themes/` absent). No `.obsidian/snippets/` or `.obsidian/templates/` folders. Only one community plugin per `.obsidian/community-plugins.json`.

## Detailed findings

### Plugin: obsidian-local-rest-api (v3.6.2)

Files in folder:

- `manifest.json` (308 B) — plugin metadata only. No secrets.
- `styles.css` (1296 B) — CSS. No secrets.
- `main.js` (2,595,037 B) — minified plugin bundle. Scanned for `sk-ant-`, `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `AKIA[0-9A-Z]{16}`, `BEGIN .* PRIVATE KEY` → **0 hits.** The 2 `BEGIN ` matches in main.js are inside the minified plugin source code referencing PEM block boundaries as string literals (parser code), not embedded credentials. Long-base64-like substrings exist (sourcemap fragments, embedded asset blobs) — classified LOW (false positives).
- `data.json` (3724 B) — **CONFIRMED LEAK.** Keys (values redacted):
  - `port`: integer (HTTPS port)
  - `insecurePort`: integer (HTTP port)
  - `enableInsecureServer`: bool
  - `apiKey`: 64-char string (HIGH severity)
  - `crypto.cert`: 1216-char PEM (LOW — public cert, but pairs with privateKey)
  - `crypto.privateKey`: 1702-char PEM RSA (CRITICAL if pushed)
  - `crypto.publicKey`: 460-char PEM

Tracked status in `HEAD`: **NOT tracked** (`git ls-files .obsidian/plugins/` returns empty). The file exists on disk but is correctly gitignored and was removed from the index in commit `36c424c` (`chore(security): gitignore + untrack obsidian local REST API plugin`). It is still present in the working tree (as required for the plugin to function) and in the blob graph at commit `f824aa8`.

### Top-level `.obsidian/*.json` files (all currently tracked)

| File | Bytes | Secret hits | Notes |
|---|---|---|---|
| `app.json` | 2 | 0 | empty `{}` |
| `appearance.json` | 2 | 0 | empty `{}` |
| `community-plugins.json` | 31 | 0 | lists `obsidian-local-rest-api` only |
| `core-plugins.json` | 696 | 0 | boolean flags only |
| `graph.json` | 511 | 0 | UI display settings |
| `workspace.json` | 6435 | 0 | gitignored (`.obsidian/workspace*`); leaf IDs and file paths only — no credentials |

### Other vault JSON

`00-claude-inbox/nexus/2026-05-11-karri-morning-discord-queued.json` — Discord webhook payload draft. Contains env-var **names** (`REGIME_DIRECTION_GATE_ENABLED`, etc.) but **no values**, no tokens, no webhook URL. CLEAN.

## Tracked-in-git status

`git ls-files .obsidian/` returns exactly:

```
.obsidian/app.json
.obsidian/appearance.json
.obsidian/community-plugins.json
.obsidian/core-plugins.json
.obsidian/graph.json
```

All five are credential-free. Plugin folder is untracked (correctly).

`git log --all --diff-filter=A -- .obsidian/` shows the plugin's `data.json`, `main.js`, `manifest.json`, `styles.css` were all added once in `f824aa8` and only `data.json` carries secrets. `36c424c` removed them from the index. The repo has **no remote** (`git remote -v` empty), so blast radius remains zero externally.

## Recommended `.gitignore` additions

**None.** Current `.gitignore` already covers the full plugin folder:

```
.obsidian/plugins/obsidian-local-rest-api/
.obsidian/workspace*
.obsidian/cache
```

Optional defensive hardening (not required — purely belt-and-suspenders):

```
# block ALL future Obsidian plugins by default; un-ignore individually if needed
.obsidian/plugins/*/data.json
.obsidian/plugins/*/*.pem
.obsidian/plugins/*/*.key
```

Rationale: any future community plugin you install may store its credentials in `data.json` too — denying that file pattern up-front prevents repeating this incident.

## Already known + handled

`.obsidian/plugins/obsidian-local-rest-api/` — see `SECURITY-INCIDENT-API-KEY.md`. Credentials in local commit `f824aa8`, never pushed (no remote), already gitignored and untracked from index. Open remediation step (per incident doc): purge the historical blob with `git filter-repo` or `BFG` **before** adding any git remote, then rotate the plugin's API key + regenerate its self-signed cert.

## Next actions

1. **No new `git rm --cached` needed** — the only file with secrets (`data.json`) is already untracked.
2. **Optional**: harden `.gitignore` with the three-line pattern above (covers future plugins). Edit only — no commit unless operator says "OK kjør".
3. **Pre-existing action item** (already in `SECURITY-INCIDENT-API-KEY.md`): before pushing this vault to any remote (public or private), purge `f824aa8`'s `data.json` blob from history and rotate the plugin credentials.
4. **No further audit required** — single-plugin vault, no themes, no snippets, no templates, no `.env` / `.pem` / `.key` files anywhere in the vault tree.
