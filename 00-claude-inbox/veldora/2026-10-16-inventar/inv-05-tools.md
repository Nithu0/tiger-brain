# inv-05 — Tool / MCP / capability roster (verified 2026-10-16)

Machine: WSL2 (Linux 6.6.87.2-microsoft-standard-WSL2), host `/home/nithu`.
Method: every "installed" claim below was verified by invoking the binary/module. UNKNOWN = not verifiable read-only.
No secret values read or printed. `.git/config` and `~/.ssh/**` not touched.

---

## 1. MCP servers (local, stdio)

Config locations found:

| File | Contents |
|---|---|
| `/home/nithu/.claude.json` → `mcpServers` (global) | `obsidian`, `filesystem`, `fetch`, `playwright`, `fetch-docker` |
| `/home/nithu/.claude.json` → `projects[...].mcpServers` | `/home/nithu/code/ai-assistent`: `nexus-pg-rw`, `playwright`; `/home/nithu/code`: `playwright`; `/home/nithu/code/callcenter.js-mcp`: `playwright` |
| `/home/nithu/code/.mcp.json` | `filesystem`, `fetch`, `playwright` (duplicates global) |
| `/home/nithu/code/ai-assistent/.mcp.json` | `{}` (empty) |
| `/home/nithu/.claude/mcp-needs-auth-cache.json` | auth-state cache, not a server definition |
| `/home/nithu/.docker/mcp/` | Docker MCP Toolkit state (`mcp-toolkit.db` 7.6 MB; `config.yaml`, `registry.yaml`, `tools.yaml` all **0 bytes**; `catalogs/` **empty**) |

No MCP config under `~/.config/`.

### Per-server status + diagnosis

All five "failed" servers were probed with a real `initialize` JSON-RPC handshake over stdio from a warm shell.

| Server | Transport / command | What it does | Probe result | Diagnosis |
|---|---|---|---|---|
| `fetch` | stdio `uvx mcp-server-fetch` | HTTP GET → markdown, for web pages | **HANDSHAKE OK** — `mcp-fetch 2026.10.10`, tools+prompts advertised | Binary fine, network fine (pypi 200). Failure is **startup-time/concurrency**, not capability. Cold `uvx` resolve on first run exceeds the MCP start window; 8 firm panes launching at once makes it worse. |
| `filesystem` | stdio `npx -y @modelcontextprotocol/server-filesystem /home/nithu/code` | Sandboxed read/write under `~/code` | **HANDSHAKE OK** — `secure-filesystem-server 1.0.0` | Same cause as `fetch`: cold `npx -y` fetch/link. Note it is also **redundant** — the native Read/Write/Bash tools already cover `~/code`. |
| `playwright` | stdio `npx @playwright/mcp@latest` (ai-assistent variant adds `--headless --isolated`) | Browser automation: navigate, click, extract, screenshot | **HANDSHAKE OK** — `Playwright 1.64.0-alpha`; browsers present in `~/.cache/ms-playwright/` (chromium-1223/1228 + headless shells + ffmpeg) | `@latest` forces a registry round-trip on **every** start → slow cold start. Everything else is in place. |
| `fetch-docker` | stdio `docker mcp gateway run --profile=cc-fetch` | Dockerised fetch via Docker MCP Toolkit gateway | **STARTS, then exits** — `Initialized in 6.567s`, `Start stdio server`, then `server is closing: EOF` (EOF is my probe closing stdin — expected) | Daemon is UP (Docker 29.1.3). Gateway pulls `mcp/fetch` image fine. Two real defects: **(a) 6.5 s init** because it loads *10 123* catalog servers from `docker-mcp-catalog:latest` + `mcp/community-registry:latest`; **(b)** `~/.docker/config.json` has `credsStore` empty → `! invalid config: empty credsStore`, `! No credential helper found`, falls back to `docker-credential-notfound`. Also `secrets engine is not available` (socket `~/.cache/docker-secrets-engine/engine.sock` absent). It is **fully redundant** with `fetch`. |
| `obsidian` | stdio `npx -y obsidian-mcp-server`, env `OBSIDIAN_BASE_URL=https://127.0.0.1:27124`, `OBSIDIAN_VERIFY_SSL=false`, `OBSIDIAN_API_KEY=<redacted>` | Read/search the Obsidian Brain vault via the Local REST API plugin | **HARD FAIL** — `https://127.0.0.1:27124` unreachable; nothing listening on 27124 (`ss -ltn` shows only 3100, 3200, 6767, 11434) | **Root cause: the Obsidian desktop app is not running.** No `Obsidian` process in WSL and none in Windows `tasklist.exe`. The Local REST API plugin lives *inside* the app, so the port only exists while Obsidian is open. This is the one genuine capability outage of the five. |
| `nexus-pg-rw` | stdio `bash /home/nithu/code/command-center/_bin/mcp-pg.sh NEXUS_PG_RW_URL` | Postgres read/write against the Nexus DB | Not probed (ai-assistent-scoped, out of lane, would touch a prod DB) | UNKNOWN. Credential-gated on `NEXUS_PG_RW_URL`. |

### Fixes (operator-gated — none applied)

| Server | Fix | Risk |
|---|---|---|
| `obsidian` | Start Obsidian on Windows and confirm the Local REST API plugin is enabled. Default route is `192.168.1.1 dev eth0` → WSL2 mirrored networking, so `127.0.0.1:27124` is the correct URL once the app is up; no config change needed. | None (just launch the app) |
| `fetch`, `filesystem`, `playwright` | Pre-warm the caches so startup is a local exec, not a network resolve: `uv tool install mcp-server-fetch`, `npm i -g @modelcontextprotocol/server-filesystem @playwright/mcp`, then pin the configs to the installed binaries and drop `-y` / `@latest`. Secondary: raise `MCP_TIMEOUT` in `~/.claude/settings.json` (currently unset → default). | Low; config edit is a dotfile change → ask first |
| `fetch-docker` | Easiest: **remove it** (redundant with `fetch`). If kept: set a `credsStore` in `~/.docker/config.json` and define a real `cc-fetch` profile — `~/.docker/mcp/registry.yaml` and `catalogs/` are empty, so the profile is resolving out of the two giant remote catalogs each start. | Config change → ask first |

`playwright` is defined **four times** across global + 3 project scopes, with inconsistent flags (only ai-assistent passes `--headless --isolated`). Worth consolidating.

---

## 2. Connected cloud MCPs (this session)

| Connector | State now | Notes for Veldora |
|---|---|---|
| Claude Docs | **USABLE** | Doc authoring/editing in-platform |
| ClickUp | **USABLE** | Full operator catalog via `clickup_get_operators` / `clickup_execute_operator` — viable as the tender/bid task tracker |
| Google Drive | **USABLE** | Tender attachment intake / storage |
| Gmail | AUTH REQUIRED | Tender notification e-mails from Doffin/Mercell would land here |
| MS365 | AUTH REQUIRED | SharePoint/Outlook/Excel; most Norwegian public-sector counterparties are MS365 |
| Asana, Atlassian, Linear, Monday, Notion, Slack (productivity plugin) | AUTH REQUIRED | Project/PM connectors; Slack matters — `Veldora/automation/SLACK-KANALER.md` already assumes Slack |

Not authenticated during this task, per instructions.

---

## 3. API keys / external services

Source: 42 `.env.example` files under `~/code` (maxdepth 3), **variable names only**. No real `.env` opened. `env-doctor.sh` exists only at `ai-assistent/scripts/ops/env-doctor.sh` and `jarvis-wt/scripts/ops/env-doctor.sh` — neither covers Veldora, so **no PRESENT/MISSING status can be reported for Veldora**.

| Domain | Variable names seen |
|---|---|
| LLM / AI | `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `AZURE_OPENAI_KEY`, `LOCAL_LLM_BASE_URL`, `LOCAL_LLM_API_KEY`, `OLLAMA_BASE_URL`, `MEMORY_DISTILLER_MAX_TOKENS` |
| Search / research | `TAVILY_API_KEY`, `NEWS_API_KEY`, `SEMANTIC_SCHOLAR_API_KEY`, `ELSEVIER_API_KEY`, `ZOTERO_API_KEY`, `ZOTERO_USER_ID`, `GROBID_URL` |
| **Norwegian business data** | `PROFF_API_KEY`, `BISNODE_API_KEY`, `AMBITA_API_KEY`, `EIENDOMSVERDI_API_KEY`, `ONE881_API_KEY`, `RESERVASJON_API_KEY` |
| **Norwegian payments / accounting** | `VIPPS_CLIENT_ID`, `VIPPS_CLIENT_SECRET`, `VIPPS_SUBSCRIPTION_KEY`, `VIPPS_WEBHOOK_SECRET`, `VIPPS_API_BASE_URL`, `FIKEN_API_TOKEN`, `FIKEN_CLIENT_ID`, `FIKEN_CLIENT_SECRET`, `FIKEN_REFRESH_TOKEN` |
| Messaging / alerts | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `TELEGRAM_API_ID`, `DISCORD_BOT_TOKEN`, 5× `DISCORD_*_WEBHOOK_URL`, `DISCORD_CHANNEL_ID` |
| Voice / media | `ELEVENLABS_API_KEY`, `AZURE_SPEECH_KEY`, `LIVEAVATAR_API_KEY`, `HEYGEN_STAR_AVATAR_ID`, `HEYGEN_STAR_VOICE_ID` |
| Storage / infra | `DATABASE_URL`, `REDIS_URL`, `QDRANT_URL`, `QDRANT_API_KEY`, `QSTASH_TOKEN`, `LITESTREAM_ACCESS_KEY_ID`, `LITESTREAM_SECRET_ACCESS_KEY` |
| Observability | `SENTRY_DSN`, `LOGTAIL_SOURCE_TOKEN`, `POSTHOG_KEY` |
| Web/analytics | `NEXT_PUBLIC_SITE_URL`, `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_GA4_ID`, `NEXT_PUBLIC_GOOGLE_ADS_ID`, `NEXT_PUBLIC_META_PIXEL_ID` |
| CRM / commerce | `CRM_BASE_URL`, `CRM_TJENESTE_TOKEN`, `CRM_INBOUND_SECRET`, `CRM_SESSION_SECRET`, `CRM_FNR_KEY`, `WOO_*` (4), `NOTION_API_KEY`, `NOTION_PAGE_ID` |
| Trading (Nexus, not Veldora) | `OANDA_*`, `POLYGON_API_KEY`, `FINNHUB_API_KEY`, `FRED_API_KEY`, `TRADING_ECONOMICS_API_KEY`, `MARKET_DATA_API_KEY`, `TRADINGVIEW_WEBHOOK_SECRET` |
| Auth / push | `AUTH_SECRET`, `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` |

**Notably absent:** no `DOFFIN_*`, `MERCELL_*`, `TED_*`, `EU_PROCUREMENT_*`, `BRREG_*` or `ALTINN_*` variable anywhere in the workspace. The tender-source integrations do not exist yet.

Veldora has **24 sibling worktrees** (`Veldora-anbud`, `-dok`, `-dok-pipe`, `-radar`, `-frist`, `-scope`, `-triage-a..e`, `-ruting`, `-union`, …), each with `website/.env.example`. The slice names imply a planned architecture (dok = documents, radar = discovery, frist = deadlines, triage = qualification) — read these before designing anything new.

---

## 4. Skills + agents

### User skills — `/home/nithu/.claude/skills/`

| Skill | Relevance to Veldora |
|---|---|
| `grill-me` | **High** — stress-test the build plan before coding |
| `write-a-prd` | **High** — PRD at `./prd/<slug>.md`; `Veldora-dok-pipe/prd/` already exists |
| `prd-to-issues` | **High** — slice PRD into vertical-slice issues |
| `humanizer` | **High** — Norwegian bid prose must not read as AI output |
| `tdd` | Medium — red-green-refactor loop |
| `improve-codebase-architecture` | Medium — Ousterhout-style deepening refactors |
| `finn-sok` | Low — FINN.no scraping; Norwegian-web-scraping prior art only |
| `heygen-avatar` / `-translate` / `-video`, `trading-knowledge` | Not relevant |

### Synced Anthropic skills — `~/.claude/skills/synced/6853767e-.../`

| Skill | Relevance |
|---|---|
| **`pdf`** | **Critical** — read/extract text+tables, merge/split, fill forms, OCR scanned PDFs. 8 helper scripts incl. `extract_form_structure.py`, `fill_fillable_fields.py`, `convert_pdf_to_images.py` |
| **`docx`** | **Critical** — read/edit/generate Word, tracked changes, templating. Tender responses are overwhelmingly .docx |
| **`xlsx`** | **Critical** — price forms / `prisskjema` are .xlsx. Has `scripts/office/validators/docx.py` |
| **`pptx`** | Medium — presentation decks |
| `deep-research` | **High** — multi-source research |
| `built-in-browser`, `chrome-browser`, `computer-use` | **High** — portal navigation where no API exists (Doffin/Mercell) |
| `google-workspace` | Medium — Drive/Docs/Sheets |
| `docs`, `morning`, `import-memory`, `skill-creator` | Support |

### Plugin skills — `~/.claude/plugins/`

- `claude-plugins-official`: `skill-creator`, `session-report`, `claude-md-improver`, plus `superpowers`, `frontend-design`, `feature-dev`, `commit-commands` on PATH
- `hyperframes` (21 skills): video/motion graphics — not relevant
- `productivity~g2`: `memory-management`, `task-management`, `start`, `update`
- `cowork-plugin-management~g2`: plugin authoring
- `.trash/` copies of productivity/cowork — ignore

### Agents — `/home/nithu/.claude/agents/` (10; `~/code/.agents/` is empty, no project `.claude/agents/`)

| Agent | Relevance |
|---|---|
| `researcher` | **High** — web+repo research, adversarially verified and cited |
| `data-pipeline` | **High** — ingestion/ETL/scraping; the natural owner of a tender-document pipeline |
| `backend-api` | **High** — Fastify/TS APIs |
| `frontend-craft` | **High** — Next.js 15 + Tailwind + SWR (Veldora is a Next.js site) |
| `ops-infra` | High — systemd/deploy/MCP |
| `code-reviewer`, `test-engineer`, `refactor-simplifier` | Medium — quality loop |
| `brain-engineer` | Medium — memory/RAG, if tender corpus goes into the Brain |
| `ml-scientist` | Low — thesis-scoped |

---

## 5. command-center capabilities

API live on `127.0.0.1:3100` — `/api/health` → `{"status":"ok","checks":{"db":"ok","firmBus":"ok","brain":"ok","workspace":"ok"}}`. Web cockpit live on `127.0.0.1:3200`.

ADR-001 binds Veldora to **file + HTTP only** — no shared imports, no shared DB.

| Package | Provides | Veldora over HTTP? |
|---|---|---|
| `router` | AI intent → command + risk classification (Opus prompt-caching) | Yes — `POST /api/router` |
| `executor` | Execution worker behind the approval gate (`ENFORCE_APPROVAL_GATE`) | Yes — `/api/executor`, `/api/commands` |
| `agents` | Agent desks (Atlas/Cipher/Shield/Prism/Forge/Blade) | Route exists but `/api/agents` returned **404** on probe — verify path before depending on it |
| `github` | PRs / branches / CI status | Yes — `/api/github` |
| `sync` | Cross-machine sync, operator registry, who-did-what | Indirect |
| `brain` | Read-only Brain Layer | Yes — `/api/brain/:id`, `/api/brain/health` → 200 |
| `engines` | Multi-engine abstraction (`AnthropicEngine`, `OpenAIEngine`); default via `CC_ENGINE` | Indirect, via router/agents |
| `auth` | HMAC session tokens; opt-in via `AUTH_SECRET` | Yes — `/api/auth/login`, `/api/auth/me` |
| `refiprep` | RefiPrep MVP (refinancing doc prep) | **Read the code** — closest existing analogue to structured document intake |
| `memory-engine`, `rag-engine` | Distillation + hybrid BM25+vector recall over ~13.4 k objects, 100 % bge-m3 embedded | Indirect — strong precedent for a tender-corpus RAG |
| `skill-registry` | 3-tier skill registry | Indirect |
| `book-ingest`, `obsidian-ingest`, `youtube-ingest`, `github-discovery` | Ingestion queue patterns | **Read `book-ingest`** — nearest prior art for document ingestion |
| `bus`, `git`, `shared` | firm-bus reader, cross-repo git status, project registry | `/api/terminals/feed` → 200, `/api/projects` → 200 |
| `brain-orchestrator`, `brain-worker` | 24/7 daemons (heartbeat/reaper/triggers; task claiming) | Indirect |

Other probed routes: `/api/projects` 200, `/api/brain/health` 200, `/api/terminals/feed?limit=1` 200.
Routes present in source: `agents, audit, auth, brain, brain-health, commands, devflow, executor, git, github, health, omnigent, orchestrator, projects, push, router, star, terminals`.

**`packages/shared/src/projects.ts` does not list Veldora** — registering it is likely a prerequisite for cockpit integration. (Commit 4dd9f2b added "de seks prosjektene registeret manglet"; confirm whether Veldora was among them.)

---

## 6. Running automation

`systemctl --user`: **23 services running, 0 failed.**

| Service | Role |
|---|---|
| `brain-orchestrator` | Heartbeat / reaper / triggers; gates G4 (nightly distill) + G6 (queue watcher) both ON |
| `brain-worker` | Claims + drains `agent_tasks`; runs distill + ingest |
| `cc-api` | Command-center API, 127.0.0.1:3100 |
| `cc-web` | Cockpit (Next.js), 127.0.0.1:3200 |
| `cc-omnigent` | Omnigent server 127.0.0.1:6767 (HTTP 200); firm-harness registered at start |
| `cc-omnigent-host` | Host daemon making this machine session-runnable |
| `firm-remote-executor@{infra-1,orchestrator-1,trading-1,learning-1,tools-1,paal-1,data-1,admin-1}` | 8 headless firm executors (v2 role map) |
| `firm-remote-verdict-watch` | Telegram approve/reject → host verify + push |
| `hermes-gateway` | Messaging-platform integration (Telegram etc.), `~/.hermes` venv |
| `litestream` | Continuous SQLite backup — **local file replicas only, no cloud** |
| `github-runner` | Self-hosted GitHub Actions runner (Solar-Consulting) |
| **`anbud-vakt`** | **"Anbud produksjonsvakt" (CRM + dashboard), report-only to firm-bus** — `~/.local/state/anbud-vakt/vakt.sh` |
| **`anbud-modell-vakt`** | **`llm_usage` in prod, report-only to firm-bus** — `command-center/_bin/anbud-modell-vakt.sh` |
| `at-spi-dbus-bus`, `dbus`, `gpg-agent` | Session plumbing |

Two `anbud` (= tender) watchdogs already run 24/7 — read them before building new monitoring.

**Timers (3):** `ollama-keepwarm.timer` (~10 min), `aslisten-crm-backup.timer` (daily ~03:34), `launchpadlib-cache-clean.timer` (daily).

**Cron (user):** Nexus watch `*/30 6-21 * * 1-5` + `35 4 * * *` (UTC); `30 7 * * *` → `command-center/_bin/morgenbrief.sh`. `/etc/cron.d` has only `e2scrub_all`.

**Local LLM:** Ollama on 127.0.0.1:11434 — `qwen2.5:7b`, `llama3.2:3b`, `deepseek-v4-pro:cloud`, `bge-m3:latest` (embeddings, dim 1024).

---

## 7. Document processing — the load-bearing section

### CLI (verified by `--version`)

| Tool | Status |
|---|---|
| `pdftotext` / `pdfinfo` (poppler-utils 24.02.0-1ubuntu9.10) | **INSTALLED** |
| `tesseract` 5.3.4 | **INSTALLED** |
| `ocrmypdf` 15.2.0+dfsg1 | **INSTALLED** |
| LibreOffice / `soffice` 24.2.7.2 | **INSTALLED** — headless docx↔pdf↔xlsx conversion |
| `ffmpeg` 6.1.1 | INSTALLED |
| `pandoc` | **MISSING** (apt candidate 3.1.3+ds-2) |
| `qpdf` | MISSING (`pikepdf` covers most of it) |
| `markitdown` | **MISSING** — the `xlsx` skill recommends it for quick sheet reads |
| `unoconv` | MISSING (superseded by `soffice --convert-to`) |

### Python 3.12.3 (verified by import)

| Module | Status |
|---|---|
| `pypdf` 6.10.2 | **INSTALLED** |
| `pdfminer.six` 20221105 | **INSTALLED** |
| `pikepdf` 8.7.1 | **INSTALLED** |
| `python-docx` 1.2.0 | **INSTALLED** |
| `openpyxl` 3.1.5 | **INSTALLED** |
| `python-pptx` 1.0.2 | **INSTALLED** |
| `pandas` 3.0.3 | **INSTALLED** |
| `lxml` 5.2.1, `pillow` 10.2.0, `img2pdf` 0.5.1 | INSTALLED |
| `pymupdf` / `fitz` | **MISSING** |
| `pdfplumber` | **MISSING** — the usual table-extraction workhorse |
| `unstructured` | **MISSING** |
| `pytesseract` | **MISSING** (CLI `tesseract` present; `ocrmypdf` wraps it) |
| `camelot`, `tabula`, `PyPDF2` | MISSING |

### Norwegian-language handling — the gap

```
$ tesseract --list-langs
List of available languages in "/usr/share/tesseract-ocr/5/tessdata/" (2):
eng
osd
```

**No `nor` / `nob` / `nno` traineddata.** OCR of any scanned Norwegian tender PDF will run through the English model and mangle `æ ø å`, Norwegian word shapes and procurement terms. `apt-cache policy tesseract-ocr-nor` → `Installed: (none)`, `Candidate: 1:4.1.0-2`. Installing it is an apt operation → operator-gated.

Note the apt candidate is a **4.1.0-era** traineddata package against a **5.3.4** engine. Tesseract 5 reads v4 `.traineddata` fine, but the better path for quality is the upstream `tessdata_best` `nor.traineddata` dropped into `/usr/share/tesseract-ocr/5/tessdata/`.

No Norwegian spell/grammar tooling found (no LanguageTool, no hunspell-nb). UNKNOWN whether any is needed — depends on whether Veldora generates Norwegian bid prose (likely).

### Live smoke test — real tender PDF

`/home/nithu/code/Veldora/Generell_kravspesifikasjon_-_Solcelleanlegg_kommunale_boliger_Sauda_kommune.pdf`

```
Producer:  Microsoft: Print To PDF
Tagged:    no
$ pdftotext -l 1 <file> -
Generell kravspesifikasjon
Solcelleanlegg kommunale
boliger, Sauda kommune
Dato: 27.02.2025
Versjon: 2
```

Clean Norwegian text extraction, `æøå` intact, **no OCR needed** for this one. `Tagged: no` means no structural/accessibility tree, so table and heading structure must be inferred from layout — exactly the job `pdfplumber` does and which is currently missing.

Veldora already holds a representative corpus at repo root: a kravspesifikasjon, an AKSJESALGSAVTALE, a skatteattest, `export_JournalEntryLine_21092026 (2).xlsx`, several `DOC-*.pdf`. Good fixture material for a parser test suite.

Veldora's own `website/package.json` has **zero** pdf/docx/xlsx/ocr/langchain/anthropic/supabase/prisma dependencies — nothing is wired yet on the Node side.

### Verdict

**Text-layer PDF, DOCX, XLSX and PPTX parsing is production-ready today** (poppler + pypdf + pdfminer + python-docx + openpyxl + python-pptx + LibreOffice + the four Anthropic skills). **Scanned Norwegian PDFs are not** — the OCR engine is installed but has no Norwegian model. Four gaps to close before serious tender-document work:

1. `tesseract-ocr-nor` (or upstream `tessdata_best/nor.traineddata`) — **blocking** for scanned docs
2. `pdfplumber` — table extraction from untagged PDFs (`prisskjema`, `kravmatriser`)
3. `pymupdf` — fast layout-aware extraction + page rasterisation
4. `pandoc` — format conversion (`markitdown` optional, recommended by the `xlsx` skill)

All four are installs → operator-gated. Nothing installed or changed by this task.

---

## Verification notes / limits

- All "INSTALLED" rows came from an actual `--version` or `import`. "MISSING" means the invocation failed.
- MCP handshakes were real `initialize` JSON-RPC probes over stdio, not inferred from config.
- `nexus-pg-rw` MCP: UNKNOWN, deliberately not probed (prod DB, out of lane).
- `/api/agents` returned 404 despite `agents.ts` existing — the mount path differs from the guess; confirm before depending on it.
- PRESENT/MISSING for secrets was not reported: no `env-doctor.sh` covers Veldora or command-center.
- The `obsidian` MCP's `OBSIDIAN_API_KEY` is stored in plaintext in `~/.claude.json`. Flagged, value redacted, not reproduced here.
