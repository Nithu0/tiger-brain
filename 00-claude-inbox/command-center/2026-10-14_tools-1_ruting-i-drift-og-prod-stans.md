# tools-1 — modellrutingen ER i drift, men prod har ikke produsert et eneste svar siden 13.10 08:15Z

Dato: 2026-10-14 · rolle: tools-1 · repo: command-center (dom) + Veldora/anbud (måling)
Dispatch: `inbox/tools-1.md` 2026-10-14T06:30Z, punkt 1-3.

## 1. Er `TASK_MODEL_DEFAULTS` (PR #158) faktisk i drift? JA — målt, ikke resonnert.

PR #158 merget 2026-10-13T19:01:32Z (merge-commit `1a9e0a7`). Innholdet er på `origin/main`:
`models.ts:114-143` har tabellen, `router.ts:47` har presedensen
`LLM_MODEL_<TASK>` → `TASK_MODEL_DEFAULTS` → `LLM_MODEL` → `DEFAULT_MODEL`, og
`tender-brief.ts:128` sender faktisk `task: 'generate.brief'` inn i `completeJson`.

Beviset er ikke koden, det er `llm_usage` i prod (Railway `anbud`/production/Postgres,
read-only SQL over stdin):

| vindu | task | model | n |
|---|---|---|---|
| 24t FØR merge | `generate.brief` | `claude-sonnet-5-5` | 95 |
| ETTER merge | `generate.brief` | `claude-haiku-4-5` | 798 |

Første haiku-rad: `2026-10-13 19:20:03Z` — 19 minutter etter merge. `generate.news` flyttet
samme vei (sonnet → haiku). Rutingen er altså i den kjørende builden, ikke bare i koden.

## 2. Men: ingen av de 798 kallene lyktes. Prod har stått i 26 timer.

Alle 897 modellkall siden merge har `ok = false`, `error_code = http_400`. Feilteksten i
`payload_jobs.error` sier det rett ut:

> `LLM-kall feilet med HTTP 400: {"type":"error","error":{"type":"invalid_request_error",`
> `"message":"Your credit balance is too low to access the Anthropic API...`

Siste **vellykkede** modellkall i hele prod-basen: `generate.news` 2026-10-13 08:15:20Z.
Det betyr: **ingen vellykket kall har noensinne kjørt gjennom den nye rutetabellen.**

Konsekvens for mitt eget regnestykke, sagt eksplisitt: anslaget «$8,92/uke, 40,6 % av
regningen» er **ikke bekreftet i drift**. Målt kostnad siden merge er $0, og grunnen er
ikke besparelse — det er at ingenting kjører. Først etter påfylling kan tallet verifiseres.

Målt kostnad per døgn (bare `ok`-rader), for påfyllingsbeslutningen:

| dag | ok-kall | USD |
|---|---|---|
| 2026-10-11 | 233 | 4,65 |
| 2026-10-12 | 638 | 12,84 |
| 2026-10-13 | 128 | 1,84 (stopper 08:15Z) |

## 3. Etterslepet, siden det er det påfyllingen faktisk betaler for

`payload_jobs` med `completed_at IS NULL`, alle med `has_error`:

| task_slug | rader | distinkte muligheter | maks forsøk |
|---|---|---|---|
| `tender-brief` | 301 | 58 | 3 |
| `assess-requirements` | 71 | — | 3 |
| `extract-requirements` | 35 | — | 3 |

Eldste døde brief-jobb: 2026-10-09 02:00Z. Jobbene har brukt opp forsøkene (maks 3), så
**påfylling alene drenerer ikke etterslepet** — `brief-coverage` må køe dem på nytt. Den gjør
det av seg selv (`*/20 6-22`, 15 per kjøring), så det selvheler på ~2 timer for 58 muligheter.

Takten på de feilende kallene er forklart, ikke mystisk: 3 coverage-kjøringer/time × 15 jobber
× 3 forsøk = 135/time, og målt var 135-141/time. Ingen runaway-loop. 400-kall faktureres ikke.

## 4. Ett målt hull i rutetabellen (funn, ikke oppgave jeg har tatt)

`extract.requirements` og `extract.requirements-check` er definert i `LLM_TASKS`
(`models.ts:28-29`, begge `dataClass: 'public'`, altså mekanisk uttrekk) men står **ikke** i
`TASK_MODEL_DEFAULTS`. De kjører derfor fortsatt sonnet: 51 kall siden merge, 36 i døgnet før.
Samme klasse som de fem `extract.*`-radene som ER i tabellen. Melder det; bygger det ikke
uten ordre.

## 5. Dom over de usporede stiene (dispatch punkt 1)

Commit `12612b4` på gren `tools-1/spor-omnigent-ralph` (lokal, **ikke pushet**):

| sti | dom | grunn |
|---|---|---|
| `omnigent/firm/` (25 filer) | **spores** | `omnigent` CLI er installert (`~/.local/bin/omnigent`); `_bin/omni-firm.sh` er dokumentert inngang |
| `_bin/omni-firm.sh` | **spores** | launcher for samme |
| `_bin/ralph-{once,afk}.sh`, `ralph-prompt.md` | **spores** | skillen `prd-to-issues` refererer `ralph-once.sh` eksplisitt; runbook `Runbook-AI-Coding-Workflow.md` finnes |
| `body.txt` | **dødt — venter på operatør** | Doffin-HTML-dump fra 2026-09-07, i command-center-roten, hører til Veldora-domenet. Sletting er operatør-gated |

Kjent begrensning skrevet inn i commit-meldingen: `omnigent/firm/agents/*/config.yaml` er
generert av `sync-agents.py` og har absolutte `/home/nithu`-stier (cwd + write_paths), så de er
ikke portable. Spores likevel, fordi kilden (`~/.claude/agents/*.md`) ligger utenfor repoet.
Skannet for legitimasjon (`sk-ant`, `sk-`, `ghp_`, `Bearer`, `*_API_KEY=`) — ingen treff.

## Metode / etterprøvbarhet

- `railway link -p anbud` fra scratch-mappe, SQL over **stdin**, `SET default_transaction_read_only = on;`
  i hver fil, `railway unlink --yes` etterpå (verifisert: `railway status` → «No linked project»).
- Spørringene ligger i sesjonens scratchpad (`ruting/q1..q7.sql`). Ingen skriving mot prod.
- Checkouten min sto på `tools-1/registry-reverify-1013` (merget som #89); byttet til `main` og
  fast-forwardet 5 commits før måling, slik dispatchen krevde.

---

## 6. ETTER PÅFYLLING (2026-10-14T10:23:16Z): rutingen er bevist med `ok=true`, og prisen er lavere enn jeg forutså

Operatøren fylte API-kontoen. Monitoren fanget første ok-rad. Nå er `generate.brief` målt på
begge modellene med `ok=true` og `cost_usd` satt — altså ikke lenger et anslag:

| model | ok-kall | inn-tokens (snitt) | ut-tokens (snitt) | USD/kall | latens |
|---|---|---|---|---|---|
| `claude-sonnet-5-5` | 794 | 2059 | 1802 | **0,02214** | 11 347 ms |
| `claude-haiku-4-5-20251001` | 15 | 1719 | **679** | **0,00512** | 5 333 ms |

Per kall: **−77 %**. Ved samme volum som måleuka (794 briefer) blir brief-kostnaden
**$17,58 → $4,07/uke**. Mitt eget anslag var «haiku halverer den, ≈ $8,79/uke» — det var for
pessimistisk, og grunnen er lærerik: anslaget antok at ut-tokenene holdt seg konstante.

**De gjorde de ikke. Ut-tokenene falt 1802 → 679, altså 62 %.** Siden ut-tokens er 81 % av
kostnaden, er det den dominerende driveren — ikke prisforskjellen mellom modellene.

### Og derfor et forbehold som veier mer enn besparelsen

Et 62 % kortere svar på samme skjema er ikke «samme brief, billigere». Det er en **materielt
annen brief**. Den kan være like god — skjemaet er tvunget (`completeJson(briefLlmSchema)`), hvert
sitat verifiseres i kode (`lib/verify.ts`, `lib/citationFlags.ts`), og operatøren leser feltene,
ikke prosaen. Men ingen har sammenlignet haiku- og sonnet-briefer på ekte anbud, og tallet over er
nettopp det beviset på at de er forskjellige.

`models.ts:137-139` sier dette selv: «Why it still needs a human check before deploy ... no one has
compared Haiku and Sonnet briefs on real tenders yet. `scripts/compare-brief-models.ts` runs that
comparison (it spends API credits — operator call).» **Den sammenligningen bør kjøres nå**, mens
det er kreditt på kontoen, og den er en operatørgate fordi den koster API-penger.

En del av inn-token-fallet (2059 → 1719, −17 %) er min egen skive 2 i samme PR — feltene koden alt
har, ble tatt ut av spørsmålet. Det var forventet; det er ut-token-fallet som ikke var.

### Forbehold på selve tallet

**n = 15.** Det er et lite utvalg, og de 15 er etterslepsbriefer fra de 58 muligheter som sto i kø
— dokumentstørrelsen der er ikke nødvendigvis representativ for en vanlig uke. Tallet skal
måles om igjen når et par hundre briefer har kjørt. Jeg melder det da. Monitoren står.

Bonus som ikke var målet: latensen halverte seg, 11,3 s → 5,3 s per brief.

---

## 7. RETTELSE (2026-10-14T13:13:57Z): jeg beskrev dreneringsmekanismen feil, og `payload_jobs` kan ikke måles som jeg antydet

To påstander i §3 og §6 over er feil. De endret ingenting operasjonelt — etterslepet ble tømt
uansett — men mekanismen jeg beskrev er gal, og noen kan bygge på den.

**Hva jeg skrev:** «Jobbene har brukt opp forsøkene (maks 3), så påfylling alene drenerer ikke
etterslepet — `brief-coverage` må køe dem på nytt, ~2 t.»

**Hva som faktisk skjedde:** de køede radene som fortsatt hadde forsøk igjen ble gjenopptatt av
workeren da kreditten kom tilbake, lyktes, og ble **slettet**. `brief-coverage` har ikke opprettet
én jobb siden `10:00:06Z` — tre timer før dette skrives. Dreneringen skjedde ved gjenopptak, ikke
ved ny køing.

**Hvorfor det var usynlig for meg:** `payload 3.90.2` defaulter `deleteJobOnComplete: true`
(verifisert i den installerte pakken: `dist/config/defaults.js:64` og `:135`), og CRM-en overstyrer
den ikke — `payload.config.ts:199-203` setter bare `tasks` og `access`. Vellykkede jobber
forsvinner altså fra tabellen i samme øyeblikk de lykkes.

### Og det er den egentlige lærdommen, større enn min feil

**I `payload_jobs` overlever bare feilene.** Det har tre konsekvenser som rammer alt som måles på
den tabellen:

1. **«331 åpne jobber» er ikke et etterslep.** `completed_at IS NULL AND has_error` gir 331 rader
   akkurat nå, og alle er oppbrukte lik hvis muligheter nå *har* brief. Et dashbord som viser det
   tallet som «ventende arbeid» lyver. Mine egne tall gjennom dagen (301 → 332 → 437 «døde jobber»)
   var riktig merket, men lette å lese som arbeid som venter.
2. **Gjennomstrømning og suksessrate kan ikke måles fra tabellen i det hele tatt.** Spør du den hvor
   mange jobber som lyktes i dag, svarer den null — fordi de er borte. Jeg kjørte nøyaktig den
   spørringen og fikk 0 rader, samtidig som 83 modellkall hadde lykkes og 65 briefer var skrevet.
   Alt som bygges på `payload_jobs` vil se en verden der alt feiler.
3. **Suksess må måles et annet sted.** For denne lanen er det `llm_usage` (`ok = true`) og
   `briefs`-rader. Det er de to jeg faktisk brukte, og de stemte hele veien.

**Dette treffer data-1s retry-arbeid direkte:** hvis retry-veien for destilleringshullet bygges på
«rader som ikke er fullført», må den vite at fullførte rader er slettet og at de gjenværende kan
være oppbrukte lik. Meldt videre.
