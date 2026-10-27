# Korpus-IDF i vokabularsjekken: skyggekjøring og utvalg (2026-10-27, data-1)

**Kort:** å koble inn korpus-IDF-tabellen ville endre dommen på 2 748 av 19 888 par (1 766 nye flagg, 982 fjernede). Tallet 2 588 fra morgenmålingen stemmer med den metoden (jeg får 2 586), men den metoden avkortet ikke body til 4000 tegn slik `distillReal` gjør. På utvalget med 20 endrede rader ser oppsummeringen grei ut i nesten alle. Det betyr at begge metodene feilflagger, bare på ulike rader. Korpus-IDF er ikke bedre, den bytter én støykilde mot en annen. Ingenting er endret i prod.

Ingen skriving til live-DB, ingen betalte kall, ingen distill. memory.db er lest via `backup()` til en snapshot som er slettet etterpå. Skript: `packages/memory-engine/scripts/idf-shadow.ts` (lokal commit på `data-1/idf-skygge`, ikke pushet).

## Tall

Snapshot 27.10 kl. 11:22: 20 782 verbatim-rader, 19 888 destillerte objekter (par). Ingen par er trivielle (<100 tegn), så kortslutningen i `distillReal` slår ikke inn.

| Variant | Flagget, fallback | Flagget, korpus-IDF | Endret | Ny flagget | Ny klarert |
|---|---|---|---|---|---|
| **Som prod (body ≤ 4000 tegn, IDF over verbatim ≤ 4000)** | **6 877** | **7 661** | **2 748** | **1 766** | **982** |
| Som morgenmålingen (hel body, IDF over hel verbatim) | 7 021 | 7 721 | 2 586 | 1 643 | 943 |
| Hel body til IDF, avkortet til topp-tokens | 6 877 | 7 662 | 2 729 | 1 757 | 972 |
| IDF over verbatim + destillert tekst | 6 877 | 8 247 | 2 854 | 2 112 | 742 |

Morgentallene (7 021 / 7 723 / 2 588) gjenskapes innen 2 rader. Avviket kommer av 62 nye verbatim-rader siden, som flytter df litt. Merk at 7 021 fra #119 overvurderer prod med 144: med avkortingen som `distillReal` faktisk gjør, flagger fallbacken 6 877.

**2x2, som prod:**

| | Korpus-IDF flagger | Korpus-IDF flagger ikke |
|---|---|---|
| **Fallback flagger** | 5 895 | 982 |
| **Fallback flagger ikke** | 1 766 | 11 245 |

**Kjennetegn per celle** (som prod). Hapax betyr df ≤ 1, altså et ord som bare finnes i denne ene raden i hele korpuset.

| Celle | n | Median body | Norsk verbatim | Hapax-andel i korpus-topp15 | Hapax som overlever | Sti-tokens i fallback-topp15 |
|---|---|---|---|---|---|---|
| Ingen flagger | 11 245 | 368 | 22 % | 10 % | 41 % | 1,1 |
| Ny flagget | 1 766 | 1 603 | 54 % | 33 % | 11 % | 3,3 |
| Ny klarert | 982 | 935 | 61 % | 23 % | 27 % | 2,5 |
| Begge flagger | 5 895 | 1 476 | 76 % | 40 % | 7 % | 3,1 |

Per prosjekt (ny flagget / ny klarert): command-center 679/557, thesis 471/133, nexus 454/204, as 51/33, aslisten-crm 36/39. Resten er småtall.

## Utvalg: 20 endrede rader

Seed 42, de ti første i stokket rekkefølge i hver retning. Regelen var å hoppe over `personlig`, `soking-fulltid` og rader med lønn eller helse, men ingen av de 20 første traff den. Stier og ID-er er forkortet eller redigert. «Overlever» er treff av topp-15-tokens i `exchange_core + specific_context`, og terskelen er 4/15 (25 %). I token-kolonnene er de fire øverste vist, `[n]` er df og ✓ betyr at ordet finnes i oppsummeringen.

| # | Objekt | Prosjekt | Retning | Overlever fallback → korpus | Body | Fallback topp | Korpus-IDF topp |
|---|---|---|---|---|---|---|---|
| 1 | `mo_019ec43d1c01_870b5bb9` | command-center | ny flagget | 4/15 → 2/15 | 478 | command-center-production-…✓, skjelletet, automatisk, kommandoen | skjelletet[1], boote[3], bland[6], aktiveres[18] |
| 2 | `mo_019edea167f8_e6c5a1b3` | command-center | ny flagget | 5/15 → 0/15 | 9032 | ai-assistent/scripts/hooks…, …/phase-status.md, …/settings.json✓, home/nithu/code/ai-assistent | inbox/feed/skills/rag[1], abandoned-in-place[1], auto-surfaced[1], most-surfaced[1] |
| 3 | `mo_019ec67edab8_9299d502` | nexus | ny flagget | 7/15 → 3/15 | 495 | already-committed, accumulated, uncommitted, 2026-06-10✓ | mid-audit[2], already-committed[4], rolled[8]✓, accumulated[12] |
| 4 | `mo_019ee02976d0_c0908453` | nexus | ny flagget | 4/15 → 1/15 | 2127 | …/command-center/_bin/firm-tab-init.sh✓, …/_bin/firm-tab-init.sh, docs/ops/sandbox-setup.md✓, zellij/layouts/firm8.kdl | sandbox-vs-production[1], workspace-launcher[1], documents/scripts[1], 2026-05-21t21[1] |
| 5 | `mo_01a152441c12_7ef0acf4` | command-center | ny flagget | 4/15 → 3/15 | 325 | monitor_agent_enabled✓, overvåkeren, skyggemodus, kontrakter | monitor_agent_enabled[11]✓, november[24]✓, strøm[26], overvåkeren[30] |
| 6 | `mo_019ef272960c_102d90cd` | as | ny flagget | 4/15 → 3/15 | 200 | eindomsmegling, forskjellige, underveis, maksimalt | eindomsmegling[1], maksimalt[14], systemer[26], finans[27]✓ |
| 7 | `mo_019f92167582_5e521287` | nexus | ny flagget | 4/15 → 1/15 | 2011 | …/ai-assistent/scripts/oneshot/…✓, …/node_modules/tsx/…, scripts/oneshot/2026-07-23…✓, asyncloaderhooks… | …/node_modules/tsx/…[1], 1784843560178[1], internal/modules/esm/resolve[1], internal/modules/esm/hooks[1] |
| 8 | `mo_01a14a563833_ae6a0156` | command-center | ny flagget | 5/15 → 3/15 | 1785 | status/validfrom/validto/…, docs/kvalifikasjonslag.md✓, npm/_npx/…✓, legal-chunk-versions | status/validfrom/validto/…[1], kofa-sitater[1], loadklagelaw[1], kofa-felt[1] |
| 9 | `mo_019edfdfcffd_7e2f302e` | command-center | ny flagget | 4/15 → 2/15 | 1025 | 2026-05-25-brain-upgrade-p…✓, 00-firm-bus/inbox/code-1.md, 07-github-repos, brain-folders | falsify[4], code-1.md[5]✓, 795-796[5], 2026-05-25-brain-upgrade-p…[6]✓ |
| 10 | `mo_019ee010a819_bafd04a3` | nexus | ny flagget | 4/15 → 2/15 | 1637 | home/nithu/code/ai-assistent✓, default-fallback-paths, motstridende/dormante, motstrid/redundant✓ | default-fallback-paths[1], motstridende/dormante[1], dobbel-gate-feller[1], motstrid/redundant[1]✓ |
| 11 | `mo_01a1762f9528_a310bd9b` | command-center | ny klarert | 2/15 → 5/15 | 2184 | obsidian/brain/00-claude-i…, solar-consulting/horizon, projects/anbud/crm, solar-consulting | obsidian/brain/00-claude-i…[1], flatten[3]✓, data/legal[4], hashes[4] |
| 12 | `mo_019ee0138f09_6b3cc0b0` | nexus | ny klarert | 2/15 → 4/15 | 1829 | apps/worker/src/firm/agent…, apps/worker/src/firm/agent…, apps/worker/src/firm/agent…, apps/worker/src/firm/predi… | apps/worker/src/firm/agent…[2], shared/cross-cutting[2], regression-guarded[2], deliberately-slow[2] |
| 13 | `mo_01a011a365e0_370539a5` | aslisten-crm | ny klarert | 3/15 → 4/15 | 292 | eksisterende, dokumentert, approachen, assistant✓ | approachen[1], rå-body[1]✓, webhooken[4], crm-siden[7] |
| 14 | `mo_019ee031b0e1_4f97dafc` | thesis | ny klarert | 3/15 → 4/15 | 16176 | merged_database_classified…, nasicon/perovskite/sulfide, metadata_completeness, predict-then-verify | data-grounded[8]✓, weigh[9], number/figure[10], dial[10]✓ |
| 15 | `mo_01a14a6d00bd_59204deb` | nexus | ny klarert | 2/15 → 4/15 | 320 | innboks-monitoren, zotero-nøkkelen✓, ci-sjekker, assistant | zotero-nøkkelen[15]✓, ci-sjekker[46], ventet[71], sc-07[105]✓ |
| 16 | `mo_01a139e7f0fa_84a67988` | command-center | ny klarert | 3/15 → 4/15 | 2315 | 00-claude-inbox/command-ce…, _bin/tests/doctor-guard.sh, tools-1/doctor-guard-aware, gh/git/railway/vercel | 00-claude-inbox/command-ce…[1], _bin/tests/doctor-guard.sh[1], gh/git/railway/vercel[1], claude.ai-connectors[1] |
| 17 | `mo_019ee0330043_80f581af` | nexus | ny klarert | 1/15 → 4/15 | 2643 | docs/strategy/2026-06-12_a…, worker/orchestrator/regime…, portfolio-brain.classifyre…, home/nithu/code/ai-assistent | ai-1-adjacent[1], prioritizing[1], api/shared[1], re-breaks[1] |
| 18 | `mo_019ef2714628_996164fa` | as | ny klarert | 3/15 → 4/15 | 236 | pragmatiske, veiviseren, respektere, nb-whisper✓ | pragmatiske[4], respektere[4], gpu-server[7]✓, veiviseren[7] |
| 19 | `mo_01a1435cd1e0_1e5ad083` | command-center | ny klarert | 3/15 → 5/15 | 455 | tmp/claude-1000/…/tasks/….output, toolu_[id], task-notification, distill-fikser✓ | tmp/claude-1000/…[1], toolu_[id][1], distill-fikser[1]✓, bxrz4lnqz[1] |
| 20 | `mo_01a13d9d6bc6_61f2786c` | command-center | ny klarert | 3/15 → 5/15 | 409 | task-notification, røyktest-portens, røyktest-porten✓, re-kjøringer | bruk-og-kast[4], bh3ren3d0[4], røyktest-portens[5], re-kjøringer[6] |

### Utdrag (verbatim V, oppsummering D, maks 160 tegn)

**1.** V: «jaa fiks det både på obsidian så den lærer og bygger hjernen og på github så ting er lagret i skjelletet. du kan også ha som default at ting som dette aktivere…»
D: «User requests dual storage strategy: update both Obsidian (for learning/brain-building) and GitHub (for skeleton storage). Proposes automating this via 'firm' …»

**2.** V: «Diagnosis complete. I have everything verified. Here is the audit. --- # Continuity audit: why every session feels like "starting over" ## (a) What a fresh ses…»
D: «Audit reveals two SessionStart paths with mismatched coverage: global hook surfaces stale Nexus context to all panes; firm-context hook only fires in command-c…»

**3.** V: «The tree is now clean except 3 untracked files. The large M/D list from the very first 'git status' call was a stale snapshot — between my first call and now, …»
D: «Git state audit reveals 3 untracked files remaining after parallel session committed stale M/D changes; date rolled to 2026-06-10 during audit window.»

**4.** V: «Audit complete. Report below. --- **Peer-WIP audit (agent #8)** **1. '.env.example'** — added a 21-line safety comment block above 'DATABASE_URL' explaining th…»
D: «Audit of peer-WIP changes in nexus project: .env.example safety documentation, zellij layout path migration (/home/nithu/code/_bin → /home/nithu/code/command-c…»

**5.** V: «Overvåkeren kjører nå i skyggemodus i prod. Strøm B logger kontrakter som snart går ut uten å vise dem til teamet, og strøm C står av. Jeg slo den på etter at …»
D: «Monitor agent running in shadow mode in prod; Stream B logs expiring contracts without team visibility, Stream C disabled. Re-enabled after #241 merge; disable…»

**6.** V: «okay letsgooo du har fått nye oppgaver. la oss bygge to forskjellige leadgen systemer en for finans og en for eindomsmegling. du får nok flere oppgaver av code…»
D: «User initiates project to build two separate leadgen systems: one for finance and one for real estate. User instructs to run maximum ultracode and expects addi…»

**7.** V: «ok kjør fase 2 og resten når review er ferdig. NEXUS [bruker@vert] WSL code ai-assistent feat/hle-import-resilience ?22 24.15.0 2s 20:19:52 ❯❯ git pull railway run …»
D: «User attempts to run phase 2 after review completion, but encounters ERR_MODULE_NOT_FOUND for backfill script at /[sti].ts during Railway Postgres exec…»

**8.** V: «<task-notification> <task-id>bqeuusf4m</task-id> <summary>Monitor event: "innboks orchestrator-1"</summary> <event>## STATUS SC-05 — from infra-1 - status: MIL…»
D: «Infrastructure status SC-05 reports milestone 2 delivery: versioned legal text now tracks status with validTo for repealed sections, FOA § 7-9 sourced from Lov…»

**9.** V: «Important context: in 'code-1.md', lines 256, 261, 306, 307 are **historical narrative** describing the rename itself. The instruction says "only replace folde…»
D: «Historical narrative and collision documentation in code-1.md (lines 256, 261, 306–307) and brain-upgrade-plan.md (lines 795–796) must be preserved as-is; they…»

**10.** V: «Read-only kode-audit i repoet /home/nithu/code/ai-assistent. Operator har 217 env-variabler på Railway (Worker-tjenesten) og vil ha en rens — mange er kill-swi…»
D: «Audit of 217 Railway Worker environment variables in /home/nithu/code/ai-assistent to classify into BEHOLD, DØD, UDOKUMENTERT, DORMANT-FEATURE, MOTSTRID/REDUND…»

**11.** V: «The plan for moving Horizon into its own repo, 'Solar-Consulting/horizon', is ready. I haven't executed any of it. It's at '~/[sti].md', and orchestrat…»
D: «Horizon repo migration plan documented: use git filter-repo to flatten paths, migrate Railway services sequentially, update Vercel dashboard root, configure Ac…»

**12.** V: «Sufficient signal — reporting now. --- **Test suite health — agent #4** **Status:** GREEN. 'npm test' in 'apps/worker' → **1005 pass / 0 fail / 0 skip / 0 todo…»
D: «Test suite shows 1005 passing tests with zero failures in apps/worker. Three coverage gaps identified in recently-touched code: discord-bridge.ts (zero test re…»

**13.** V: ««ok kjøør» — jeg kjører. Approachen er godkjent. Jeg skriver først spec-en (så designet er dokumentert), så bygger jeg CRM-siden bak flagg + tester. La meg ras…»
D: «Assistant confirms approach: write spec first, build CRM behind feature flag with tests. Needs to verify existing webhook HMAC implementation and raw-body hand…»

**14.** V: «You are the JUDGE (thesis-4 seat). For discussion section 7.1 — The Headline Result (R2=0.971 conductivity surface), weigh the advocate against the counter-adv…»
D: «Judge task: evaluate discussion section 7.1 (R2=0.971 conductivity surface) for advocate vs. counter-advocate positions. Identify data-grounded strengthenings,…»

**15.** V: «Det har ikke kommet nye meldinger i innboksen på 30 minutter. Det er ventet, siden jeg venter på at SC-07 blir merget. Jeg har startet innboks-monitoren på nyt…»
D: «Inbox monitor has been inactive for 30 minutes while waiting for SC-07 to merge; PR #175 remains in draft status with passing CI checks, blocked on Zotero key.»

**16.** V: «Done. One step, closed end to end. **Hva jeg gjorde.** Alt som står igjen på det aktive målet er operatør-gated (yq, Twelve Data, Context7, telegram-mcp), så j…»
D: «Fixed tools-doctor.sh health check that was incorrectly reporting FAIL on remote runs due to firm-exec-guard PATH-shims. Introduced SKIP status for unmeasurabl…»

**17.** V: «Nexus = autonomous XAUUSD/gold trading firm (demo on OANDA), repo /home/nithu/code/ai-assistent. READ-ONLY — analysis only, DO NOT edit/build/commit anything. …»
D: «Nexus gold trading system (OANDA demo) has fixed absolute-$ volatility threshold drift via ATR_PCT_THRESHOLDS_ENABLED (#102/#103), but faces new blocker: worke…»

**18.** V: «Nå gjør jeg veiviseren ærlig — den skal respektere "sky"-valget (→ Azure, som du sier er den pragmatiske starten), og vise **hva hvert valg faktisk krever** (i…»
D: «Making the wizard honest about cloud choice (Azure) and clarifying actual requirements, especially that NB-Whisper requires running a GPU server.»

**19.** V: «<task-notification> <task-id>bxrz4lnqz</task-id> <tool-use-id>[id]</tool-use-id> <output-file>/[sti].output</output-file> <status>completed</status> <s…»
D: «CI smoke-test completed successfully on PR #94 (brain distill-fikser) with all checks passing.»

**20.** V: «<task-notification> <task-id>bh3ren3d0</task-id> <summary>Monitor event: "fem re-kjøringer på main, inkl. røyktest-portens første kjøring"</summary> <event>GRO…»
D: «Guard main is GRØNN with 4 of 5 re-runs complete. Only 'anbud' remains: røyktest-porten running 30 smoke-tester against ephemeral Postgres 18.»

## Min vurdering

Jeg har lest de første ~600 tegnene av hver rad, ikke hele teksten. Med det forbeholdet: i alle 20 rader er oppsummeringen en rimelig gjengivelse. #7 er mest terminalutskrift, så der betyr dommen lite uansett. Ingen av dem ser ut til å trenge −0,2. Det betyr at fallbacken tar feil i rad 11–20 og korpus-IDF tar feil i rad 1–10. Siden korpus-IDF legger til 1 766 flagg og fjerner 982, gir byttet ~780 flere flagg som trolig er feil.

Hvorfor de bommer:

- **Fallbacken** rangerer etter lengde og vil derfor at oppsummeringen skal inneholde lange stier, tmp-filnavn og tool-use-ID-er (#11, #12, #16, #17, #19). En god oppsummering kopierer ikke `apps/worker/src/firm/agent-bus/...` ordrett. Den straffer dermed rader med mange stier, ikke korte rader.
- **Korpus-IDF** med `log(N/(1+df))` setter ord med df = 1 øverst: tastefeil («skjelletet», «eindomsmegling»), task-ID-er, linjeområder («795-796»), tidsstempler («1784843560178»), node-interne stier og engangs-sammensetninger. I de nye flaggene er en tredjedel av topp-15 slike hapax-ord, og bare 11 % av dem havner i oppsummeringen. Det er ikke fordi oppsummeringen er generisk. Ordene er rett og slett støy.
- **Felles feil:** oppsummeringene skrives på engelsk, mens 43 % av verbatim-tekstene er norske etter en enkel regex-heuristikk (æøå eller vanlige norske småord), og 76 % i «begge flagger». Substring-overlapp på tvers av språk måler oversettelse, ikke tap av informasjon. «overvåkeren» kan ikke overleve i «Monitor agent». Dette er trolig den største grunnen til at 6 000–7 700 rader flagges, med begge metodene.

**Konsekvens i dag:** `lowVocab` gir bare −0,2 på `confidence`. Ingen kø for ny destillering finnes (spec §3.3 nevner `_redistill_queue`, men den er ikke bygget), og ingenting i recall eller rag-engine leser `memory_objects.confidence` (grep). Uansett hvilken metode som brukes, påvirker dommen derfor ikke recall nå. Recall-eval er ikke kjørt på nytt, siden ingen hentekode er endret.

**Hvis noen skal koble inn korpus-IDF** (egen beslutning, ikke gjort): da trengs minst et df-gulv (for eksempel df ≥ 2–3), og tokens med sifre, stier eller ID-form må filtreres bort. Språkproblemet må også løses, for eksempel ved å sammenligne mot `entities`/`decisions` eller gjøre sjekken språkbevisst. Uten dette er korpus-IDF ikke bedre enn fallbacken, og antall flagg øker.

## Reproduser

```
db.backup(<snapshot>)   # read-only kilde, se skriptets header
npx tsx packages/memory-engine/scripts/idf-shadow.ts <snapshot> <ut.json> 42 verbatim4k   # som prod
npx tsx packages/memory-engine/scripts/idf-shadow.ts <snapshot> <ut.json> 42 prior        # som morgenmålingen
```
