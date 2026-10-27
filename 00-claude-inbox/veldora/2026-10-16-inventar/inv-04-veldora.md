# Veldora / Solar Consulting — read-only inventory

Produced 2026-10-16. Read-only pass over `/home/nithu/code/Veldora` + its 24 sibling worktrees.
Epistemic tags below reproduce the repo's own convention (`FACT` / `ASSUMPTION` / `HYPOTHESIS` /
`DECISION` / `TODO` / `UNKNOWN`) and the licensing convention (`GREEN` / `YELLOW` / `RED` / `UNKNOWN`).
Where I state something myself I say so.

---

## 0. First thing to know: the main checkout is stale, and the repo has been renamed

`FACT` — `/home/nithu/code/Veldora` is checked out on branch **`feat/secure-age`** at `c2e0ef6`
(21 Sept), which is **157 commits behind `main`**. Everything described in its `README.md` /
`CLAUDE.md` is a September snapshot. **Do not read the main checkout as current state.**
I used `/home/nithu/code/Veldora-ci` (`900b07c`, one commit past `main` `fae0ddd`) as the
canonical tree for this report.

`FACT` — on `main`, `README.md` is titled **"Solar Consulting"**, not "Veldora", and the website
line says `solarconsulting.no`. ADR-0016 is `ADR-0016-navnebytte-solar-consulting.md`.

`FACT` (from `~/Obsidian/Brain/00-firm-bus/feed.md`, learning-1 2026-10-13T18:59Z, repeated by
admin-1 21:04Z) — the GitHub repo **has been moved to `Nithu0/Solar-Consulting`**, but
`git remote -v` still reads `https://github.com/Nithu0/Veldora.git`. Pushes succeed on GitHub's
redirect, which hides the move from CI and deploy hooks. Flagged as a trap, not fixed.

### Worktree map (verified with `git worktree list`, not guessed)

One repo, 25 human worktrees + 10 agent-created ones under `.claude/worktrees/`.
There is **no `Veldora-bid`** worktree (the task brief guessed one).

| Worktree | Branch | Lane |
| --- | --- | --- |
| `Veldora` (main checkout) | `feat/secure-age` | **stale, 157 behind** |
| `Veldora-anbud` | `fix/anbud-sporsmal` | tender Q&A |
| `Veldora-auto` | `fix/deploy-vercel-git-metadata` | deploy |
| `Veldora-checks` | `infra-1/auto-merge-verifiser-foer-deploy` | CI gate |
| `Veldora-ci` | `trading-1/dedup-fiks` | CI / dedup (newest) |
| `Veldora-dok` | `fix/anbud-dokumentdekning` | document coverage |
| `Veldora-dok-pipe` | `trading-1/dokument-pipe` | document pipeline |
| `Veldora-domene` | `chore/domene-solarconsulting` | domain rename |
| `Veldora-frist` | `admin-1/legal-engine-map` | legal engine + deadlines — **branch is identical to `main`, zero commits** (see §5) |
| `Veldora-gws` | `feat/anbud-whatsapp` | Google Workspace / WhatsApp |
| `Veldora-lanes` | detached HEAD `3bf5142` | — |
| `Veldora-mote` | `fix/migrasjon-down` | meetings / migrations |
| `Veldora-rad` | `strategy/ai-plattform-rad` | AI-platform council |
| `Veldora-radar` | `fix/anbud-solenergi-track-false-positives` | solar track precision |
| `Veldora-radar-verdi` | `anbud/verdi-ekstraksjon` | contract-value extraction |
| `Veldora-research` | `research/myhre-kommentar` | legal commentary |
| `Veldora-ruting` | `tools-1/model-routing-defaults` | LLM model routing |
| `Veldora-scope` | `feat/anbud-scope-categories` | scope taxonomy |
| `Veldora-triage-a..e` | `feat/anbud-triage-{data,learning,veiledning,agents,integrasjon}` | triage |
| `Veldora-union` | `infra-1/union-verify-f4cb3f0` | union smoke-test |
| `SC-rename` | `chore/slack-linear-rename` | (sibling, same repo) |

Agent worktrees under `.claude/worktrees/` carry `feat/034-055…` issue branches.
`FACT` (orchestrator-1, feed 2026-10-13T08:39Z): **42 worktrees / 137 branches / 4.5 GB**, growing
during the session. "Nothing has a lifecycle — agents create, nobody cleans." Deletion is operator-gated.

---

## 1. What Veldora is today

### Product thesis — two theses, one superseded in practice but not in writing

`HYPOTHESIS` (still in `README.md` and `strategy/company-thesis.md` on `main`):
"AI-driven information flow for the public sector — help public bodies collect → understand →
structure → find → monitor → analyse → distribute → act on information", with three pillars
(Document & AI, Monitoring & Intelligence, Digital Interaction) plus exam-lockdown off-thesis
(ADR-0001, ADR-0003). Target contract band **300k–1.5 MNOK**, deliberately *below* the EEA threshold.

`DECISION` (ADR-0015, 2026-10-03) — **the real direction is solar + IT ops, bidding as
Solarconsulting AS.** The ADR itself says, verbatim:

> **Strategien er ikke oppdatert.** `company-thesis.md`, `positioning.md` og `roadmap.md`
> beskriver fortsatt Veldora som et selskap for AI og informasjonsflyt i offentlig sektor.
> Retningen er nå valgt: sol pluss IT-drift. … `TODO` — oppdater dem med henvisning hit.

**My read:** `strategy/` is the most stale part of the repo and should not be fed to any model
as a statement of what the company does. Corroborating evidence: `market/competitors/` holds
**33 competitor JSON files and every one is a solar/energy consultancy** (Multiconsult, Norconsult,
Sweco, Rambøll, AFRY, Asplan Viak, COWI, Solenergi Fusen, Entro, Kiona, …) — zero IT competitors.
The competitor data already pivoted; the strategy prose did not.

`UNKNOWN` (stated in ADR-0015 itself) — whether "Veldora" exists as a company at all. Veldora is
now the name of the internal work (this repo + the platform), not a bidder.

### Where the code lives

The September `CLAUDE.md` says "code lives in product repos" — **that is stale**. `main`'s
`CLAUDE.md` corrects it:

> This is **primarily not a software repo**. … It does contain code. Products live as directories
> under `projects/`, not in separate repos (ADR-0004). The largest is `projects/anbud`, a live
> tender platform and team CRM (ADR-0014).

`FACT` — `projects/` contains exactly three: `anbud/` (**1291 files**, the real system),
`monitoring/` (README + CLAUDE.md only), `examlock/` (README + CLAUDE.md only).
There are **no separate product repos**. `scripts/extract-project.mjs` exists for a future split.

### Architecture (the live system)

`projects/anbud/` — contract is `projects/anbud/ARCHITECTURE.md` (~2600 lines, "change it before
the code"):

- `crm/` — **Payload 3 + Next 15 + Postgres 18**. Admin UI, REST, and the worker (same image, two
  start commands). The scrapers and all agents live here. ~57 collections, 11 globals.
- `dashboard/` — Next 15 on Vercel. Team-facing views.
- Deploy: Railway project `anbud`, EU West (Amsterdam) — `Postgres`, `crm` (volume `/data`),
  `worker`. Dashboard on Vercel team `veldora2`, project `anbud-veldora`.
- Live URLs in the README: `https://anbud-veldora.vercel.app`,
  `https://crm-production-ef9b.up.railway.app/admin`, health at `/api/health`.
- `ACTIVE` — live since **2026-09-30** with TED + Doffin.
- Production watchdog `projects/anbud/scripts/vakt.sh` as systemd user unit `anbud-vakt`,
  writes to `Brain/00-firm-bus/feed.md` only when something is wrong.

### Current slice/phase

`strategy/roadmap.md` still says "Phase 1 is manual on purpose". That is **stale**. Reality:
the platform is in production, numbered issues `011`–`055` are the working queue
(`issues/`), and three PRDs exist (`prd/bedriftsautomatisering.md`,
`prd/juridisk-assistent.md`, `prd/kvalifikasjonslag.md`). Development moves by
`scripts/ship.sh` → PR → auto-merge bot → auto-deploy (ADR-0012).

**My read:** the repo is in a "live product, unrevised strategy docs" state. The gap between
`strategy/` and `projects/anbud/` is roughly a year of direction.

---

## 2. The bid engine

### `bid-engine/` the directory — thin

`FACT` — **5 files total**: `README.md`, `playbooks/README.md`, `playbooks/anbudsloypa.md`,
`playbooks/kgv-brukere.md`, `pricing/README.md`, `pricing/prismodell.json`. The README promises
`scoring/`, `requirements/`, `templates/` — **none of those directories exist.** It is a doc shell.

`bid-engine/pricing/prismodell.json` (`sist_oppdatert` 2026-10-03, `selskap: "Solarconsulting AS"`)
is input to `scripts/pris.mjs`. Its own design is that `UNKNOWN` halts the calculation. Current state:

- `FACT` rates are filled: feriepenger 12 %, arbeidsgiveravgift 14.1 % (sone I, with sources + `hentet` dates), OTP 2 %.
- **Everything company-specific is `UNKNOWN` / `TODO`, owner "daglig leder"**: annual salary,
  stillingsprosent, other personnel costs, billable hours per FTE, profit %, fixed-price risk
  markup, software costs, liability insurance, accounting, office.

So the company cannot currently compute its own hourly cost. That is a company-self-knowledge gap
as much as a pricing gap.

### The real scoring engine — `projects/anbud/crm`

Two models, both real TypeScript with tests:

**Fit** — `crm/src/lib/scoring/fit.ts` + `crm/src/config/verticals.ts`.
`FIT_POINTS` (all marked `ASSUMPTION — tune`): CPV max 50, keyword 6/hit (title counts double,
cap 35), negative keyword −12 (cap 40), value-in-range 10, preferred buyer 5, **own product +15**.
`NO_FIT` below 20. Verticals are `it` and `solar-energy`; `PRODUCTS` are `monitoring-intelligence`
and `exam-lockdown`; `WATCH_SEGMENTS` (laundry/textile, food wholesale/poultry, cleaning, glass
railings) are counted in market analysis but never produce an opportunity.

`CAPACITY` (`crm/src/config/verticals.ts:188`):
`maxContractValue` 10 MNOK (`DECISION` operator 2026-09-30; soft gate since 2026-10-03, focus band
2–10 MNOK), `minContractValue: null`, `excludedProcedures: ['dps']`,
`preferredBuyerTypes: ['kommune','fylkeskommune','interkommunalt']`, static FX
`{NOK 1, EUR 11.5, SEK 1.0, DKK 1.55}` — all `ASSUMPTION — tune`.

**Win probability** — `crm/src/config/model.ts`, model **`wp-2`**:
weights `fit 1.2, coverage 1.0, incumbent −0.8, relationship 0.6, deadlinePressure −0.5,
hardGate −2.0`; clamp 0.01–0.95; baseRate `shrinkageK 5, fallbackBidders 4`. Header comment:
*"The weights are the contract's initial guesses — ASSUMPTION — tune against `predictions` once
outcomes exist."* Changing a weight requires bumping `winModelVersion` or calibration is poisoned.

**Qualification gate** — two implementations.

**(a) `automation/lib/bid-gate.mjs`** — ~2100 lines, Node stdlib only, zero runtime deps
(`CONTRACT.md` §2). Spec is `procurement/qualification/bid-gate.md`; the two are meant to be read
together ("prosaen begrunner valgene, koden håndhever dem").

*Inputs.* `assessBid(input, matrix)` where `matrix` comes from `loadMatrix()` reading
`procurement/qualification/qualification-matrix.yaml`, and `input` is
`{ competition, requirements[] }`. From `competition` it derives two things before anything else:
`derivePart()` (estimated value incl. options and the full framework period per FOA § 5-4 (5),
buyer type, contract type → `utenfor-FOA` / `I` / `II` / `III` / `IV` / `UNKNOWN`) and
`deriveProcedure()`.

*Outputs.* A **frozen** result object: `outcome`, `part`, per-requirement `requirements[]`,
`questions[]` (each with `what`, `owner`, `ask_in_competition`, `requirement_id`), `standing`,
`always`, `selection`, `procedure`, `unknowns[]`, `extraDecisions[]` — and `bid_no_bid`.
`OUTCOMES` is an ordered ladder: `QUALIFIED` → `QUALIFIED_WITH_SUPPORTING_ENTITY` →
`QUALIFICATION_RISK` → `REQUIRES_CLARIFICATION` → `NOT_QUALIFIED`.

*Two aggregation rules, and they go opposite ways.* `better()` is used **within** one requirement
(one passable route is enough). `worse()` is used **across** requirements, because qualification
criteria are minimum criteria and one failed criterion rejects the whole bid — the gate cites the
rejection chapters for this (§ 24-2 (1) a in Part III, § 9-5 (1) a in Part II), not the
qualification chapters.

*Two design rules that shape everything:*
1. **VALUE → PART → RULESET → ASSESSMENT, in that order.** The rules on qualification criteria are
   not the same in Parts I, II and III, so a rule applied in the wrong Part *"er en felle og ikke
   et argument"*. If the Part cannot be established the gate **stops and returns
   `REQUIRES_CLARIFICATION` with an action**, not an error — and it never guesses a Part from a
   value it does not have. Part IV is a *known* Part the package does not cover, and stops it too,
   with its own reason.
2. **A requirement is a chain of routes, not a checkbox.** If a competition demands three
   references and Solar Consulting has none, the answer is **not** `NOT_QUALIFIED` until the key-
   personnel, alternative-evidence, supporting-entity, subcontractor and consortium routes have all
   been tried. Each route carries a `ROUTE_STATUS` — `AVAILABLE`, `AVAILABLE_WITH_CONDITIONS`,
   `BUYER_DISCRETION` (the route exists but the buyer decides whether it opens), `UNKNOWN` (the
   legal basis itself is unsettled, so *"har ruten en eier, ikke et svar"*), `UNAVAILABLE`,
   `NOT_APPLICABLE`. Classification comes after the chain, never instead of it. The header names
   the failure mode it exists to prevent: *"et falskt NOT_QUALIFIED er nøyaktig feilen denne porten
   finnes [for]"*.

*Why `bid_no_bid` is always null.* `DECISION`, ADR-0011, option (a). The field exists in the
returned struct, is always `null`, and **no line in the module sets it**. The header explains the
reasoning: `CLAUDE.md` §10 and `CONTRACT.md` §5 already say "AI proposes, humans decide" in prose,
*"men en regel som bare finnes i prosa forsvinner den dagen noen har dårlig tid"* — so it is
encoded as a data structure instead. Setting it requires a human outside the module, where it is
visible who did it. Everything the gate derives is `ASSUMPTION`, never `FACT`; the only facts in
the result are the ones carried from the matrix with legal basis and retrieval date.

The one fact the gate deliberately duplicates is the threshold values (`THRESHOLDS`: FOA floor
500 000, Part II floor 1 300 000, …) — the Part cannot be derived without comparable numbers, and
the matrix carries them only as prose in `QUAL-DOC-014`. The duplication is made auditable rather
than invisible: a test reads `QUAL-DOC-014` and fails if the numbers here drift from that row's
`verbatim`.

**(b) `crm/src/lib/qualification/`** + the `qualification-assessments` collection (issue 001) — the
live per-requirement verdict engine running in production, with `requalify`, Brreg TTL,
second-pass, clarify, the evidence vault and a readiness checklist. This is the one the team
actually uses; (a) is the reference implementation of the legal reasoning.

**Agent tasks** (`crm/src/jobs/tasks/`, ~58 files, each with tests):
`ingest-doffin`, `ingest-ted`, `ingest-kofa`, `ingest-lovdata`, `enrich-buyer`, `awards-backfill`,
`scan-news`, `classify`, `extract-requirements`, `qualify-requirements`, `assess-requirements`,
`refresh-assessments`, `requalify`, `score`, `challenge`, `red-team`, `draft-bid`, `draft-reply`,
`contract-review`, `tender-brief`, `brief-coverage`, `deadline-sweep`, `morning-briefing`,
`news-digest`, `postmortem`, `calibration-backtest`, `parse-cv`, `ingest-answer`,
`learn-preferences`, `scope-backfill`, `verdi-backfill`, `stats`, `heartbeat`, `notify-email`,
`sync-workspace`, `analyser-energidata`, `rapportutkast`, `fakturakladd`, `score-prospekter`,
`referanseforesporsel`, `avstemming`, `slett-utloept-tekst`, `messages`.

### How well does it actually work? — measured, and the answer is sobering

`FACT` — `~/Obsidian/Brain/00-claude-inbox/Veldora/2026-10-13_triage-grunnlinje.md`, measured
read-only against production 2026-10-13T08:42Z on code `6cc89c2`
(reproduce: `projects/anbud/crm/scripts/baseline/run-triage-baseline.sh`):

- 1750 notices ingested → 907 opportunities → **758 queue-eligible**.
- **105 human decisions total**: 30 yes (24 STRONG_BID + 6 BID), 69 no, 6 investigate.
  Base rate for yes = 30/99 = 30.3 %.
- Labels are **two work sessions, not a time series** (11.10 → 72, 12.10 → 24, 13.10 → 7).
- `agent_verdict` calibration labels: don't-know 45 · right 25 · too-high 24 · too-low 10
  → **59 directional labels that no code reads.**
- Average operator time per decision: INVESTIGATE 621 s · BID 249 s · NO_BID 207 s · STRONG_BID 156 s.
  One false positive in the queue costs ~3.5 minutes.

`FACT` (learning-1, feed 2026-10-13T08:34Z, same production measurement):
**fitScore AUC 0.577 · priorityScore 0.549 · winProbability 0.575 — not distinguishable from a
coin flip at n=30. `scope_score` 0.678 is the only measurable signal.**

Scope-category filtering (counterfactual — it is not a filter today, only an optional `?kategori=`,
off by default, `lib/triage.ts:367`): would cut 48/69 no and lose 4/30 yes (13.3 %), precision
26/51 = 51.0 % vs base 28.6 % → **lift 1.78×**, recall 86.7 %, saving ~2.8 h per 105 cases.
89.2 % of the queue is `utenfor-scope`.

**My read: the bid engine is a well-engineered, heavily tested, production-deployed pipeline whose
scoring is currently no better than chance.** The architecture is real; the *intelligence* is not
yet calibrated, and the thing that would calibrate it — labelled outcomes and company-specific
knowledge — is exactly what's missing (see §3).

### Open issues directly on the engine

- `issues/054-maalvariabel-dialog-vs-konkurranse.md` — the target variable itself is unresolved.
  learning-1 (feed 13.10): *"gater ALT rangeringsarbeid, urørt siden 13.10 — dyrest å miste."*
- `issues/055-profilen-teller-feil-mot-30-terskelen.md`
- `issues/050-scope-kategorier.md`, `051-solenergi-null-treff.md`, `053-dialoger-og-rfi.md`
- `awards` has 552 rows but **only 54 with an amount** — criterion 3 for ranking cannot be decided.
- `FACT` (tools-1, feed 2026-10-14T11:56Z): **13 opportunities have no brief at all, and all 13 are
  decided (7 STRONG_BID, 4 BID, 2 INVESTIGATE)** — `queueWhere` requires `UNDECIDED`, so coverage
  never reaches them. The tenders we said yes to are the only ones without background data.
  6 of 7 STRONG_BID also lack a deadline.

### The other knowledge directories — all shells

| Dir | Files | Reality |
| --- | --- | --- |
| `procurement/` | README only outside `qualification/` | `qualification/` is the substance: 12 files, 7937 lines |
| `automation/` | 85 files | **Real.** 8 agents (`anbud`, `drift`, `kilder`, `konkurs`, `laering`, `marked`, `regelverk`, `research`) as `.md`+`.json` pairs, 10 checks with tests, a Slack responder, `lib/` with tests. `anbud.json` is `PAUSED` (superseded by the live platform). Agents open PRs, never merge. |
| `data/` | 30 files | 14 source JSONs, 17 schemas, `data/legal/terskelverdier.json` (`FACT`: deliberately **empty** — admin-1 feed 13.10: "financial-capacity.md:915 forbids copying the values into a template"), licensing README |
| `research/` | 34 files | `energikartlegging/` is a serious 12-part study (regelverk, kompetansekrav, marked, konkurrenter, prising, upsell, prospekter, risiko, sertifiseringer, anbud, leveranse, dokumenter) + structured JSON/CSV; plus `2026-09-23-solarconsulting-erverv-og-solmarkedet.md` and `open-questions.md` |
| `market/` | 36 files | 33 solar/energy competitor JSONs + 3 READMEs. **No buyers, no sizing, no trends** despite the README promising them |
| `legal/` | 3 files | `procurement/qualification-requirements.md` + 2 READMEs |
| `verticals/` | 5 READMEs | shells |
| `product/` | 1 README | shell |
| `sales/` | **1 README** | shell. `sales/cases/` — the directory `reference-cases.template.yaml` points to as the home for finished reference records — **does not exist** |
| `projects/` | README + 3 subdirs | only `anbud/` is real |
| `strategy/` | 5 docs + `proposals/` (3 dated proposals) | the 5 core docs are stale per ADR-0015; the proposals (2026-10-05 anbud-plattformstrategi, 10-08 automatisering-solarconsulting, 10-12 tre-scopes) are current |

---

## 3. Company self-knowledge about Solar Consulting AS — **THE KEY QUESTION**

**Verdict: the machinery is excellent and the content is close to empty.** The repo has a
well-designed, well-tested, production-deployed *container* for company knowledge, a working
import pipeline into it, and an interview system to fill its gaps. What it does not have is the
knowledge. Almost everything the bid engine would need to argue "we can do this, here is proof"
is either `UNKNOWN`, deliberately held outside git, or written about a different company.

### 3a. What exists as schema (rich)

`projects/anbud/ARCHITECTURE.md` §5 "Capability bank (kompetansebank)" defines, and the code
implements, a complete model:

| Collection | File | Holds |
| --- | --- | --- |
| `people` | `crm/src/collections/People.ts` | name, title, summary, `yearsExperience`, `skills[]{name,years,level}`, `certifications[]{name,year}`, `roles[]`, `education[]`, `sectors[]`, `languages[]`, `availability`, **`consent`** (default **false** — consent to use the CV in bids), `cvUpdatedAt` |
| `cvs` | `crm/src/collections/Cvs.ts` | upload + `extractedText`, `cvDate`, `current`, `fileHash` (sha256, idempotent import) |
| `references` | `crm/src/collections/References.ts` | title, customer, `periodFrom/To`, **`valueNok`**, `durationMonths`, `capabilities[]`, `technologies[]`, people, `ourRole` (`prime \| subcontractor \| personal`), **`mayCitePublicly`**, `contactAvailable`, `verticals` |
| `customers` | `crm/src/collections/Customers.ts` | name, orgNumber, kind, relationship |
| `capability-facts` | `crm/src/collections/CapabilityFacts.ts` | free-text `statement`, `topics[]`, **`polarity: have \| partial \| lack`**, `validUntil` |
| `interview-questions` | `crm/src/collections/InterviewQuestions.ts` | the gap-filling loop; answers flow `ingest-answer` → `capability-facts` |
| `evidence` | `crm/src/collections/Evidence.ts` | qualification evidence, attestation references, confirmation status (issue 001/004) |
| `qualification-assessments` | `crm/src/collections/QualificationAssessments.ts` | per-requirement verdicts |
| `supplier-profile` (global) | `crm/src/globals/SupplierProfile.ts` | orgnr, name, accepted credit ratings, rating scale, doc max age, **signatories**, supporting entities (FOA § 16-10) |

Retrieval into the LLM (`crm/src/lib/bank.ts`): deterministic **idf-weighted token overlap** with
light Norwegian stemming and a procurement stopword list; the LLM only judges the top
`EVIDENCE_TOP_K = 8` candidates. Governing rule, in the file header: **"no evidence ⇒ UNKNOWN"**.
Agents never overwrite a human-edited non-empty field (`mergeAgentPatch`).

`draft-bid`'s rule, from `projects/anbud/README.md`:
> Erfaring, personer og referanser hentes **bare** fra kompetansebanken, med kilde; det som mangler
> står som «Mangler dokumentasjon». Personer uten samtykke tilbys ikke.

That is the right design, and it means **an empty bank produces a bid full of "Mangler dokumentasjon".**

### 3b. What exists as content (thin — this is the gap)

**The capability bank's real content is deliberately outside git and does not exist on disk.**

`projects/anbud/crm/kompetanse-mappe.example/README.md` is the *only* file in that directory:
> Den ekte mappen ligger **utenfor git** (foreslått: `~/Solar-Consulting-kompetanse/`) — den
> inneholder personopplysninger og skal aldri sjekkes inn.

`FACT` (I checked): **`~/Solar-Consulting-kompetanse/` does not exist on this machine.** No CVs,
no reference YAMLs, no customer files have ever been staged for import here.
Importer: `crm/scripts/import-capabilities.ts` / `npm run import:kompetanse` — real, idempotent
(person by name, CV by file hash, reference by title, customer by orgnr), local or remote mode.

`UNKNOWN` — whether the production Railway database has any rows in `people` / `references` /
`capability-facts`. I could not check read-only without a Railway link. Indirect evidence that it
is sparse: 168 `judge.assess` calls died silently on HTTP 400 between 8.–11. Oct (tools-1,
`2026-10-13_tools-1-bolge0-modellruting.md`), and no measurement report in
`~/Obsidian/Brain/00-claude-inbox/Veldora/` ever quotes a bank row count. **Worth checking first
before any training work.**

**Hard-coded company knowledge in git — the complete list:**

1. **Org number.** `OUR_ORG_NUMBERS=931949837` (Solarconsulting AS, verified in Brønnøysund), set
   as a Railway env var. In git it appears only in `projects/anbud/README.md` and in test fixtures
   (`crm/scripts/smoke-*.ts`, `crm/src/lib/qualification/*.test.ts`).
2. **Four signatories.** `crm/src/lib/tilbud/signatories.ts` → `DEFAULT_SIGNATORIES`:
   Baber Ahmad, Nithushan Kukaraja, Alper Adiyaman, Tin Tun Naing. Seeded from the 2026-10-06
   interview. This is the only named-person data in the repo.
3. **Three website team entries.** `website/content/team.ts` — added 2026-10-04 with consent, under
   strict content rules: *no client or employer names, no numbers with units, no certifications,
   no solar-experience claims, no delivery claims in present tense*; bios are two sentences; CVs
   never enter the repo; photos need separate written consent (none yet, `photo: null`).
4. **Five customer quotes.** `website/content/solarconsulting-inventory.md` §6 — see below.
5. **NACE code** `71.129` (`research/energikartlegging/data/sertifiseringer.json`).

#### `website/content/solarconsulting-inventory.md` — the single richest company file (310 lines)

`FACT`, source = the company's own old website, retrieved 2026-09-24 with curl. This is the one
place the repo actually describes what Solar Consulting *does*:

- **Legal name / orgnr / contact**: Solarconsulting AS, 931 949 837. Address on the site
  (Nygaardsgata 33, Fredrikstad) marked **utdatert** — the registered address is Nannasvei 12,
  1654 Sellebakk per the 2026-09-25 general-meeting protocol.
- **Four services, in full prose with bullet lists**: Kalkulasjoner (energy reports, production
  estimates, layout/3D, price guidance), Forprosjektering (site analysis, system layout, load
  calculations, inverter dimensioning, string plan, ROI & LCOE, risk analysis), Prosjektledelse
  (from planning to handover, budget, applications, fire guidance, FDV documentation, final
  inspection), Rådgivning (needs analysis, supplier negotiation, QA of material and installation,
  battery/storage integration).
- **Four values**: Kundeorientert, Sikkert, Tillitsfull, Lønnsomt.
- **Five written references (§6)** — quotes only, with name + organisation:
  1. Fredrik Tusvik Helle, El 24 Ensiko AS — project management, solar installations. Year `UNKNOWN`.
  2. Are Andersen, Norway Solar — design of commercial-building solar. Year `UNKNOWN`.
  3. Knut-Erlend Rosvold, Suncel/Hasselsolar/Provitaz — consultant. Year `UNKNOWN`.
  4. Jarle Sølyst, Sastech AS — pre-project through completion/operation. Year `UNKNOWN`.
  5. **Rakel Ljung, Sauda kommune** — consultant on a procurement of solar for municipal housing:
     wrote the technical specification and helped evaluate the bids. **The only public-sector
     reference, and the only one describing a concrete engagement in detail.**
  The file states plainly: *"Det finnes **ingen prosjektliste** (kunde/år/beskrivelse), ingen
  kundelogoer og ingen bilder knyttet til referansene."*
- **§7 Sertifiseringer: "Ingen."** No certifications, approvals, memberships or industry bodies are
  named anywhere. Tools mentioned in articles: PVsol, PVsyst — as mentions, not certifications.
- **§5 Team: no team page, no named employees.** The only person named is "Wafa" (first name only),
  in the Norway Solar quote. Role, surname, photo: `UNKNOWN`.
- **§13 open question 5, unanswered:** *"Referanser med år/beskrivelse. Gammel side har bare
  sitater. Har du en prosjektliste (kunde, år, hva) som kan brukes?"* Operator answer 2026-09-24:
  **"Ingen prosjektliste."**
- **§13 open question 6, consent:** the five quotes were published by the previous owner.
  `website/content/references.ts` supersedes the earlier "consent carried over" note — each person
  is asked again before the new site ships, and a quote renders only when `consentConfirmed` is
  true. Until then the section hides itself. `logos` and `cases` arrays are **empty**.

#### `research/open-questions.md` — what the operator has and has not answered

| Q | Status |
| --- | --- |
| A1 hours per person per week | `UNKNOWN` |
| A2 runway | `UNKNOWN` |
| ⚠️ A3 registered? accounts? auditor? | `FACT` — Solarconsulting AS, 931 949 837, bought from Nielve AS 2026-09-24. Annual accounts in place (operator 2026-10-03). **Auditor `UNKNOWN`** |
| ⚠️ A4 any public reference? | `FACT` — **Yes, in solar: Sauda kommune.** One of five written references. **None in IT** |
| A5 can we carry liquidated damages / response-time obligations? | `UNKNOWN` |
| **B1 has anyone run a public tender end to end?** | `FACT` — **No. Nobody on the team has ever submitted a public tender bid.** (operator 2026-10-03). This invalidates the "Practical IT tender experience" row in `company-thesis.md` |
| B2 municipalities where we have a way in? | `UNKNOWN` |
| ⚠️ B3 realistic win rate for an unknown supplier, 300k–1.5 MNOK | `UNKNOWN` — flagged as "worth more than three weeks of research"; B1 means nobody can answer it from experience |
| B4 do we have Mercell or paid alerting? | `UNKNOWN` |

#### `procurement/qualification/qualification-matrix.yaml` — 3008 lines, **69 rows**, the closest thing to a self-assessment

Each row is one qualification requirement, with 17 fields: `id` (`QUAL-<CATEGORY>-NNN`), `category`
(registration / economic / technical / documentation / security / …), `instrument`,
`requirement_trigger` (`ANBUDSSPESIFIKK` vs fixed), **`foa_del`** (I / II / III — the part marker;
the README says *"En regel uten del-markør er en feil"*), `requirement` (the rule in Norwegian),
`legal_basis` (e.g. `FOA § 16-2 (1)`), `mandatory_or_optional`, `when_applicable`, `documentation`,
**`our_status`**, **`gap`**, `action`, `owner`, `priority` (P1–P3), `can_use_supporting_entity`,
`notes`, and `source[]` with `url` + `retrieved` + `citation`.

**`our_status` distribution across the 69 rows (counted):**

| Status | Rows |
| --- | --- |
| `YELLOW` | 23 |
| `RED` | 21 |
| `NOT_APPLICABLE` | 15 |
| `GREEN` | **5** |
| `UNKNOWN` | 3 |
| `PARTNER` | 3 |

**Five green rows out of 69.** All legal sources carry `retrieved: 2026-09-09`. Header warning, verbatim:

> Budgiver: Solarconsulting AS fra 2026-10-03 (ADR-0015). `our_status` gjelder Solarconsulting AS.
> **Gap-tekster som ikke er datert 2026-10-03 ble skrevet for Veldora og må leses på nytt**
> (TODO, eier: daglig leder).

Sampled rows:

| Row | Status | Note |
| --- | --- | --- |
| QUAL-REG-001/002 registration | `GREEN` | fetch a fresh firmaattest from Brreg |
| QUAL-ECON-001/002 turnover requirement | `RED` | **text still describes Veldora** ("stiftet 2026, ingen avlagte årsregnskap") — not re-read for Solarconsulting |
| QUAL-ECON-003/004 financial-standing annex | `YELLOW` | the annex does not exist |
| QUAL-ECON-005 annual accounts | `GREEN` | updated 2026-10-03 per ADR-0015 |
| QUAL-ECON-006/007 credit rating | `RED` | still Veldora text |
| **QUAL-ECON-008/009 liability insurance** | `RED` | updated 2026-10-03: *"ansvarsforsikring er ikke tegnet ennå, men skal tegnes. Fortsatt det billigste og raskeste gapet å lukke."* |
| QUAL-ECON-010 tax certificate | `YELLOW` | no routine to fetch it; whether the company has arrears is **not verified in the repo** |
| QUAL-ECON-012 turnover in the contract's field | `RED` | *"Veldora har null omsetning innenfor IT-området"* — per ADR-0015 this is still true for IT |
| **QUAL-TECH-001/002 references** | `YELLOW` | updated 2026-10-03: *"referanser finnes innen sol. CV-er og kompetansematrise er på vei, ikke ferdige. For IT-kontrakter gjelder gapet fortsatt."* |
| QUAL-TECH-005 team capacity | `YELLOW` | *"Teamet er selskapets sterkeste kapasitet — AI-utvikling i produksjon hos en ekstern oppdragsgiver, app- og frontend-utvikling fra IT-konsulentbransjen, full stack…"* |

ADR-0015's own status table (operator, 2026-10-03):

| Krav | Status |
| --- | --- |
| Referanser | Finnes |
| Årsregnskap | Fikset |
| **CV-er og kompetansematrise** | **På vei** |
| **Ansvarsforsikring** | **Ikke tegnet ennå, skal tegnes** |
| Kvalitetssystem + informasjonssikkerhetsrutiner | Utkast skrevet 2026-10-03, **ikke vedtatt** |

#### Pricing / capacity / win-loss

- **Pricing**: `bid-engine/pricing/prismodell.json` — every company-specific number `UNKNOWN`.
  `research/energikartlegging/data/pakker-og-okonomi.json` is a *modelling* exercise
  (`EXPERIMENTAL`, explicit `epistemic_status: ASSUMPTION unless a field states a source`):
  founder gross salary 750 000 assumed, 1760 available hours (`FACT` from RIF, corrected because it
  includes lunch), internal cost 504 NOK/available hour, max billable utilisation 0.55. These are
  **assumptions about a hypothetical three-founder company**, not the company's actual numbers.
- **Certifications**: `research/energikartlegging/data/sertifiseringer.json` is a genuinely good
  *roadmap* — a prioritised catalogue (`MÅ_LOV`, `ANBUD_VANLIG`, `TROVERDIGHET`, …) of what to
  acquire NÅ / 6_MND / 2_3_ÅR / VED_BEHOV, with primary Lovdata + NVE sources and retrieval dates.
  But it records **what to get, not what is held.** Held certifications: none recorded anywhere.
- **Win/loss history**: `FACT` — none exists, because B1 says no tender has ever been submitted.
  `postmortem` and the `predictions` / Brier calibration machinery are built and waiting for data.
  The 59 `agent_verdict` calibration labels that do exist are read by no code.
- **Reference cases as structured data**: `procurement/qualification/reference-cases.template.yaml`
  is a **template containing zero references**, by design, with its own explanation:
  *"Veldora har ingen per 2026-09-09, og en oppdiktet referanse i denne filen ville være verre enn
  en tom fil, fordi den ville bli brukt."* The target directory `sales/cases/` does not exist.

### 3c. Blunt summary of the gap

| Dimension | State |
| --- | --- |
| Legal identity (orgnr, address, signatories, accounts) | **Good** — scattered across ADR-0015, inventory §1, `signatories.ts`, but present |
| Services offered | **Good** — inventory §3, four services in detail (solar only) |
| Named references | **Weak** — 5 quotes, names + orgs, **no year, no value, no scope, no project list** |
| Public-sector reference | **One** — Sauda kommune, and it is exactly the right kind (spec writing + bid evaluation) |
| Structured reference cases (FOA § 16-6: value, date, recipient) | **Zero** |
| CVs / people / skills | **Zero in repo, zero on disk.** Schema + importer ready, folder never created |
| Certifications held | **Zero** (inventory §7: "Ingen"). Roadmap of what to get exists |
| Insurance | **Not purchased** |
| Quality system / infosec routines | **Draft 2026-10-03, not adopted** |
| Pricing / cost base | **All `UNKNOWN`** |
| Capacity (hours, utilisation, concurrent projects) | **All `UNKNOWN`** |
| Win/loss history | **Zero — never bid** |
| Tender experience | **Zero — B1 `FACT`: nobody on the team has ever submitted one** |
| Qualification self-assessment | **Exists and is good** (3008-line matrix) but **~two-thirds of gap texts still describe Veldora, not Solarconsulting** |

**My read:** this is the cleanest possible setup for the operator's "train it on the company" goal.
The ingestion path is built, tested, idempotent, consent-aware and provenance-tracked. The right
first move is not to write knowledge into the repo (the repo's own rules forbid most of it — no
personal data, no invented facts) but to **populate `~/Solar-Consulting-kompetanse/` and run
`npm run import:kompetanse`**, then answer the open interview questions in `/intervju` so
`ingest-answer` writes `capability-facts`. Second move: re-read the ~2/3 of
`qualification-matrix.yaml` gap texts that still describe the old company. Third: turn the five
quotes into structured reference cases with value / date / recipient, which is what FOA § 16-6
actually asks for and what `draft-bid` needs.

---

## 4. Data sources + legal posture

### Sources registered in `data/sources/` (14 JSONs)

Licensing convention (`CONTEXT.md`): `GREEN` permitted · `YELLOW` probably/narrowly · `RED` not
usable commercially · `UNKNOWN` **not yet investigated — the default**.
`CLAUDE.md` §7 keeps five properties strictly separate and forbids collapsing them:
`technically fetchable` · `legal to store` · `legal to analyse` · `legal to show a customer` ·
`licensed for commercial redistribution`. `data/sources/README.md`: *"Never collapse technically
fetchable into legally usable. They are different fields for a reason."*

Staleness policy is enforced in code — `automation/checks/stale-sources.mjs`: **warn at 30 days**
since `provenance.retrieved`, **fail at 90 days**, measured against rights fields still `UNKNOWN`.

| Source | What | `technically_fetchable` | `licence_status` | Rights (storage/analysis/redistribution/ai) | Auth | Retrieved |
| --- | --- | --- | --- | --- | --- | --- |
| `doffin.json` | Doffin notices (DFØ) | `YELLOW` — front end is a JS shell; real API behind Azure APIM, registration + subscription key | `UNKNOWN` | all `UNKNOWN` | key-gated, `UNKNOWN` | 2026-08-30 |
| `ted.json` | TED (EU) | `GREEN` | `UNKNOWN` | all `UNKNOWN` — EU's own CC-BY-4.0/CC0 claim **does not auto-flip** to GREEN ("that is a jurist assessment") | none | 2026-08-30 |
| `brreg.json` | Brønnøysundregistrene | `GREEN` | `YELLOW` (NLOD 2.0 claimed by API docs, unverified for commercial reuse) | all `UNKNOWN` | open REST none; `/autorisert-api/` needs Maskinporten | 2026-08-30 |
| `lovdata.json` | Stiftelsen Lovdata | `YELLOW` | `UNKNOWN` | **redistribution `RED`**, rest `UNKNOWN` | mixed (open + paid Lovdata Pro) | 2026-08-30 |
| `robertmyhre.json` | Procurement-law blog (foa.no) | `GREEN` | `UNKNOWN` | **redistribution `RED`**, rest `UNKNOWN` | none | **2026-10-09 (fresh)** |
| `schibsted.json` | Schibsted Media | **`RED`** — full fetch block | `UNKNOWN` | all `UNKNOWN` | `UNKNOWN` | 2026-08-30 |
| `amedia.json` | Amedia AS | `GREEN` | `YELLOW` | all `UNKNOWN` | `UNKNOWN` | 2026-08-30 |
| `polaris.json` | Polaris Media ASA | `GREEN` | `UNKNOWN` | all `UNKNOWN` | `UNKNOWN` | 2026-08-30 |
| `arkivverket.json` | Nasjonalarkivet/Digitalarkivet | `YELLOW` (nasjonalarkivet.no 403, digitalarkivet.no 200) | `UNKNOWN` | all `UNKNOWN` | `UNKNOWN` | 2026-08-30 |
| `stortinget.json` | data.stortinget.no | `GREEN` | `UNKNOWN` | all `UNKNOWN` | none | 2026-08-30 |
| `regjeringen.json` | regjeringen.no | `GREEN` | `UNKNOWN` | all `UNKNOWN` | none | 2026-08-30 |
| `datatilsynet.json` | Norwegian DPA | `GREEN` | `UNKNOWN` | all `UNKNOWN` | none | 2026-08-30 |
| `digdir.json` | Digitaliseringsdirektoratet | `GREEN` | `UNKNOWN` | all `UNKNOWN` | none | 2026-08-30 |
| `podcast-rss.json` | category placeholder (no publisher, no URL) | `YELLOW` | `UNKNOWN` | all `UNKNOWN` | none | 2026-08-30 |

**Two things stand out.** First: **13 of 14 source files are 47 days old** (all 2026-08-30) and
therefore past the repo's own 30-day stale warning; only `robertmyhre.json` is fresh. None has hit
the 90-day fail threshold yet. Second: **no source is `GREEN` across all four rights fields.**
`data/licensing/README.md`'s rule is *"No monitoring product ships against a source that is not
GREEN for the exact use we are selling."* By that rule, nothing is shippable as a product today —
which is consistent with ADR-0010 and ADR-0014 making all of this internal-only.

Open licensing questions (`data/licensing/README.md`):
- `TODO` (lawyer) — commercial data access from Amedia, Schibsted, Polaris; whether an aggregator
  licence is obtainable at small-company pricing.
- `TODO` (lawyer) — does åndsverkloven's quotation right cover the *briefs* the product generates,
  or only internal use.
- `UNKNOWN` — whether AI processing of licensed content needs separate consent under current
  Norwegian media agreements. *"Assume it does until told otherwise."*

`legal/` has only three files. The named subdirectories `privacy/`, `licensing/`, `compliance/`
**do not exist**. The one substantial file, `legal/procurement/qualification-requirements.md`
(1958 lines), is about procurement/qualification law, not data licensing. It carries a striking
operational warning: statute text must be fetched raw from Lovdata, never through a summarising
layer, because *"automatiske hentelag ved minst tre anledninger returnerte velformede, plausible
og helt oppdiktede versjoner av FOA kapittel 16"* — one fabrication dropped the two-strike ceiling
in § 16-3 entirely, caught only by diffing raw HTML.

### Scrapers — what is live

From `projects/anbud/README.md`, with its own tags:

| Source | File | Status |
| --- | --- | --- |
| **Doffin webclient API** (no key) | `crm/src/lib/sources/doffinWebclient.ts` + `doffinEnrich.ts` | **`FACT`, verified live 2026-09-30.** `POST api.doffin.no/webclient/api/v2/search-api/search` (max top-1000) + `GET …/notices-api/notices/{id}`. All 13 `type` values mapped. 100 notices tested, all with CPV, 17 with winners. Real responses saved as fixtures in `crm/src/lib/sources/__fixtures__/`. eForms tree follows `eforms-sdk-nor` |
| **Doffin Public API v2** (key) | `crm/src/lib/sources/doffin.ts` + `jobs/tasks/ingest-doffin.ts` | Used when `DOFFIN_API_KEY` is set. **Never tested against the real API — no key** |
| **TED v3** (no key) | `crm/src/lib/sources/ted.ts` + `ingest-ted.ts` | **Verified live** against an empty database. `POST /v3/notices/search`, `organisation-country-buyer=NOR` |
| Brønnøysund | `enrich-buyer` | unit-tested |
| Awards backfill, news RSS | `awards-backfill`, `scan-news` | unit-tested |
| KOFA, Lovdata | `ingest-kofa`, `ingest-lovdata` | legal corpus, see below |

**The honest caveat the README states itself:**
> **Webklient-API-et er udokumentert og internt for doffin.no.** Det kan endre seg uten varsel,
> og rate limits og vilkår er ukjente (`UNKNOWN`).

The robust path is a free key from Doffin's developer portal
(`https://dof-notices-prod-api.developer.azure-api.net/`, product "Public") set as `DOFFIN_API_KEY`
on the `worker`. **Operator-gated, still unset.**

### Mercell / TendSign / EU-Supply / Ivalua / Altinn / KGV

`DECISION`, `projects/anbud/README.md` (ARCHITECTURE §10):
> Kun internt bruk: ingenting fra dette systemet vises til kunder eller publikum.
> **Konkurransegrunnlag lastes opp manuelt av et menneske — ingen automatisk nedlasting fra
> Mercell/TendSign/EU-Supply.**

`FACT` — learning-1 measured the terms-of-use gate on 2026-10-14
(`~/Obsidian/Brain/00-claude-inbox/Veldora/2026-10-14_rea-vilkaarsgate-robots-maaling.md`,
robots.txt only; no portal page fetched, no login, nothing installed):

- **TendSign**: `Disallow: /` — 215 links, 18.2 %
- **Ivalua**: `Disallow: /` on **all four hosts** — 127 links, 10.7 %
- **EU-Supply**: open, **but `Disallow: /app/docmgmt`** — the document path is named explicitly
- **Mercell / hyyr / Artifik**: no robots.txt — **and they return HTTP 200 with HTML for
  `/robots.txt` (SPA catch-all), so a naive parser reads silence as permission.** Named as a trap.
- Total explicitly forbidden: **342 of 1184 = 28.9 %**; with EU-Supply's document path, **452 = 38.2 %**.
- Consequence recorded: the earlier adapter ranking (3 = 67.6 %) assumed the obstacle was *login*,
  i.e. operator-gate-openable. For two of six it is `Disallow: /`, which no account lifts.
- Document coverage today: **0 of 1184**; at most **70.3 % legally possible**; **0 % cleared**.
  ToS layer unread — that was the next slice.

**Altinn**: `UNKNOWN` — I found no Altinn integration, no Altinn source JSON, and no Altinn code in
Veldora. **The "Altinn document gap" in `feed.md` belongs to a different project**: it is paal-1's
`aslisten-crm` lane — *"sju saker READY_FOR_ALTINN uten dokumenter siden 12.09"* (feed
2026-10-15T06:21Z and the 2026-10-16 wrap-up, listed as the top item without an owner).
Do not attribute it to Veldora.

**KGV**: `bid-engine/playbooks/kgv-brukere.md` exists (konkurransegjennomføringsverktøy users).
Not an integration.

### Legal posture inside the repo

- `DECISION` ADR-0014 + operator 2026-09-30: *"systemet er til intern bruk og oversikt, og det er
  godkjent å kjøre det."* A formal lawyer review of Doffin's reuse terms (question C6 in
  `research/open-questions.md`) **has not been done**; ADR-0014 is to be revisited if it ever comes
  back restrictive.
- `DECISION` ADR-0010: regulatory monitoring is internal tooling, not a product.
- `DECISION` ADR-0011: the qualification gate is **advisory**; `bid_no_bid` is always null.
- `CLAUDE.md` §10: *"AI proposes, humans decide. Never let an agent make a final bid/no-bid or
  legal call."* Enforced in code by a hook that strips `decision*` fields from every agent write.
- Data policy: `crm/src/globals/DataPolicy.ts`. `FACT` — PR #161 (2026-10-13, `f4cb3f0`) closed two
  fail-open paths: the policy now **refuses when it cannot be read** instead of letting the call
  through. Degraded mode = allow-list `anbudsdokument` + `intern`; an undeclared task is refused
  before the model call.
- No contact persons are stored (stripped at ingest). No secrets in git — only names in `.env.example`.
- Sensitive documents are age-encrypted under `secure/` (`encrypt.ps1` / `decrypt.ps1` / `.cmd`).

### Company legal/tax PDFs in the main checkout root — noted, not read

These sit untracked/tracked in `/home/nithu/code/Veldora/` (the stale checkout). I note their
existence and topic only and quote **no** personal or financial detail from any of them:

- `attest_for_opplysninger_om_skatt_og_avgift_for_931949837_solarconsulting_as_22-09-2026.pdf` —
  tax and duty certificate for Solarconsulting AS.
- `AKSJESALGSAVTALE Excella til Asada Abrar Qureshi.pdf` — a share purchase agreement.
- `Generell_kravspesifikasjon_-_Solcelleanlegg_kommunale_boliger_Sauda_kommune.pdf` — **the Sauda
  kommune technical specification.** This is the artefact behind the one public reference and is
  directly relevant to training the platform on what the company can produce.
- `0,1,2,…,13.pdf`, `content-2.pdf`, `DOC-20260922-WA0008.pdf`, `DOC-20260922-WA0009.pdf`,
  `export_JournalEntryLine_21092026 (2).xlsx` — accounting/journal export and assorted documents.

Several have `:Zone.Identifier` sidecars (Windows download marker). None are referenced by any code.

---

## 5. Open gaps + in-flight work

### Commit volume

`FACT` — **428 commits across all branches since 2026-09-01**, **387 of them since 2026-10-02.**
This is the most active repo in the workspace by a wide margin.

### Open PRs (via `gh`, 2026-10-16)

| # | Branch | State |
| --- | --- | --- |
| 171 | `feature/data-driven-scoring` | **draft** — "Data-driven scoring: audit, award data, lookalike stage 1 (behind flag)". Directly the bid-engine calibration work |
| 169 | `trading-1/dedup-maaling` | open — dedup measurement before fix |
| 166 | `infra/royktest-anthropic-key` | open — smoke test actually calls the model; 11 agent tasks were silently skipping themselves. **Red for two days** per the 2026-10-16 wrap-up |

Recently merged: #170 (dedup fix), #168 (CI gate ran on deploy, not on what the bot landed),
#167, #165, #164 (ADR-0018), #163 (triage baseline), #162 (smoke tests against migrated PG18),
#161 (fail-closed data policy), #160 (countdown shows disputed/single-source dates), #159 (watchdog).

### Known blockers (from `~/Obsidian/Brain/00-firm-bus/feed.md`)

1. **`ANTHROPIC_API_KEY` empty on `worker`** — requirement extraction from description and
   "why we lose" are skipped without it. *Operator-gated.*
2. **`DOFFIN_API_KEY` empty** — the system runs on the undocumented webclient API. *Operator-gated.*
3. **`SLACK_BOT_TOKEN` missing on `worker`** — briefings and deadline alerts are only logged.
4. **`VERCEL_TOKEN` missing as a GitHub secret** — `deploy.yml` skips the Vercel deploy.
5. **Postgres backup with a tested restore** — not done; ADR-0014 says the team should not trust
   the data until it is. Branch `infra-1/pg-backup-restore` built it against a throwaway local
   PG18; the first real dump is an operator gate.
6. **`SEED_ADMIN_*` still on the `crm` service**; admin password not rotated.
7. **No per-IP rate limit on `users/login`** (ARCHITECTURE §9, `TODO`).
8. **Two billing outages on 2026-10-14**, neither of which alerted:
   - **anbud-CRM was down for 26 hours** — last successful model call 13.10 08:15Z, then 897
     consecutive HTTP 400 "credit balance is too low". `anbud-vakt` reported **green** the whole
     time: *"Appen var oppe, den kunne bare ikke tenke."* tools-1 then built
     `anbud-modell-vakt.service` (reads `llm_usage` read-only, alerts on new failed calls per
     error code). Backlog of 301 dead brief jobs has since drained; 789/789 opportunities have briefs.
   - **GitHub Actions refused to start all jobs** across the whole repo (spending limit / billing
     on the moved repo). All six checks on PR #162 died in 2 seconds with zero steps.
     `_bin/ci-guard.sh` was built in response (measures refusal at *job* level, not run level).
   - Recorded conclusion: **account balances must go into monitoring.**
9. **13 decided opportunities have no brief** (7 STRONG_BID, 4 BID, 2 INVESTIGATE) because
   `queueWhere` requires `UNDECIDED`. The ones we said yes to are the only ones without background data.
10. **`issues/054` (the target variable)** — gates all ranking work, untouched since 13.10,
    described as "dyrest å miste".
11. **Document access**: 0 of 1184 documents fetched; ≤70.3 % legally possible; 0 % cleared.
12. **`origin` still points at `Veldora.git`** while the repo is `Solar-Consulting.git`.
13. **42 worktrees / 137 branches / 4.5 GB**, no lifecycle. Deletion operator-gated.
14. Not Veldora, but top of the 2026-10-16 wrap-up without an owner: the **Altinn document gap**
    (7 `READY_FOR_ALTINN` cases without documents since 12.09) — **`aslisten-crm`, not Veldora.**

### Model-cost work (landed)

`FACT` (tools-1, measured in `llm_usage`, n=65): routing `generate.brief` from `sonnet-5-5` to
`haiku-4-5` gave **−76 % per call** (0.02214 → 0.00524 USD), output tokens 1802 → 700 (−61 %),
latency 11.3 → 5.8 s; weekly volume 17.58 → 4.16 USD. Full LLM chain per tender ≈ **0.05 USD**
(0.028 realised, 0.016 after repricing); whole system ≈ **94 USD/month**. Prompt caching measured
**NO** — the largest system prompt is 602 tokens against a 1024 (Sonnet 5) / 4096 (Haiku 4.5)
minimum. `llm_usage` has no tender reference, so per-tender cost is derived, not queried; adding
`opportunity_id` is owned by tools-1 and needs a migration (27 call sites in 21 files).

### The legal knowledge engine

**Where it is not:** the worktree `Veldora-frist` on branch `admin-1/legal-engine-map` is
**identical to `main`** — zero commits, empty diff, clean status, no stash, and the string
"legal-engine" appears nowhere in that tree. It is a naming placeholder for work whose output went
to the Brain, not to the repo. Do not read the branch name as code.

**Where the mapping is:** `FACT` (admin-1, feed 2026-10-15T07:05Z) — mapping complete, 8 agents +
its own document layer.
Synthesis: `~/Obsidian/Brain/00-claude-inbox/Veldora/legal-engine/10-SYNTESE-koblingskart.md`
(12 documents: rettskildemotor, feilsjekk, juridiske domenemoduler, datamodell-og-api,
inntak-og-kilder, analysepipeline-og-llm, dashboard, kvalitet-og-tester, institusjonell-kunnskap,
plus a plan and two briefs).

> Motoren er **~3/4 bygget**; mangler fire ledninger (korpus-til-sak-FK, dokumentinntak, reranking,
> tidsversjonering) og fem beslutninger (ADR-0010 internt-vs-produkt, rettighetsmatrise
> **12/14 UNKNOWN**, KOFA-gate, juristens 59 ASSUMPTION-rader, portaltilgang).
> Gullsettet `legal-gold.json` er **koblet fra CI** — feil hjemmel fanges ikke.

In-repo: `crm/src/lib/legal/`, `crm/src/lib/klage/`, `crm/src/lib/feilsjekk/`, collections
`LegalDocuments`, `LegalChunks`, `LegalFlags`, `LegalQuestions`, `KlageCases`, `KlageDocuments`,
`KommentarVurderinger`; config `legal.ts`, `legalTerms.ts`, `kofa.ts`, `klage.ts`,
`kommentar-regler.json`; globals `KofaIngestState`. Tasks `ingest-lovdata`, `ingest-kofa`,
`contract-review`. ADR-0018 (2026-10-14) decided deadlines have multiple sources and the threshold
table is a cache. PRD: `prd/juridisk-assistent.md`.

---

## 6. Existing knowledge / RAG inside Veldora

What I verified directly:

- **There is no vector search in production.** `FACT` — learning-1, feed 2026-10-13T08:34Z:
  *"pgvector finnes IKKE i prod."*
- **Embeddings are an open, unstarted issue**: `issues/019-embeddings-hybridsok.md`.
- **The retrieval that does exist is deterministic lexical.** `crm/src/lib/bank.ts` implements
  idf-weighted token overlap with a light Norwegian stemmer (strips one of
  `heten/elsen/ingen/ene/ane/het/else/ing/er/en/et/e`, caps stems at 9 chars), a procurement-aware
  stopword list, and `c#`/`c++`/`f#` preservation. Top-K = 8 candidates to the LLM, and
  **"no evidence ⇒ UNKNOWN"**. Deterministic fallback without an LLM key: `FALLBACK_MIN_OVERLAP
  0.35`, `FALLBACK_CONFIDENCE 0.4`, plus `SKILL_KEYWORDS` (~38 keyword→skill rules spanning IT and
  solar/energy, explicitly `ASSUMPTION — tune: ikke en full taksonomi`).
- **LLM layer**: `crm/src/lib/llm/`, `crm/src/prompts/`, `crm/src/config/models.ts`,
  `TASK_MODEL_DEFAULTS` for per-task routing, `LlmUsage` collection for cost/observability,
  `LLM_MODEL=claude-sonnet-5-5` with `generate.brief` routed to `haiku-4-5`. A hard floor prevents
  routing a *legal conclusion* down to a cheaper model (PR #158, "gjør det umulig å rute en
  juridisk konklusjon nedover"); `draft.reply` is deliberately not routed down.
- **Legal corpus chunking exists**: `LegalChunks` collection + `crm/src/lib/legal/`, fed by
  `ingest-lovdata` / `ingest-kofa`. Reranking is one of the four missing "wires" per the legal-engine
  synthesis.
- **Document layer**: `crm/src/lib/documents/`, `Documents` collection, `extractText.ts`,
  `tenderText.ts`; `crm/src/lib/chat/` + `ChatChannels`/`ChatMessages`/`ChatImports` for the
  anbud-chat; `crm/src/lib/learning/` + `learn-preferences` task for the triage feedback loop.
- **Eval harness exists**: `crm/eval/`, `crm/scripts/eval-typesafe/` with
  `data/requirements.json` and `data/citations-hard.json`; docs in
  `projects/anbud/docs/eval-typesafe.md`. The legal gold set `legal-gold.json` is currently
  **disconnected from CI**.

**My read:** Veldora has an LLM pipeline with real cost control and real guardrails, and a
*lexical* retrieval layer over its own structured knowledge. It does not have embeddings, vectors
or hybrid search. For the operator's goal that is arguably fine in the near term — with a bank of
a few dozen references and CVs, idf overlap over structured fields will outperform a vector index
over nothing. The binding constraint is content, not retrieval.

---

## 7. Stale-document flags (for whoever writes the training prompt)

| File | Problem |
| --- | --- |
| `/home/nithu/code/Veldora/**` (main checkout) | 157 commits behind `main`. Entirely a September snapshot |
| `strategy/company-thesis.md`, `positioning.md`, `roadmap.md`, `strategic-pillars.md` | `TODO` per ADR-0015 — still describe Veldora as a public-sector AI/information-flow company. The direction is solar + IT ops |
| `README.md` "Today it answers none of them. Phase 1 is about making the first one possible." | Stale — the platform is live and answering several |
| `procurement/qualification/*.md` (written 2026-09-09) | Legal reasoning stands; every statement about *the company's own position* was written for Veldora-as-startup. Each file carries its own warning banner |
| `qualification-matrix.yaml` | ~2/3 of `gap:` texts still describe Veldora. Only the rows ADR-0015 touched are current |
| `website/content/solarconsulting-inventory.md` §1 address | Marked `utdatert` in-file |
| `automation/agents/anbud.json` | `PAUSED`, superseded by the live platform; ADR-0014 keeps it until the switch is verified |
| `issues/050-scope-kategorier.md` status line | Outdated — written before PR #147 fixed it; assess against 13.3 % loss, not 27 % |
| `verticals/` (`document-ai`, `monitoring-intelligence`, …) vs `crm/src/config/verticals.ts` (`it`, `solar-energy`) | **Do not match.** Listed as an open item in `projects/anbud/README.md` §5 |

---


## 8. Addendum — three claims from parallel agents, checked

Three claims reached me from other agents. **Two are wrong**; I verified all three rather than
folding them in.

### 9a. "`SC-rename` holds a newer Solar Consulting procurement corpus" — **FALSE**

The true part: `/home/nithu/code/SC-rename/.git` reads
`gitdir: /home/nithu/code/Veldora/.git/worktrees/SC-rename`, so it is indeed a Veldora worktree,
on `chore/slack-linear-rename`. I already had it in the §0 worktree table.

The false part: it is **not newer**. Measured:

- `SC-rename` HEAD = `289bcb7`, 2026-10-04, *"chore: Slack-kanalen og Linear-teamet heter Solar Consulting (ADR-0016)"*
- **123 commits behind `main`**, 1 commit ahead.
- Its entire diff against `main` is **5 files**, none of them procurement:
  `automation/OPPSTART.md`, `automation/SLACK-KANALER.md`, `automation/slack-channels.mjs`,
  `decisions/ADR/ADR-0016-navnebytte-solar-consulting.md`, `scripts/linear-website-tasks.mjs`.
- `md5sum` of `procurement/qualification/qualification-matrix.yaml` and `automation/lib/bid-gate.mjs`
  is **byte-identical** between `SC-rename` and `Veldora-ci`
  (`22c5649b…` and `7a1a44dd…` respectively).

The comparison that produced the claim was against the *stale* `/home/nithu/code/Veldora` checkout
(`feat/secure-age`, 157 behind), not against `main`. **Nothing is stranded in `SC-rename`, and my
answer to question 3 is unchanged** — it was already written against `main` via `Veldora-ci`.

### 9b. "No DOFFIN/MERCELL/TED/BRREG env vars exist; tender-source integration is greenfield" — **FALSE**

`FACT` — `projects/anbud/crm/.env.example` declares **`DOFFIN_API_KEY`**, and
`projects/anbud/README.md` records that the variable *name* is already present on the Railway
`worker` service with an empty value, pending an operator action. TED and Brønnøysund need no key
(hence no env var) and both are implemented and running: `ingest-ted` is live-verified, and
`lib/sources/brreg.ts` is called on demand from `enrich-buyer` and the qualification sources.
Mercell has no env var because downloading from it is an explicit architectural **non-goal**, not
a gap. Tender-source integration is live in production since 2026-09-30 — the opposite of greenfield.

### 9c. "Two systemd user services run 24/7 report-only to firm-bus" — **TRUE**, with one wrinkle

```
anbud-vakt.service         loaded active running
  Description=Anbud produksjonsvakt (CRM + dashboard, rapport-only til firm-bus)
  ExecStart=/home/nithu/.local/state/anbud-vakt/vakt.sh
  WorkingDirectory=/home/nithu/.local/state/anbud-vakt/railway

anbud-modell-vakt.service  loaded active running
  Description=Anbud modell-vakt (llm_usage i prod — report-only til firm-bus)
  ExecStart=/home/nithu/code/command-center/_bin/anbud-modell-vakt.sh
  WorkingDirectory=/home/nithu/.local/state/anbud-modell-vakt/railway
```

- **`anbud-vakt`** watches the CRM/dashboard **HTTP surface**: health, response time, 5xx, every
  minute; writes to `Brain/00-firm-bus/feed.md` only when something is wrong, never alerts on a
  single slow response, and says so when the log check sees no traffic (so "zero 5xx" is not read
  as green while blind). **Wrinkle:** it executes a *copy* at
  `~/.local/state/anbud-vakt/vakt.sh`, not the repo file `projects/anbud/scripts/vakt.sh`.
  The installer `projects/anbud/scripts/vakt-install.sh` places it there. Repo edits do not reach
  the running service until it is reinstalled — a drift risk worth noting.
- **`anbud-modell-vakt`** watches the **thinking** surface: reads `llm_usage` in production
  read-only and alerts on new failed model calls per `error_code`, plus a "could not measure"
  signal. It lives in **command-center**, not Veldora.
- Why both exist: `FACT` (tools-1, feed 2026-10-15T06:27Z) — during the 26-hour outage
  `anbud-vakt` **would have reported green the whole time**. *"CRM svarte 200 med null 5xx mens
  hvert modellkall feilet på 400. Appen var oppe, den kunne bare ikke tenke."* The model watchdog
  was built to close that gap in coverage.
- Neither service takes action. Both are report-only, per the operator's no-auto-disable rule.

---

## 9. What I could not determine

- `UNKNOWN` — row counts in the production capability bank (`people`, `references`,
  `capability-facts`, `evidence`). Needs `railway link --project anbud --environment production`
  and a read-only query. **This is the first thing to check before any "training" work.**
- `UNKNOWN` — whether the five reference quotes have re-confirmed consent
  (`consentConfirmed` flags in `website/content/references.ts`).
- `UNKNOWN` — auditor for Solarconsulting AS (open question A3).
- `UNKNOWN` — B3, the realistic win rate. Still the load-bearing unanswered number.
- `UNKNOWN` — whether Veldora exists as a legal entity (ADR-0015 says so itself).
