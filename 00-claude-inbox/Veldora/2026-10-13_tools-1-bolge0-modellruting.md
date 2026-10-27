# tools-1 — bølge 0: modellruting + prompt-caching (målt, ikke antatt)

**Gren:** `tools-1/model-routing-defaults` i worktree `/home/nithu/code/Veldora-ruting` (meldt til orchestrator-1 før opprettelse). **Ingen push. Ingen prod-endringer.** Alle tall er lest read-only fra prod-basen (`SET default_transaction_read_only = on`, SQL over stdin via `railway ssh`).

## 1. FØR — målt i prod, ikke estimert

`llm_usage`, 1 649 rader, 2026-10-06 → 2026-10-13 (7 døgn). 1 366 vellykkede kall, **$21,99** totalt ≈ **$94/mnd** i dagens tempo.

| Oppgave | Kall | Modell | Inn-tokens | Ut-tokens | USD | Andel |
|---|---|---|---|---|---|---|
| `generate.brief` | 794 | sonnet-5-5 | 1 634 979 | 1 430 565 | **17,5756** | **79,9 %** |
| `judge.assess` | 105 | sonnet-5-5 | 361 420 | 118 719 | 1,9100 | 8,7 % |
| `extract.requirements` | 44 | sonnet-5-5 | 83 837 | 55 588 | 0,7236 | 3,3 % |
| `extract.requirements-check` | 41 | sonnet-5-5 | 73 651 | 38 597 | 0,5333 | 2,4 % |
| `generate.answer` | 27 | sonnet-5-5 | 70 420 | 26 289 | 0,4037 | 1,8 % |
| `generate.challenge` | 23 | sonnet-5-5 | 66 192 | 16 286 | 0,2952 | 1,3 % |
| `judge.citation` | 285 | sonnet-5-5 + **jev** | 187 406 | 17 608 | 0,2236 | 1,0 % |
| `extract.answer` | 11 | sonnet-5-5 | 11 070 | 9 465 | 0,1168 | 0,5 % |
| `generate.news` | 14 | sonnet-5-5 | 20 673 | 7 389 | 0,1152 | 0,5 % |
| øvrige 4 | 22 | sonnet-5-5 | 26 473 | 7 125 | 0,0911 | 0,4 % |

**Hele regningen er én oppgave.** `generate.brief` er 80 % av forbruket. Alt annet til sammen er $4,41/uke. Enhver rutingsdiskusjon som ikke handler om briefen er støy.

Verdt å merke: `judge.citation` har 285 kall — nest mest trafikk i hele systemet — til $0,22, fordi Jev tar dem og koden avviser de åpenbare før modellen ser dem. Det er den deterministisk-først-arkitekturen som virker, målt.

## 2. ENDRET

`TASK_MODEL_DEFAULTS` var tom (`models.ts:52`, kommentar: «Empty on purpose»). Nå fylt med 11 rader. Haiku 4.5 er eksakt halvparten av Sonnet på begge retninger ($1/$5 mot $2/$10), så hver rad er et 50 %-kutt på den oppgaven.

- **Haiku** — mekanisk arbeid: `extract.threshold`, `extract.criteria`, `extract.message`, `extract.answer`, `extract.cv`, `judge.classify`, `judge.fail-check`, `generate.news`, `generate.feilsjekk`, `route.helper`, **`generate.brief`**.
- **Blir på Sonnet** (ingen rad): bevis­kjeden `extract.requirements` + `-check`, `judge.assess`, `judge.semantic`, `extract.contract`, `extract.award`, `generate.answer`, `generate.challenge`, `generate.redteam`, `generate.draft`, `chat.helper`. Begrunnelse: feil her koster penger eller troverdighet.
- **Opus: ingenting.** Dobbel Sonnet-pris, og ingen oppgave har vist en feilkostnad som rettferdiggjør den. Eskalering gjøres per oppgave med `LLM_MODEL_<TASK>`.

Tester: 7 nye i `router.test.ts` (inkl. en vakt mot at tabellen tømmes igjen, siden to av løkketestene ville bestått trivielt på tom tabell). Den gamle testen «defaults every task to LLM_MODEL (no behaviour change)» er omskrevet — den beskrev den tomme tabellen, og kontrakten er nå at en per-oppgave-default **slår** `LLM_MODEL`. Én test i `feilsjekk/explain.test.ts` hardkodet `claude-sonnet-5` som stedfortreder for «et modellkall skjedde»; den spør nå ruteren i stedet, så den tåler framtidige rutingsendringer.

## 3. ETTER — projisert på de samme 7 døgnene

Reprising av faktisk forbruk under den nye tabellen (samme tokens, Haiku-priser):

| | USD/uke |
|---|---|
| Omrutede oppgaver, før | 17,8490 |
| Omrutede oppgaver, etter | 8,9245 |
| **Spart** | **8,9245/uke ≈ 38/mnd** |
| Andel av total regning | **40,6 %** |

**Men:** $8,79 av de $8,92 er `generate.brief` alene. Uten den raden er hele tabellen verdt **$0,14/uke (0,6 %)**. Jeg skriver det rett ut fordi det er den ærlige formen på resultatet: dette er ikke 11 forbedringer, det er én beslutning med ti små følgesvenner.

**Briefen trenger en menneskesjekk før deploy.** Den er det operatøren leser for å avgjøre et anbud. Det som gjør Haiku forsvarlig: utdata er skjemabundet (`completeJson(briefLlmSchema)`), hvert sitat verifiseres i kode før operatøren ser det (`lib/verify.ts`, `lib/citationFlags.ts`), og briefen caches per kildetekst-hash så en dårlig brief kjøres om, ikke betales om. Det som mangler: ingen har sammenlignet Haiku- og Sonnet-briefer på ekte anbud. Omgjøring er én env-var: `LLM_MODEL_GENERATE_BRIEF=claude-sonnet-5-5`.

## 4. PROMPT-CACHING: MÅLT NEI

Ordren ba meg slå det på. Det kan ikke fyre i denne kodebasen i dag, og her er hvorfor, med tall:

**Minimum cache-prefiks er modellavhengig** (Anthropic): **1 024 tokens på Sonnet 5**, **4 096 på Haiku 4.5**. Under grensen caches ingenting — ingen feil, bare `cache_creation_input_tokens: 0`.

Målt størrelse på hver system-prompt i `src/prompts/`:

`BRIEF_SYSTEM` 602 · `LEGAL_ASK_SYSTEM` 467 · `REQUIREMENTS_SYSTEM` 455 · `CONTRACT_SYSTEM` 423 · `CV_SYSTEM` 402 · `REQUIREMENTS_CHECK_SYSTEM` 382 · `ASSESS_SYSTEM` 379 · `KLAGE_EXTRACT_SYSTEM` 350 · `CHALLENGE_SYSTEM` 316 · `FEILSJEKK_SYSTEM` 242 · `DRAFT_SYSTEM` 237 · `INGEST_SYSTEM` 211 · `HARD_RULES` 205 · `REDTEAM_SYSTEM` 198 · `NEWS_BRIEF_SYSTEM` 164 · `CRITERIA_SYSTEM` 141 · `DIGEST_INTRO_SYSTEM` 66 tokens.

**Den største er 602 tokens.** Ingen av dem når 1 024. Alle er langt under 4 096, altså ville de aldri caches på Haiku uansett.

Og det eneste store innholdet som faktisk gjentas — anbudsteksten, som sendes to ganger i kravuttrekket (pass 1 + kontrollpass) — er utilgjengelig: caching er et **prefiks**-treff, rekkefølgen er `tools` → `system` → `messages`, og de to passene bruker ulike system-prompter (`REQUIREMENTS_SYSTEM` mot `REQUIREMENTS_CHECK_SYSTEM`). Prefiksen divergerer før dokumentet. Caching ville truffet null.

**Hva som måtte til for at det skal lønne seg** (foreslått, ikke gjort — det er prompt-omskriving med kvalitetsrisiko, og ikke bølge 0): gi begge kravuttrekks-passene identisk system-prefiks og flytt instruksjonsforskjellen ned i brukermeldingen etter en cache-markert dokumentblokk. Da ville pass 2 lese dokumentet fra cache til 0,1× pris. Gevinsten er taket på `extract.requirements-check`: $0,53/uke. Det er under en tiendedel av brief-beslutningen, så det hører i kø bak den.

## 5. FUNN SOM IKKE VAR OPPDRAGET

**273 kall ble avvist av API-et med http_400 mellom 8. og 11. oktober** — 17 % av alt modellarbeid i den uka:

| Oppgave | Avvist | Modell | Vindu |
|---|---|---|---|
| `judge.assess` | 168 | sonnet-5-5 | 08.–11.10 |
| `generate.brief` | 54 | sonnet-5-5 | 09.–11.10 |
| `extract.requirements` | 51 | sonnet-5-5 | 08.–10.10 |
| `generate.news` | 5 | sonnet-5-5 | 08.–10.10 |
| `judge.citation` | 5 (http_401) | jev-1.13.0 | 06.10 |

Null kostnad (400 faktureres ikke, og `costUsd` er null når `ok=false`), null retry (400 er ikke retrybar i `llm.ts`), og de stoppet etter 11. oktober. **Men et 400 betyr at arbeidet ikke ble gjort** — 168 kompetansevurderinger og 54 briefer forsvant stille i det vinduet. Årsaken er ikke diagnostisert; det var ikke mitt oppdrag. Jeg anbefaler én bølge-1-skive på det, fordi en stille 17 % bomrate er verre enn en dyr modell.

## 6. OPPRYDDING AV AGENTFLÅTEN (sidebemerkningen orchestrator-1 ba om)

Målt nå i `/home/nithu/code/Veldora`: **39 worktrees og 134 grener, 4,5 G** — og orchestrator-1 målte 42/137 åtte minutter senere. Jeg har **ikke slettet noe**; sletting er operatør-gated.

Kostnaden ved opprydding er lav i tid og høy i risiko hvis den gjøres blindt: hver worktree er ~1,5 G disk, men minst én (`infra-1/vakt-i-repo`, f47cd4d) har upushet arbeid som venter på push-gaten, og mine egne tre tools-1-grener likeså. **Trygt å slette** er bare en worktree der `git status` er tom *og* grenen er merget til `origin/main` — det er en 20-linjers sjekk per worktree, ikke en vurdering. **Ikke trygt** er alt med utrackede filer eller commits over `origin/main`; de må pushes eller forkastes først, og det er operatørens valg. Jeg kan levere skriptet som *lister* de to kategoriene uten å røre noe, hvis det blir bedt om.

## 7. STATUS

- Gren `tools-1/model-routing-defaults`, commit på egen gren, **upushet** (OK kjør-gaten).
- Testsuiten kjørt mot virkeligheten, ikke CI: 1 864 tester. `documents.test.ts` feiler 5 tester i full-suite-kjøring men passerer 6/6 alene — 5-sekunders timeout under last (fila importerer ingenting modell- eller rutingsrelatert, bekreftet med grep). Kontrollkjøring uten mine endringer gjort for å slå det fast.
- `node_modules` i worktreet er en symlenke til `Veldora-dok` sin (identisk `package.json` bortsett fra at dok-en har én ekstra avhengighet, altså et supersett). Lenken er ikke committet.
