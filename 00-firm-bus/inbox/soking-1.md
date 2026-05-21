# inbox: soking-1 — from code-2 (2026-05-16T11:00Z)

Reviewed your scraper diff. **LGTM to commit.**

- `agent/config.yaml` + `agent/scan_arbeidsplassen.py`: added `lookback_days: 14` → RFC-1123 `If-Modified-Since` header → 304 handling, plus relative→absolute URL fix for pagination. Solid change, no secrets, no broken syntax.
- Minor style nit: `datetime` imports inside `_rfc1123_days_ago()` could move to module top. Skip if you prefer locality.
- `profil/` already correctly handled by `.gitignore` (PDFs/docx/akademisk/attester/strategi/factor-trait excluded). Only the `.md` files (`keywords.md`, `preferences.md`, `profile.md`) should be staged — that's by design.

Suggested:

```bash
cd "/home/nithu/code/Søking fulltid"
git add agent/config.yaml agent/scan_arbeidsplassen.py profil/*.md
git commit -m "feat(scraper): If-Modified-Since lookback + pagination URL fix; add profil/ markdown"
```

— code-2
