# inv-06 — Adjacent repos: what Veldora can harvest

Read-only inventory, 2026-10-16. Scope: the repos *not* covered by the other
inventory agents (ai-assistent, Master-oppgave/research-os, Brain, command-center,
Veldora). Dates are `git log -1 --format=%ci` where a repo has git, otherwise newest
non-vcs file mtime. No secrets, no PII, no financial figures reproduced below.

---

## 0. Two scope corrections up front

**`SC-rename` is not a separate repo — it is a git worktree of Veldora.**
`SC-rename/.git` contains `gitdir: /home/nithu/code/Veldora/.git/worktrees/SC-rename`,
checked out on branch `chore/slack-linear-rename` @ `289bcb7` (2026-10-04). The
`/home/nithu/code/Veldora` checkout is on `feat/secure-age` (2026-09-15), i.e. an
*older* commit of the same repo. So SC-rename holds the Solar Consulting
strategy/procurement corpus and the Veldora agent is nominally covering it — but
**only if that agent looks at branch `chore/slack-linear-rename`, not at the Veldora
working tree**. Flagging this explicitly because the most valuable procurement assets
in this whole sweep live there and are easy to miss. §7 lists them anyway.

**`cc-leakscan` and `jarvis-wt` are clones of in-scope-elsewhere projects.**
- `cc-leakscan/CLAUDE.md` line 1 = `# CLAUDE.md — command-center`; it has
  `apps/`, `packages/`, `_bin/`, `omnigent/`. It is a working copy of command-center
  (newest file 2026-10-15, memory-engine migrate.ts). Covered by the command-center agent.
- `jarvis-wt/CLAUDE.md` line 1 = `# CLAUDE.md — Nexus XAUUSD Firm`. It is an
  ai-assistent worktree/copy, stale since 2026-06-24. Covered by the gold agent.
Neither contains anything Veldora-specific. Skip both.

---

## 1. One-screen verdict per repo

| Repo | What it is | Stack | Alive? | Veldora value |
|---|---|---|---|---|
| `refi-doc-agent` | Norwegian document-intake agent for refinancing cases: upload → OCR → classify → deterministic number extraction → per-bank checklist → draft e-mail | Python 3.11, FastAPI, Jinja2, pypdf+pdfplumber, Tesseract, Fernet, SQLite, Anthropic SDK | **Abandoned but complete.** No `.git` at all. Newest source 2026-06-03/04. 34 py files, ~3k LoC app + 15 test files | **HIGHEST.** It is a working prototype of Veldora's document core, already in Norwegian, already with the LLM-never-touches-numbers posture. §2 |
| `aslisten-crm` | Case/CRM platform for buying & selling Norwegian AS shells (a *different* business — regnskapsfører Pål, aslisten.no) | Next.js 15 + TS, SQLite, 18 SQL migrations, vitest (57 test files) | **Alive.** Last commit 2026-10-03, working files to 2026-10-15, 231 commits | **HIGH for code, ZERO for data.** No Solar Consulting content. But `src/lib/brreg.ts` is a production-grade Brønnøysund client, and the orgnr MOD11 validator is directly liftable. §3 |
| `leadgen-mvp` | Multi-vertical lead-gen: open Norwegian registries → Claude enrich/score → CSV/HTML | Python, httpx, YAML profiles, Anthropic SDK | **Abandoned.** Last commit 2026-06-22, 9 commits | Medium. The YAML *profile* pattern (sources + rubric + compliance gate + opener per vertical) is the best scoring-config design of the three. §4 |
| `leadgen-pipeline` | One-off: brreg equity filter → 1881 phone → prioritized Excel for one finance adviser | Python, openpyxl | **Abandoned.** Last commit 2026-06-26 (newest of the three), 8 commits, ~1000 LoC | Low. Single-user Excel tool. Only `scripts/brreg_acquire.py` (equity-threshold company sweep) is interesting. §4 |
| `leadgen-platform` | TS monorepo rewrite of the same idea: pluggable connectors, vertical modules, daily review queue | npm workspaces, TS, Fastify, better-sqlite3, Next 15, vitest | **Abandoned.** Last commit 2026-06-23, 5 commits, ~6.7k LoC | Medium-high. The cleanest *architecture* of the three — `packages/core/src/types.ts` is the pipeline contract Veldora's tender funnel should copy. §4 |
| `call-center-ai-demo` | Runnable demo: transcribe Norwegian calls → LLM QA analysis, with a documented-effect eval page | Python, FastAPI, pluggable STT/LLM providers, pydantic | **Abandoned.** Last commit 2026-06-23, 10 commits | Medium-high for *patterns*: provider abstraction, PII redaction, gold-label eval harness. §5 |
| `callcenter.js-mcp` | Third-party vendored repo (`gerkensm/callcenter.js-mcp`) — MCP server that places SIP/VoIP calls via OpenAI Realtime | Node 20+, TS, native G.722 codec | **Not ours, upstream-stale.** Last commit 2025-10-02 (upstream dependabot) | Low. Only `src/mcp-server.ts` as a reference MCP-server shape. §5 |
| `grossist-plattform` | Clean-room platform code for a local AI admin platform; synthetic data only | pnpm monorepo, TS, Hono, SQLite | **Recent but thin.** Last commit 2026-10-11, only **2 commits** | Medium, narrow. `packages/license` (Ed25519 signed licence + enforcement ladder + heartbeat) and `packages/policy` (reason-codes, threat-control-matrix) are productization scaffolding. §6 |
| `lavera-site` | Static marketing page (4 files: index.html, app.js, styles.css, img/) | vanilla HTML/CSS/JS | **Abandoned.** No git. Newest file 2026-09-26 | None. |
| `cc-leakscan` | Copy of command-center | — | Working copy, files to 2026-10-15 | None (duplicate). |
| `jarvis-wt` | Copy of ai-assistent/Nexus | — | **Abandoned.** Newest file 2026-06-24 | None (duplicate). |
| `Renseri` | Public marketing site + lead form for a mobile cleaning/key/locksmith service | Next.js 16, React 19, Tailwind v4, Vercel | **Dormant.** Last commit 2026-09-25, 13 commits | Low-medium. `src/lib/leads/*` (attribution, reference-number generation, rate-limit, email) and `src/lib/analytics/consent.ts` are small, finished, GDPR-aware lead-intake pieces. |
| `SC-rename` | **Veldora worktree** holding the Solar Consulting strategy + procurement intelligence corpus | Node ESM scripts, JSON Schema, YAML, Next.js site | Branch head 2026-10-04, 87 commits | **HIGHEST (but see §0).** §7 |
| `AS/` | Operator's own accounting repo for **KUKARAJA SIKKERHET (ENK)** — payslips, receipts, Fiken sync, income-strategy docs | Python scripts + Fiken API client + a pile of PDFs/XLSX | **Dormant.** Last commit 2026-07-21, files touched to 2026-10-03, 17 commits | **Low for company facts, HIGH for one document.** It is *not* Solar Consulting. §8 |
| `Søking fulltid/` | Job-hunting automation: scrape postings → score fit → draft letters, plus the operator's CV/credential library | Python agents, Streamlit-ish CRM, DOCX/PDF assets | **Dormant.** Last commit 2026-07-28, CV updated 2026-10-03, 8 commits | **HIGH.** The competence evidence Veldora needs for qualification requirements. §9 |
| `Personlig/` | Personal optimisation tracking (effectiveness, food, training) | Python, Streamlit, YAML frontmatter | **Abandoned.** Last commit 2026-06-03, 4 commits | None. |
| `_refs/` | Vendored reference repos: `pysystemtrade` (878M), `nautilus_trader` (204M), `claude-trading-skills` (39M), `awesome-systematic-trading` | — | Frozen 2026-06-14 | None — all trading-domain. |
| `_logs/` | Empty directory | — | Empty since 2026-05-03 | None. |
| `vendor/` | One vendored MCP server: `telegram-mcp` (Python/Poetry) | Python | Frozen 2026-08-14 | None for Veldora. |

---

## 2. Deep dive — `refi-doc-agent` (the single best code lift)

**Status: abandoned, no git history at all.** Newest source file 2026-06-03,
`.pytest_cache` touched 2026-06-04. ~147 MB on disk, almost all `.venv`. The code
itself is small, finished and tested.

### What it parses, with what

`app/services/ingest.py` (180 lines) is a three-tier text extractor:

1. **pypdf** `PdfReader` over all pages (`_extract_pdf`).
2. If the result is `< 40` non-whitespace chars → **pdfplumber** fallback
   (explicitly chosen "better on tables/forms"); keeps whichever yielded more text.
3. If still `< _OCR_TEXT_THRESHOLD` (40) → **OCR** via `app/services/ocr.py`:
   `pdf2image.convert_from_bytes(dpi=300, last_page=10)` → `pytesseract` with
   `lang="nor+eng"` and an automatic retry at `lang="eng"` when the Norwegian
   traineddata is missing. Direct image uploads (10 suffixes incl. HEIC) skip
   straight to OCR.

OCR degrades safely: `ocr_available()` checks the `REFI_OCR_ENABLED` flag, the
Python bindings *and* `pytesseract.get_tesseract_version()`, warns once, and returns
`""` — an upload never crashes because Tesseract is absent. An `ocr_used` boolean is
carried all the way to the UI as a lower-confidence marker.

sha256 and text extraction both run on **plaintext bytes before** at-rest encryption,
so the checksum is of the real document and the parsers never see ciphertext
(`ingest()`, lines ~160-175). `store_upload()` then Fernet-wraps the bytes when
`REFI_DATA_KEY` is set.

### How good is the extraction pipeline?

Better than its size suggests, because it is honest about its limits.

`app/services/extraction.py` (259 lines) is the piece to copy wholesale:

- **Norwegian money parsing that actually works.** `_NUM` handles `45 000,50`,
  `45.000,50`, `45000`, `kr 1 234`, `1 234,-`, and — the part most people get wrong —
  NBSP ` `, narrow NBSP ` ` and thin space ` ` as thousands separators.
- **Label→amount rules are doc-type-scoped.** A `_Rule` carries
  `doc_types: set[str]`, so a "gjeld" pattern cannot fire on a payslip. The
  label-to-amount gap is `[^\d\n]{0,20}?` — deliberately digit-free so a label cannot
  reach across an unrelated number.
- **Every extraction keeps provenance:** `source_snippet` (±30 chars around the match)
  and `method="python-regex"`, persisted in the `talluttrekk` table.
- **`field_status_for_sak()` reports what was NOT found**, and distinguishes
  "source document missing" from "document present but the figure did not parse —
  verify manually". That is the uncertainty surface Veldora needs on requirement
  extraction, and it is rarer than it should be.

### The governance posture is the real asset

`extraction.py` opens with a boxed JURIDISK KRITISK banner: every number is
deterministic Python, an LLM never touches one, and *if a figure cannot be parsed
deterministically it is not returned*. `app/services/llm.py` enforces the other side —
the LLM is used for exactly two things (document-type label, e-mail draft prose) and
`classify()` constrains the model's output to the known `DOC_TYPES` keys, coercing
anything else to `ukjent` and refusing to let the LLM downgrade a medium heuristic
hit. Backends: `off` (default, zero egress), `local-openai-compatible`, `anthropic`.

Veldora will be asked "did an AI make up this number in our tender response?" This
codebase already has the answer written down and enforced in code.

### Concretely liftable files

| File | Lines | What to lift |
|---|---|---|
| `app/services/extraction.py` | 259 | Norwegian money regex, doc-type-scoped rule table, `field_status_for_sak()` not-found reporting |
| `app/services/ingest.py` | 180 | pypdf → pdfplumber → OCR cascade + encrypt-after-hash ordering |
| `app/services/ocr.py` | 134 | `nor+eng` Tesseract with safe degradation, DPI/page caps |
| `app/services/classify.py` | 92 | Two-stage heuristic-then-LLM classification with output coercion |
| `app/services/checklist.py` | 130 | `build_mangelliste()` + `bank_readiness()` — rename bank→buyer and this *is* tender-requirement completeness |
| `app/services/bank_profiles.py` | 152 | Data-driven per-counterparty requirement registry (flat dict, one-line edits) — Veldora's per-buyer document-requirement profiles |
| `app/services/storage.py` | 424 | SQLite schema: `saker`/`dokumenter`/`talluttrekk`/`audit_log`, append-only audit (no update/delete path by design), idempotent `ALTER TABLE` column-add upgrade |
| `app/services/crypto.py` | 101 | Fernet at-rest wrapper |
| `tests/` | 15 files | incl. `test_extraction.py`, `test_ocr.py`, `test_crypto.py`, `test_retention.py` |

Env var **names** only: `REFI_DB_PATH`, `REFI_UPLOAD_DIR`, `REFI_OPERATOR`,
`REFI_PASSWORD`, `REFI_DATA_KEY`, `REFI_ALLOW_REAL_DATA`, `REFI_OCR_ENABLED`,
`REFI_SEED_ON_START`, `LLM_BACKEND`, `ANTHROPIC_API_KEY`, `CLAUDE_MODEL`,
`LOCAL_LLM_BASE_URL`, `LOCAL_LLM_API_KEY`, `LOCAL_LLM_MODEL`.

**Caveat:** `bank_profiles.py` documents its own requirement sets as
"realistic-but-GENERIC placeholders … NOT scraped from or verified against any bank's
current public requirements". Lift the *structure*, not the table contents.

---

## 3. Deep dive — `aslisten-crm`

### Does it hold Solar Consulting's history? No.

Checked directly: `grep -ril "solar consulting"` across the repo → zero hits.
`grep -rl "931949837"` (Solar Consulting's org number, taken from a filename in the
Veldora tree) → zero hits. ASListen is a **different business**: back-office
case handling for buying and selling Norwegian AS shells, run for one regnskapsfører,
with the public aslisten.no WooCommerce shop as a separate front end. The companies in
it are pizzerias, bistros and similar transaction targets — nothing to do with Solar
Consulting's deliveries, clients or references.

### Schema and volume

18 SQL migrations in `migrations/0001_init.sql` … `0018_jobber.sql`. Core entities:
`contacts`, `companies`, `cases`, `case_parties`, `company_changes`, `documents`,
`messages`, `automation_runs`, `approvals`, `tasks`; later migrations add templates,
a customer-facing page, FK indexes, Facebook leads, template checksums, signatory
mobile, rate limits, structured findings, a three-state identity model, WooCommerce
orders/status/payment, power-of-attorney, users+sessions, TOTP, and a jobs queue.

`data/crm.db` is **143 KB of development data, not production**:

| Table | Rows |
|---|---|
| automation_runs | 143 |
| messages | 26 |
| documents | 12 |
| contacts | 11 |
| case_parties | 11 |
| cases | 10 |
| company_changes | 7 |
| approvals | 4 |
| companies | 4 |
| tasks | 5 |

Plus 14 per-case document folders under `data/documents/AS-2026-NNNN/` holding
generated DOCX/HTML (aksjeeierbok, aksjeoverdragelse, generalforsamling). I did not
open any of them. Production data, if it exists, is on Railway, not here.

### What to lift anyway

- **`src/lib/brreg.ts` (9.2 KB)** — the best Brønnøysund client in the workspace.
  Three endpoints (Enhetsregisteret, `/roller`, Regnskapsregisteret), typed
  `BrregCompany`/`BrregRole`/`BrregFinancials`, and it reads fields most clients miss:
  `underTvangsavviklingEllerTvangsopplosning` (court-ordered dissolution, a *different*
  state from voluntary `underAvvikling`), `registrertIForetaksregisteret`,
  `registrertIMvaregisteret`, `vedtektsfestetFormaal`, `antallAnsatte`. Role lookups
  carry `resigned` and `deceased`. For Veldora this is buyer enrichment *and*
  competitor/supplier qualification lookup in one file.
- **`isValidOrgnr()` / `normalizeOrgnr()`** — the official MOD11 checksum with
  weights `[3,2,7,6,5,4,3,2]`, rejecting check-digit 10. Stops false orgnr matches in
  extracted tender text. ~15 lines, copy it.
- **The honesty invariant** — "API-data overskriver aldri godkjente data — endringer
  vises som «før → etter» til kontroll". Veldora needs exactly this when Doffin/TED
  data conflicts with a human-confirmed fact.
- `src/lib/extract.ts` (13.5 KB) — deterministic heuristic extraction (orgnr, name,
  price, date, phone, email, case type) with optional Claude refinement behind a
  feature flag, zod-validated, uncertain fields → `null`, and a hard PII rule that
  fødselsnummer never reaches an LLM.
- `src/lib/doc-templates.ts` + `docx-write.ts` + `templates.ts` (68 KB) — DOCX
  generation from templates with checksums, which is the shape of tender-response
  document assembly.
- 57 vitest files, several of them adversarial (`kundeside-fiendtlig.test.ts`,
  `qa-falske-utslag.test.ts`, `stille-feil.test.ts`, `duplisert-sannhet.test.ts`).

---

## 4. Deep dive — the three `leadgen-*` repos

### Why there are three

They are three successive attempts at the same idea within four days, not three
products. The git dates make the sequence obvious:

1. **`leadgen-mvp`** (last commit 2026-06-22, 9 commits) — the first build. Python,
   "concierge-MVP skjelett", explicitly framed as P1 from
   `command-center/docs/ops/sky-first-business-strategy.md`. Generalises to
   multi-vertical via YAML profiles mid-life.
2. **`leadgen-platform`** (2026-06-23, 5 commits) — a same-week TypeScript rewrite
   as a proper monorepo with stable contracts. Abandoned one day later.
3. **`leadgen-pipeline`** (2026-06-26, 8 commits) — a retreat to a single concrete
   deliverable: one finance adviser, brreg + 1881, one prioritized Excel. The newest
   and the narrowest.

All three died in June 2026. None has been touched since.

### Which is most mature?

**Split answer, and it matters for what you lift.**

- **Most mature architecture: `leadgen-platform`.** ~6.7k LoC across
  `packages/{core,connectors,verticals/finans,verticals/eiendom}` + `apps/{api,web}`,
  with tests at every layer. `packages/core/src/types.ts` declares the stable
  contracts — `Prospect → EnrichedProspect → Lead`, plus `SourceConnector`,
  `EnrichmentProvider` and a `VerticalModule` interface bundling
  `{scoreWeights, enrich, score, draftOutreach, dailyTasks}`. Pipeline is
  `source → dedupe → enrich → score → qualify → draftOutreach → Lead[]`. Connectors
  are mode-tagged `synthetic | live` so the whole thing runs offline. The finans
  vertical scores against named numeric weights (`belaningsgradHeadroom 0.25`,
  `rentemargin 0.30`, `besparelse 0.35`, `forbruksgjeld 0.10`) and returns
  `{score, tier A|B|C, reasons[]}` — explainable, not a black box.
- **Most mature *domain* work: `leadgen-mvp`.** 10 real source connectors under
  `app/sources/` (brreg, brreg_regnskap, reelle_rettighetshavere, aksjonaer,
  matrikkel, + clearly-labelled paid STUBs for proff/bisnode/one881/ambita/
  eiendomsverdi), each with the same `fetch(bransje, omrade, limit, profile)`
  contract and a one-line REAL/STUB marker. Dedup is on `org_nr`.

### Scraping architecture

There is deliberately almost no scraping. All three refuse it and route through open
APIs instead:

- `data.brreg.no/enhetsregisteret/api/enheter` — company universe, no key.
- `data.brreg.no/regnskapsregisteret/regnskap/{orgNr}` — annual accounts; the
  `egenkapital` figure is used as a lawful registry-derived wealth proxy
  (`min_egenkapital: 20000000` in the finans profile).
- Kartverket/Geonorge matrikkel — property universe, no owner names.
- Beneficial-owner register by org.nr.
- Everything paid (Proff, Bisnode, 1881, Ambita, Eiendomsverdi) is a typed stub that
  returns sample rows, never a scraper.

The compliance stance is written into code, not just docs: no skattelister anywhere,
no Finn.no scraping, Reservasjonsregisteret scrub before any B2C contact, GDPR art.13/14
notice stamp, and `human_review_required` forced `True`. `app/compliance.py::_is_reserved`
returns **`None` (unknown) rather than `False` when it has no access** — it will never
emit a false "cleared". That three-state pattern is worth copying verbatim into
Veldora's qualification gates.

### Scoring architecture

`leadgen-mvp/app/scorer.py` sends batched leads to Claude with a **JSON-schema-
constrained structured output** (`{index, score 0-100, reason, opener}`) and a rubric
templated per vertical. The rubric itself lives in `profiles/*.yaml`, not in code:

```
profiles/finans_hnw.yaml:  sources[] · min_egenkapital · compliance{} · rubric | · opener_template |
profiles/eiendom.yaml:     same shape, stricter compliance block
```

That YAML-profile shape — *sources + threshold + compliance gate + LLM rubric +
output template, one file per vertical* — is the single most directly transferable
idea from the leadgen trio. Veldora's equivalent is one profile per buyer type or per
CPV family.

Also: `api_key_present()` treats the placeholder string `FYLL_INN_HER` as unset, and
with no key the pipeline still runs fetch + export. Small, but it is the right
degradation default.

### What to lift

| From | File | Why |
|---|---|---|
| leadgen-platform | `packages/core/src/types.ts` (119 lines) | The pipeline contract; rename Prospect→Tender and it fits |
| leadgen-platform | `packages/verticals/finans/src/index.ts` | Named-weight explainable scoring returning `reasons[]` |
| leadgen-mvp | `profiles/*.yaml` | The vertical-profile config shape |
| leadgen-mvp | `app/compliance.py` (112 lines) | Three-state gate (`True/False/None`) + forced human review |
| leadgen-mvp | `app/scorer.py` (148 lines) | Schema-constrained Claude scoring with graceful no-key path |
| leadgen-mvp | `app/sources/brreg_regnskap.py` | Equity-threshold enrichment over the brreg universe |
| leadgen-pipeline | `scripts/brreg_acquire.py` (176 lines) | `--kommune X Y Z --min-ek N` company sweep CLI |

---

## 5. Deep dive — `call-center-ai-demo` + `callcenter.js-mcp`

### `call-center-ai-demo` (ours, abandoned 2026-06-23, 10 commits, ~4.7k LoC)

Norwegian call transcription + automated QA analysis, built as a pitch artefact for
"Loyalty". Three things in it outlive the pitch:

**1. Provider abstraction (`app/providers/`).** One env var moves the whole system:
`DEPLOY_TARGET=azure` makes `app/config.py` select `STT_BACKEND=azure` and
`LLM_BACKEND=azure-openai`; default `local` uses deterministic mock providers and runs
fully offline with no keys. Both backends return the same pydantic models
(`Transcript`, `Analysis`) so the UI is backend-agnostic. `app/providers/llm.py` is
901 lines and — notably — carries a **complete deterministic mock implementation**
(`_analyze_mock`, `_build_scorecard`, `_sentiment`, `_classify`, `_key_info`,
`_compliance_flags`, `_coaching_tips`) alongside the real `_analyze_anthropic` /
`_analyze_azure_openai` paths. That is how you demo and test an LLM product without
a key, and Veldora will want it.

**2. Prompt management.** Single `_ANALYSIS_SYSTEM_PROMPT` constant, a
`_coerce_analysis(raw, backend)` function that forces model output into the pydantic
shape, and `_extract_json()` for fenced-block tolerance. Not a framework, but a clean
minimal pattern: one prompt constant + one coercion function + one JSON extractor.

**3. Eval harness (`app/routers/eval.py`, 213 lines).** This is the most
Veldora-relevant piece. It compares AI output against a **human-labelled gold file**
(`data/_labels.json`), reports per-call agreement % on scorecard items, sentiment and
reason-classification, plus an aggregate accuracy — and loads gracefully with the
labels file absent. Bolted onto it is a time-saving/ROI model with named, editable
assumptions (`DEFAULT_MIN_PER_MANUAL_QA = 8`, `DEFAULT_HOURLY_COST = 450`,
`AI_SECONDS_PER_CALL = 5`) and a live slider UI. Veldora needs precisely this to
answer "how accurate is your requirement extraction?" with a number instead of a
claim. Companion scripts: `scripts/wer.py`, `scripts/verify_llm.py`,
`scripts/verify_stt.py`, and `app/routers/stt_compare.py` (279 lines).

**4. `app/redaction.py` (204 lines).** Deterministic regex PII masking for Norwegian
text — `FNR | TLF | E-POST | KONTONR | KORTNR | NAVN` — no model, no network. Two
good design calls documented in the docstring: conservative on fødselsnummer (any
11 consecutive digits is masked rather than risk a leak), and pattern order is
deliberate so specific structured patterns (email, account-no-with-dots, card) run
before the generic digit patterns. Returns `(masked_text, findings)` where each
finding is `{type, original_maskert: "12•••••••89", posisjon: [start, end]}` — an
audit trail that does not itself contain the PII. Tender documents contain contact
persons; this is a drop-in.

**5. `app/integrations/crm.py` + `telephony.py`** (125 / 120 lines) — thin integration
adapters, nothing special.

### `callcenter.js-mcp` (NOT ours)

Upstream `gerkensm/callcenter.js-mcp`, vendored. Last commit 2025-10-02 and it is a
dependabot merge — the local `.gitignore` touch on 2026-10-03 is the only local
activity. The README's own words: *"Vibe-coded side project! Please do not use this
in any kind of professional context … There are no guard rails."*

It is a SIP/VoIP agent (G.722 native codec, Fritz!Box/Asterisk/3CX/Cisco configs)
bridging OpenAI Realtime to phone lines. Nothing in the domain transfers. The only
reusable artefact is `src/mcp-server.ts` as a reference for MCP tool-server shape —
and command-center already has better in-house examples. **Recommend: ignore.**

---

## 6. `grossist-plattform` — narrow but current

Last commit 2026-10-11, but only **2 commits total**; this is a fresh extraction, not
a mature product. pnpm monorepo, synthetic data only by policy. Three packages matter
if Veldora is ever sold as a product rather than run in-house:

- `packages/license/` — `signing.ts`, `canonical-json.ts`, `schema.ts`,
  `enforcement.ts` (an enforcement *ladder*, not a binary kill switch), `heartbeat.ts`,
  `time.ts`, and `testing.ts` exposed as a `@grossist/license/testing` subpath for
  fixtures. Ed25519-signed licence files verified offline.
- `packages/policy/` — `reason-codes.ts`, `threat-control-matrix.ts`,
  `rule-bundle.ts`, `action-policies.ts`, `execution.ts`. A structured policy engine
  with machine-readable reason codes; the reason-code pattern is reusable for
  "why was this tender gated".
- `packages/db/` — `tenant.ts`, `hardening.ts`, `type-enforcement.ts` plus a
  tenant-typecheck test. Multi-tenant isolation enforced at the type level.

`infra/license-server/` is a Hono + SQLite sketch issuing licences and taking
metadata-only heartbeats.

---

## 7. `SC-rename` — the Solar Consulting corpus (Veldora worktree, see §0)

Branch `chore/slack-linear-rename` @ 2026-10-04, 87 commits. This is the "know our own
company" and "know the tender domain" layer, and it is far more built out than the
task brief assumed. Highlights, since another agent may be reading an older branch:

**`procurement/qualification/` — 13 files.** `qualification-matrix.yaml` is one row per
qualification requirement a Norwegian public buyer may lawfully impose, each with its
legal basis, **which Part of anskaffelsesforskriften it applies in**, what must be
documented, and where the company actually stands (`our_status`, with a named owner on
every `UNKNOWN`). Its header encodes the value bands that decide everything —
under 500k outside LOA/FOA, 500k–1.3M Del I, 1.3M–EØS Del II, above that Del III —
and records that FOA's lower threshold rose to 500 000 kr on 2026-07-01 and that LOA § 4
is repealed "fra den tid Kongen bestemmer". It is marked UTKAST TIL JURISTGJENNOMGANG.
Siblings: `bid-gate.md`, `espd.md`, `references.md`, `supporting-entities.md`,
`financial-capacity.md`, `informasjonssikkerhet.md`, `kvalitetssystem.md`,
`tender-readiness-checklist.md`, `faste-vs-anbudsspesifikke-krav.md`,
`reference-cases.template.yaml`.

**`automation/lib/bid-gate.mjs`** — the executable qualification gate, zero runtime
deps, Node stdlib only. Five ranked outcomes starting at `QUALIFIED`, with the ranking
derived from the array order so the two cannot drift apart. Two design rules worth
stealing outright: *value → part → ruleset → assessment, in that order* (it refuses to
evaluate any requirement before the Part is established, and never infers a Part from
a value it does not have), and *a requirement is a chain of routes, not a checkbox*
(three references required and zero held is not `NOT_QUALIFIED` until the key-personnel,
alternative-evidence, supporting-entity, subcontractor and consortium routes have each
been tried). Per ADR-0011 the gate is **advisory**: the result struct has a
`bid_no_bid` field that is always `null` and no line in the file sets it.

**`projects/anbud/ARCHITECTURE.md`** — the full contract for the live tender platform:
Vercel dashboard + Railway Payload 3/Postgres CRM + worker from one image, pinned
`payload@3.90.2`/`next@15.5.x`/Node 22, env var names only, and a Payload collection
model (`tenders`, `buyers`, `signals`, `predictions`, `agent-runs`) where every
externally-sourced record carries
`provenance {source, url, retrievedAt, publishedAt, confidence}` and unknowns are
`null`, never guessed. It explicitly ports the Nexus trading patterns — blackboard
message types, agent bus, gate registry, shadow log, Brier-scored calibration,
morning briefing — onto tenders. Also solves a real modelling trap: a Doffin id or TED
publication number identifies *one notice*, not a procurement, so
`lib/tenders/related.ts` links RESULT/CHANGE notices and cross-source twins back to a
root notice (by `procedureId`, else buyer+normalised title within 2 years, else
buyer+title with deadline ±1 day), and a linked notice never gets its own opportunity.

**`data/schemas/` — 16 JSON Schemas** (draft 2020-12): `opportunity`, `procurement`,
`award`, `buyer`, `supplier`, `cpv`, `requirement`, `qualification-requirement`,
`reference-case`, `capability`, `product`, `agent`, `data-source`, `feedback`.
`opportunity.schema.json` carries the funnel enums —
`status: spotted|screening|analysing|bidding|submitted|won|lost|declined|expired`,
`decision: STRONG_BID|BID|INVESTIGATE|NO_BID|UNDECIDED` with `decision_rationale`
required once decided ("a no-bid without reasoning teaches us nothing") — plus
`fit_score 0-100`, `win_probability 0-1`, `incumbent_id`, `competitors_expected[]`.

**`data/sources/` — 13 researched source dossiers** with rights fields
(`storage_rights`, `analysis_rights`, `redistribution_rights`, `ai_processing_rights`,
`licence_status`), each with provenance and a dated `next_action`. The two that matter:
`doffin.json` records that doffin.no is a JS shell and unusable without JS, that
robots.txt is permissive, and that the real API is Azure API Management at
`dof-notices-prod-api.developer.azure-api.net` requiring a subscription key via header
`Ocp-Apim-Subscription-Key` — terms still UNKNOWN. `ted.json` records that TED API v3
Search at `api.ted.europa.eu` needs **no key**, with the SIMAP legal notice quoted
(free commercial reuse, metadata CC0) and the rights fields deliberately left UNKNOWN
pending a lawyer. `automation/checks/stale-sources.mjs` tracks how long a source sits
at UNKNOWN (warn 30d, fail 90d).

**`automation/agents/anbud.{json,md}`** — status `PAUSED` since 2026-09-30, superseded
by `projects/anbud`. The spec file is unusually valuable as *measured* operational
knowledge: `POST https://api.ted.europa.eu/v3/notices/search` with
`publication-date>=today(-1) AND buyer-country=NOR AND notice-type=cn-standard`
returned 46 Norwegian notices for one day; adding
`AND classification-cpv IN (48000000 72000000 79000000)` narrowed it to 9. Single-notice
follow-up is `GET https://ted.europa.eu/en/notice/<pub-number>/xml` (~10.7 KB).
It also records that TED returns titles in ~24 languages regardless of the `fields`
parameter (~4 KB/notice, so a `limit:10` response is ~41 KB), that an unrecognised
top-level key is a hard 400, and that `ted.europa.eu/robots.txt` disallows
`/*/search/result?` while `api.ted.europa.eu` is a separate origin with no robots file.
Five other agent specs sit beside it (`konkurs`, `research`, `marked`, `kilder`,
`drift`, `regelverk`, `laering`).

**`market/competitors/` — 29 competitor dossiers** as JSON (Multiconsult, Sweco,
Rambøll, COWI, Asplan Viak, Norsk Energi, Entro, Kiwa, Rejlers, WSP, Varig
Technologies, Sustevo, Kiona, …) — i.e. the energy/consulting field, consistent with
Solar Consulting's actual market rather than generic IT.

**`secure/`** — age-encrypted store (`recipients.txt`, `encrypt.ps1`/`decrypt.ps1`),
currently holding `secure/contracts/Veldora.pdf.age` plus empty `company/` and
`procurement/` directories with READMEs. Not opened.

**`bid-engine/`** — `playbooks/anbudsloypa.md`, `playbooks/kgv-brukere.md`,
`pricing/prismodell.json`. **`scripts/`** — `new.mjs`, `validate.mjs` (schema CI),
`deadlines.mjs`, `pris.mjs`, `schemas.mjs`, `seed-sources.mjs`, `linear-sync.mjs`,
`extract-project.mjs`.

---

## 8. `AS/` — operator's accounting repo

**It is not Solar Consulting.** The company here is **KUKARAJA SIKKERHET (ENK)** —
`scripts/fiken-sync.py` names it in its docstring. `grep -rl "solar consulting"` and
`grep -rl "931949837"` across `AS/` both return zero. Main income is Verisure-related
security work (sales, installations, guard shifts). Last commit 2026-07-21, files
touched to 2026-10-03, 17 commits.

### Categories of data present (locations only — nothing quoted)

| Category | Where |
|---|---|
| Monthly payroll bundles (sales, installations, payslip forms, invoices, driving log) | `Lønn Januar/`, `Lønn februar/`, `Mars/`, `Lønn Mai/`, `Lønn juni/`, `Lønn Juli/`, `docs/Lønn august/`, `september lønn/`, `Lønn oktober/`, `Lønn novembe/`, `Lønn desember/`, `Lønn/` |
| Expense receipts (fuel, meals/diet, flight, phone/equipment) | `Drivstoff kvittering/`, `mat kvittering september/`, several loose PDFs/JPGs at repo root |
| Telecom invoices | `Telenor/`, `Telia/` |
| Rental contracts (3 parties) | `Kontrakt/` |
| Employer contract basis | `Verisure/` (Lønnsmodell-Base-kit, Lønn.xlsx) |
| Tax / VAT correspondence | `Mva-brev …pdf`, `skattemelding_sirius_*.pdf` at root |
| Accounting automation | `scripts/` — Fiken OAuth2 client + sync/dump/summary, reconciliation, voucher catalogue builder, draft-invoice + credit-note creation, payroll-form fillers, dashboard builder |
| Accounting state docs | `docs/` — `regnskap-status.md`, `mva-skatt-action.md`, `frister.md`, `bilag-katalog.md`, `fiken-avstemming.md`, `plan-vs-faktisk.md`, `oversikt.md` |
| Business-plan material | `docs/FORRETNINGSPLAN-1SIDE.md`, `docs/inntekt-strategier.md`, `docs/kapitalprioritering.md` |
| Refi product/business planning | `docs/refi-business/` — pitch deck (md/pptx/pdf), `produkt-arkitektur.md`, `finansmodell.{md,py}`, `go-to-market.md`, `compliance-partnerskap.md`, `partnerskap-struktur.md`, `mulighetsmotor-verdimodell.md` |
| Hardware / on-prem node spec | `docs/hardware/install-runbook.md`, `build-spec.md` |
| ASListen transaction documents | `ASlisten/` (share purchase agreements, EGM protocols, articles of association for third-party companies) |

**Implied project history for Solar Consulting: none.** The invoices and payroll here
document the operator's own security-sector work, not Solar Consulting deliveries, so
they do not feed Veldora's "know our own company" requirement. That requirement is
served by `SC-rename`/Veldora (§7) and, for personnel, by `Søking fulltid` (§9).

### The one genuinely valuable file

**`AS/IT/analyse-medieovervakning-anbud.md`** (written 2026-08-21) — a critical
analysis of a real Norwegian public tender: a media-monitoring kravspesifikasjon for
Akershus, Buskerud and Østfold fylkeskommuner, reconstructed from 13 screenshots of
the buyer's *internal draft* (tracked changes, red guidance text, TendSign). It
decomposes the requirements the way Veldora must learn to:

- **A-krav** (absolute, must be met at bid time) enumerated A1–A15: SaaS, a working
  demo with 3 user accounts tested during evaluation, WCAG, ~300 users, web + iOS +
  Android, same-day/real-time hits, RSS/XML intranet feed, configurable alerting,
  archive, continuously editable search terms, historical back-search. Plus DBA and
  SSA (Statens standardavtaler).
- **E-krav** (scored) with the weighting: Quality 40 % — usability (demo-tested),
  implementation plan, analysis functions, source breadth, SLA.
- A blunt feasibility verdict naming the real blockers — content licensing behind
  paywalls (Opoint/Retriever, several hundred thousand NOK/year), broadcast rights +
  24/7 STT, social-media API costs, and a 20-year historical archive a newcomer
  cannot create retroactively.
- A strategic read on *why we hold the buyer's draft at all* (contact at the buyer, or
  early market dialogue) and that it changes the game.

Two siblings: `IT/etableringsplan-medieovervakning.md`, `IT/plan-medieovervakning-bud.md`.
This is the best worked example in the workspace of "read a Norwegian kravspec and tell
us honestly whether we can win" — use it as a golden test case for Veldora's
requirement-extraction and win-probability output.

`docs/refi-business/produkt-arkitektur.md` is also worth a read: it is the plan for
turning `refi-doc-agent` into a repeatable single-tenant-per-box product, and it
already names the deployment stack (Ubuntu + Docker + Tailscale + Ollama/vLLM + Qdrant
+ Postgres + Caddy) for an air-gapped document-AI appliance. If Veldora ever needs an
on-prem story for a security-conscious public buyer, that document is the draft.

---

## 9. `Søking fulltid/` — CVs and competence evidence

Last commit 2026-07-28 (8 commits); the CV itself was updated **2026-10-03**, so the
*assets* are current even though the automation is dormant. ~384 MB, mostly a 59 MB
video CV and a vendored `.venv`.

### CVs / competence profiles: yes, in several formats

| What | Where | Format |
|---|---|---|
| CV versions V1–V5 | `profil/Nithusan Kukaraja CV V{1..5}.docx` | DOCX, V5 dated 2026-10-03 |
| Engineer resume | `profil/Nithusan Kukaraja - Engineer Resume.pdf` | PDF |
| Sales resume | `profil/Nithusan Kukaraja - Sales Resume.pdf` | PDF |
| General resume | `profil/Nithusan Kukaraja Resume.pdf` | PDF |
| Video CV | `profil/Video cv.{docx,pdf,mp4}` | DOCX/PDF/MP4 |
| **Structured machine-readable profile** | `profil/profile.md` | Markdown, sectioned: Kontakt · Tilgjengelighet · Utdanning (incl. Masteroppgave) · Yrkeserfaring · Ferdigheter · Strategisk posisjonering · Referanser |
| **Skill/keyword taxonomy** | `profil/keywords.md` | Markdown, grouped (ML/AI/data science, materials informatics, materialteknologi, …) |
| Preferences / constraints | `profil/preferences.md` | Markdown |
| **Employment certificates (attester)** | `profil/attester/` | 5 PDFs: Forsvaret, Røde Kors, Sikkerhet 24 Verisure Partner, Sikkerhetsfirmaet, Verisure (Team Leader) |
| **Academic transcripts** | `profil/akademisk/` | 4 PDFs: Karakterutskrift, Transcript, plus two India exchange transcripts |
| Psychometric report | `profil/factor-trait-report_nithusan-kukaraja.pdf` | PDF |
| Cover-letter + CV templates | `maler/cover_letters/`, `maler/cv/` | — |

I did not open the CVs, attester or transcripts; the table above is from filenames and
`profile.md`'s heading structure only.

### Why this matters for Veldora

Norwegian tenders routinely require named key personnel with documented education,
years of relevant experience and verifiable references. `profil/profile.md` +
`profil/keywords.md` are already the structured form of that, and
`profil/attester/` + `profil/akademisk/` are the *documentation evidence* a
kvalifikasjonskrav demands. Feeding these into Veldora turns
`SC-rename/procurement/qualification/qualification-matrix.yaml` rows about key
personnel from `UNKNOWN` into answerable.

### The matching machinery is also reusable

`agent/match_score.py` (226 lines) scores a posting 0–100 against `agent/config.yaml`:
role tiers (+30/+20/+15), a 5-tier geography ladder (Norway 15 → Ireland 12 → Nordics 9
→ UK 7 → EU 5), seed-company bonus, graduate-signal bonus, domain-keyword bonus, and —
the important bit — **hard stop-words in the requirements section force the score to 0**
(senior / PhD / 5+ years). That is structurally identical to a tender's absolute
qualification requirements: a single unmet A-krav zeroes the opportunity regardless of
how well everything else scores. Thresholds are config, not code
(`draft_threshold` 75 → auto-draft, `append_threshold` 40 → shortlist, below → drop).

Rest of the pipeline: `agent/scan_arbeidsplassen.py` (331) and `agent/scan_finn.py`
(212) as source scrapers, `agent/enrich_leads.py` (301), `agent/daily.py` (509) as the
daily orchestrator, `agent/crm_build.py` (740), `agent/soknad/render_letter.py` (162)
generating tailored application letters from the profile + the posting — i.e. the
same "read a requirement, pull matching evidence from our own profile, draft the
response" loop Veldora needs for tender responses. `crm/` adds a small SQLite-backed
tracker with tests.

---

## 10. Ranking by reuse value

1. **`refi-doc-agent`** — the document pipeline, built, tested, Norwegian, with the
   right legal posture. Lift the code.
2. **`SC-rename`** (= Veldora worktree, branch `chore/slack-linear-rename`) — the
   procurement domain model, bid gate, qualification matrix, source dossiers and
   measured TED API knowledge. Make sure the Veldora agent is on that branch.
3. **`Søking fulltid/`** — CVs, attester, transcripts, `profile.md`, `keywords.md`,
   plus the hard-stop match-scoring pattern.
4. **`aslisten-crm`** — `brreg.ts` + MOD11 orgnr validation + deterministic-extract-
   with-optional-LLM pattern. No usable data.
5. **`call-center-ai-demo`** — gold-label eval harness, PII redaction, mock-provider
   discipline.
6. **`leadgen-platform` / `leadgen-mvp`** — pipeline contracts and vertical-profile
   YAML; three-state compliance gate.
7. **`AS/IT/analyse-medieovervakning-anbud.md`** — one file, but the best worked
   example of Norwegian kravspec decomposition in the workspace.
8. **`grossist-plattform`** — licensing/policy/tenant scaffolding, only if Veldora is
   productized.
9. **`Renseri`** — small GDPR-aware lead-intake utilities.
10. **`leadgen-pipeline`** — one script worth keeping.
11. Dead weight: `lavera-site`, `Personlig`, `_refs`, `_logs`, `vendor`,
    `callcenter.js-mcp`, and the two duplicates `cc-leakscan` / `jarvis-wt`.
