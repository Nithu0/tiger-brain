---
tags: [command-center, brain, distill, data-1, overlevering]
type: handover
role: data-1
pane: synlig
dato: 2026-10-14
---

# data-1 → orchestrator-1: full overlevering

Operatøren wrapper opp og vil se alt som er levert. Dette er hele dagens leveranse fra
data-1, med det som er avgjort, det som gjenstår, og det jeg tok feil på.

## 1. Hva som er levert

| # | Leveranse | Hvor | Status |
|---|---|---|---|
| 1 | Distill-hullet målt — omfang, årsaker, G4-historikk, varslingsanalyse, kostnad | `00-claude-inbox/command-center/2026-10-14_distill-gap.md` §1-7 | ferdig |
| 2 | Retry-veien skrevet (spor A/B/C med eksakt SQL) | samme rapport §4 | ferdig |
| 3 | Spor B **kjørt** etter operatør-påfylling — 456 av 457 rader for 13.10 | samme rapport, RESULTAT-seksjon | ferdig |
| 4 | Diagnose-avgjørelsen du ba om 09:50Z | §3 i dette dokumentet | **avgjort** |
| 5 | Kostnadssvaret du etterlyste to ganger | §4 | svart, med forbehold |
| 6 | Dødbrev-designet (radnivå mot dagnivå) | §5 | anbefaling, ikke bygget |
| 7 | Minne + rollefiler oppdatert | `project_distill_gap_anatomy.md`, `agents/data-1/{GOALS}.md` | ferdig |

Ingen kode endret. Ingenting pushet. Ingen `_bin/`-filer rørt. Én skriving til
`agent_tasks` (re-kø av én eksisterende rad, ingen ny rad).

## 2. Tilstanden nå (målt 2026-10-14T12:13Z)

| dag | udistillert | hva det er |
|---|---|---|
| 2026-10-13 | **1** | rad 15061 — dødbrev, trenger kodefiks |
| 2026-10-12 | 1 | rad 14960 — dødbrev, annen årsak |
| 8 dager juni-juli | 49 | delvise hull, retryes aldri av design |
| 2026-10-14 | 163 | i dag, nattens ordinære kjøring tar dem |

Reelt etterslep: **51 rader over 10 dager.** 15 605+ verbatim, 15 454+ objekter.

## 3. Diagnosen er avgjort — og uenigheten var min feil

**Du hadde rett. Det er trunkering mot `max_tokens`, ikke innhold.**

Først korreksjonen, fordi den forklarer hele uenigheten: **de to diagnosene gjaldt aldri
samme rad.** I 09:36Z-meldingen skrev jeg at «13.10 feilet på validering». Det var feil
språk fra min side — jeg mente *natten til 13.10*, som destillerte **datoen 12.10**.
Oppdelingen er:

- **rad 14960 (dato 12.10)** — `room_assignments[].type: invalid "feature"`. Validering.
- **rad 15061 (dato 13.10)** — `Unterminated string at position 3530` → trunkering.

Rapportfilen min hadde tabellen riktig (natt → dato), men inbox-linja komprimerte den feil
og skapte en konflikt som ikke fantes. To rader, to datoer, to feilklasser.

**Beviset for trunkering, uten å betale for et nytt kall.** Du ba om `stop_reason`; koden
leser den ikke, så den finnes ikke i noen logg. Men de 456 radene som *lyktes* i natt gir
svaret statistisk:

```sql
-- JSON-lengde = feltene + skjema-skaffold (~190 tegn), over de 456 radene fra kjøringen
WITH o AS (SELECT LENGTH(exchange_core)+LENGTH(specific_context)+LENGTH(room_assignments_json)
                  +LENGTH(entities_json)+LENGTH(decisions_json)+LENGTH(unresolved_questions_json)
                  +LENGTH(next_actions_json)+190 AS json_chars
           FROM memory_objects WHERE created_at >= '2026-10-14')
SELECT COUNT(*), ROUND(AVG(json_chars)), MAX(json_chars) FROM o;
```

| n | snitt | maks | maks i tokens (≈3,6 t/tok) | andel av taket 1024 | rader over 80 % | rader over 90 % |
|---|---|---|---|---|---|---|
| 456 | 1 252 tegn | 2 890 tegn | ~803 | **78,4 %** | **0** | **0** |

Fordelingen er **sensurert ved taket**: ingen av 456 vellykkede rader kommer over 80 % av
1024 tokens. Det er ikke fordi ingen utveksling fortjener et lengre svar — det er fordi en
rad som trenger mer enn taket *ikke kan havne i den vellykkede populasjonen i det hele
tatt*. Og den ene raden som falt ut knakk på posisjon 3530 tegn, linje 59 — altså rett
over der sensuren begynner. (Tett JSON ligger nærmere 3,0-3,3 tegn/token enn prosa-3,6, så
3530 tegn er snarere ~1 070-1 180 tokens: forbi taket, ikke under det.)

**Konklusjon:** taket er den bindende begrensningen, feilmeldingen er en innholdsfeil som
maskerer en avkutting, og `distill.ts:148`-fiksen min treffer en *annen* rad enn den vi
nettopp mistet. Begge fiksene trengs, men de er ikke alternativer.

## 4. Kostnaden — svart, med et forbehold som er sitt eget funn

**Jeg kan ikke måle faktisk forbruk.** Det finnes ingen tokenmåler i loopen:
`distill-pipeline` kaster `usage` fra API-svaret uten å lagre det, og `cost-guard-api.sh`
melder «no usage log yet — meter pending». Det er code-1s lane, og det er grunnen til at
spørsmålet ditt ikke kan besvares med en kommando.

Det jeg kan stå for, to uavhengige anslag for de 456 radene:

| metode | regnestykke | USD |
|---|---|---|
| token-modell | 441 ktok inn × 1,00 + 205 ktok ut × 5,00 per MTok | 1,47 |
| målt historikk | 456 × 0,0037 (juni: USD 42 / 11 295 rader) | 1,69 |

**Altså USD 1,5-1,7 mot anslaget ditt på 1,50 — innenfor.** Men det er et anslag som
bekrefter et anslag, ikke en måling. Så lenge ingen lagrer `usage` er «hva kostet natten»
et spørsmål systemet ikke kan svare på, og det er verdt mer enn dette ene tallet.

## 5. Dødbrevene — designsvaret

Du spurte om radnivå mot dagnivå. Svaret er at det ikke er køens granularitet som er feil,
men **hva executoren kaller en feil**:

`executors.ts` kaster hvis `errors.length > 0`, uansett hvor mange rader som lyktes. En
task som destillerte 456 av 457 blir derfor `failed 3/3`. Det er to tap i ett: dagen blir
*delvis*, og delvise dager hopper catch-upen over med vilje
(`nightly-distill.ts:176-182`) — så den ene raden blir usynlig for alltid, og de to
retryene betalte for ingenting.

**Anbefaling, i prioritert rekkefølge:**

1. **Skill delvis suksess fra total fiasko.** Kast bare når `distilled === 0 && errors > 0`.
   Destillerte den noe, er tasken fullført *med dødbrev* — ikke feilet. Dette alene fjerner
   de meningsløse re-forsøkene og de falske `failed`-radene som maskerer varslingen.
2. **Gi dødbrevene egen kø.** Radnivå, ikke dagnivå: ett `agent_tasks`-innslag per feilet
   verbatim-rad, slik at den kan retryes uten å dra en hel dag med seg. Dagnivå er riktig
   for normaldrift og feil for unntakene.
3. **`stop_reason`-sjekk** i `haiku-distiller.ts` — ved `max_tokens`, ett nytt forsøk med
   dobbelt tak og en feilmelding som sier «avkuttet», ikke «ugyldig JSON». Jeg er enig i
   din vurdering: retry på trunkering, ikke heve taket for alle 15 000.
4. **`distill.ts:148`** degraderer ukjent `room_assignments[].type` til `concept`. Lukker
   14960-klassen.

De to kjente dødbrevene (14960, 15061) er en gratis regresjonssuite som alt ligger i basen.
Ingenting av dette er startet — det er kode, og jeg venter på klarering.

## 6. Det jeg tok feil på i dag

- **«13.10 feilet på validering»** (09:36Z) — feil. Det var 12.10. Natt-mot-dato-forveksling
  i inbox-linja, og den kostet deg en runde med å avstemme to diagnoser som ikke var uenige.
  Rapportfilen var riktig; sammendraget var ikke.
- **«failed-task-varsling mangler»** — jeg leste CLAUDE.md som sannhet før jeg målte.
  Varslingen finnes i to kanaler. At de er utette er et annet og verre funn.

## 7. Det jeg IKKE tok, som du ba meg la ligge

Hook-taket (`firm-hook-session-start.sh`, 6,97 s mot 10 s, 7 timeouts kl. 07:52) og
morgenbrief-cronen uten catch-up. Begge i `_bin/`, begge hos infra-1/tools-1. Jeg har ikke
rørt dem. Din kobling 10:25Z er riktig og gjelder også min lane: **kontosaldo er ikke
tjenestehelse.** To tomme kontoer på én dag, begge funnet ved flaks. Det som overvåkes må
inkludere evnen til å betale.

## 8. Åpne operatørgater i mitt domene

1. **De 49 radene** over 8 delvise juni/juli-dager (spor C, ≈ USD 0,17). De kommer aldri av
   seg selv. Enten køes de, eller de avskrives bevisst.
2. **De fire kodefiksene i §5.** Alle i min lane, ingen startet.
3. **Tokenmåleren** (code-1s lane) — uten den er «hva kostet dette» ubesvarbart, hver gang.

— data-1, 2026-10-14T12:15Z
