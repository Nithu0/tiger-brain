# Handoff 2026-10-13 — learning-1, Veldora/anbud

Skrevet 18:40Z. Bussen har vært stille siden ~14:45Z; infra-1 skrev handoff 14:09Z. Bølge 2 ble
aldri fordelt til meg. **Ingenting står halvferdig, ingenting er pushet.**

## Hvor arbeidet ligger

Gren **`learning-1/triage-baseline`**, **9 commits ahead av `origin/main`**, siste `5a6595b`.

`FACT` Commitene er nåbare fra hovedutsjekkingen `/home/nithu/code/Veldora` — grenreferansen bor i
det delte objektlageret, så **arbeidet er trygt selv om worktreet forsvinner**. Worktreet selv
ligger i en scratchpad-sti under `/tmp` og kan bli ryddet; da trengs bare
`git -C ~/code/Veldora worktree prune`, og grenen består. Ny utsjekking:
`git -C ~/code/Veldora worktree add <sti> learning-1/triage-baseline`.

**Push venter «OK kjør».** Ingen av de 9 commitene rører kjørende kode: alt er nye skript under
`projects/anbud/crm/scripts/baseline/`, artefakter under `crm/eval/`, to issue-filer og ett
research-dokument.

## Hva som ble levert

**Måleriggen** — `crm/scripts/baseline/run-triage-baseline.sh` + fem SQL-filer
(`triage-baseline`, `scope-kategorier-19okt`, `sakstype-kryss`, `dokumentkilder`, `fixture-export`).
SQL i fil, sendt base64 via `railway ssh`, **ingen connection-string på kommandolinjen** (etter
lekkasjen 11.10), og hver måling kjører i en transaksjon med `SET TRANSACTION READ ONLY` så
Postgres selv avviser skriving. Garden er testet: den stoppet mitt eget første utkast.
Kjør: `cd projects/anbud/crm && ./scripts/baseline/run-triage-baseline.sh [--sql <fil>]`
(krever `railway link --project anbud --environment production`).

**Fire dokumenter med frosne artefakter ved siden av** (alle i `crm/eval/`, kopier i
`00-claude-inbox/Veldora/`):

| Dokument | Svarer på |
| --- | --- |
| `TRIAGE-BASELINE.md` | kø, beslutninger, scope-filter, verdi, CPV, score-AUC, utfall |
| `SCOPE-KATEGORIER-19OKT.md` | ja per kandidatkategori — grunnlaget for 19.10-beslutningen |
| `DOKUMENTKILDER.md` | hvor `documentsUrl` peker, og hva vi faktisk har lastet ned |
| `research/2026-10-13-medarbeiderundersokelser-ks-10faktor-og-pivoten.md` | KS/10-FAKTOR-forbeholdet |

**Nullmålingen er fixture** — `crm/eval/fixtures/tender-decisions-2026-10-13.json` (105 rader,
live tekst på alle 105 mot snapshot-sammendrag på 76) + snapshot-varianten + begge evalkjøringene.
`justification` er bevisst utelatt. Kjørbar **uten prod-tilgang**:
`npx tsx scripts/eval-scope-categories.ts eval/fixtures/tender-decisions-2026-10-13.json`
→ 13,3 % tapte ja / 69,6 % kuttede nei. NB: `tsx` og `node_modules` finnes ikke i noen
utsjekking, så `npx -y tsx@4.19.2` er nødvendig — det er grunnen til at ingen tidligere
eval-kjøring kunne lagres.

## Tallene som gjelder (mål på nytt før de brukes som fasit)

Kø 736–758 (krymper time for time når frister passerer) · 105 beslutninger: ja 30, nei 69,
undersøk 6 · `fitScore` AUC 0,577 / `priorityScore` 0,549 / `winProbability` 0,575 /
`scope_score` **0,678** — de tre første er uskillbare fra myntkast ved n=30 · scope-filter
kontrafaktisk: 48/69 nei kuttet, 4/30 ja tapt · verdi 386/758 køkvalifiserte (50,9 %) · CPV som
filter: beholder alle 30 ja **og** 64/69 nei, lift 1,05× · 59 `agent_verdict`-etiketter som ingen
kode leser · **13 av 30 ja (43 %) er førkonkurranse-dialog, ikke konkurranser** · `documents` =
0 rader · 0 av 1184 `documentsUrl` peker på en fil.

## Hva som ligger i kø

- **`issues/054`** — målvariabelen blander «vil by på» med «verdt å svare på i en dialog».
  Gater alle rangeringsoppgaver. Trinn 1 er én linje i `learnableRecords`. **HITL**, se spørsmål under.
- **`issues/055`** — `profileN` (`endpoints/triage.ts:305`) teller rader profilen ekskluderer.
  Meldt videre til code-1-lanen, **ikke tatt**.
- Ukespuls #2 (Nexus, egen lane) og forensics→lessons-koblingen står fortsatt parkert fra i morges.

## Operatør-gater

1. **Push av de 9 commitene** — «OK kjør».
2. **Ubesvart spørsmål som styrer 054:** markedsdialoger er 11,5 % av kunngjøringene men 43 % av
   beslutningene. Er det fordi de er raskere å vurdere, fordi køen løfter dem, eller fordi
   relasjonsbygging prioriteres bevisst? De to første betyr at dialogene bør ut av treningen; den
   tredje betyr at de skal ha egen rangering.
3. **pgvector på Railway-Postgres** (issue 019) — prod har kun `plpgsql`.
4. **Anthropic-kreditt tom + Google-token `invalid_grant`** (meldt 11.10, fortsatt åpne).
5. **Hvilket beløp er «terskelverdi»** i kriterium 3 — repoet definerer ingen konstant.
6. **Vilkårsavklaring per dokumentportal før adapterarbeid** — fem av seks krever innlogging.
7. **`firm-remote-executor@learning-1`** dobbeltkjører med panet. Den tok dagens første jobb kl.
   08:17, leverte bare permission-advarsler og satte `awaiting-verify`; jeg gjorde jobben i panet
   og rettet recorden. Alle åtte roller har samme oppsett.

## Lærdommen jeg vil at neste økt tar med

Jeg rettet meg selv tre ganger i dag, og alle tre hadde samme form: **jeg sluttet fra et fravær i
et tynt datasett til en årsak.**

1. «PR #144s 27 % er et snapshot-artefakt» → snapshot forklarer én rad. Årsaken var kode-drift
   (#147 utvidet `utvikling-ki` samme dag). #144 var riktig for sin egen kode.
2. «Ingen små kontrakter finnes» → `awards` har 54 beløp av 552. Doffin har kontrakter fra 0,3 MNOK.
3. «Vi henter ikke inn dette segmentet» → korpuset er 23 dager gammelt. Segmentet hentes inn.

Målingen koster to minutter hver gang; slutningen var ikke verdt å ta uten den. Det gjelder særlig
her, der n = 105 og alt er tynt. **Mål først, slutt etterpå.**
