# PR-tekst SC-03 (brukes når «OK kjør» kommer)

**Tittel:** feat(anbud): to målvariabler, snapshot v2, kvalifikasjon, blindmodus + tidsdelt testsett (SC-03)

Branch `sc-03-treningsdata`. Migrering `20261016_092001_sc03_treningsdata` (nr. 1 i migreringskøen).

## Hva
- To målvariabler: `bid` (COMPETITION, «vil by på konkurransen») og `respond` (PLANNING, «verdt å svare på dialog/RFI»). INVESTIGATE er ikke et ja. Profilen lærer bare `bid` (issue 054).
- Snapshot v2 fryser alle trekk ved beslutningstidspunktet. Gamle rader får `noticeType` fylt inn bakover, merket `reconstructed`. scopeScore fylles bevisst ikke inn, fordi den lekker.
- `qualification` («kunne vi kvalifisert oss?») er påkrevd på konkurranser. Blindmodus lagrer `blindDecision`. Kunngjøringsteksten ligger i egen kolonne `tender_text`.
- En beslutning uten årsak utenom triage-skjemaet avvises. Issue 055: `profileN` er null uten profil.
- Tidsdelt testsett med cutoff 2026-10-14 00:00 Oslo (ADR-0019) og manifest `3d6e21c0b2a5`. Eval-skript med AUC og CI per målvariabel (`crm/eval/TRIAGE-TARGETS-BASELINE.md`).
- `npm run requeue:extract` er tørrkjøring som standard, for de døde extract-requirements-jobbene.

## Etter deploy — operatør
1. **Kjør `npm run queue:job -- learn-preferences` én gang** i crm-tjenesten. Profiler bygget før splitten avvises. Uten kjøringen er forslagene og preferanseleddet i prioriteten av til nattjobben 02:50.
2. **Forvent synlig endring i forslagene. Det er ikke en feil.** Profilen går fra n = 110 til 62 og fra 4 foreslåtte regler til 0, fordi dialoger og INVESTIGATE ikke lenger lærer konkurranse-profilen. På dev-dataene bytter preferanseleddet fortegn for 18 av 71 konkurranser, og `kw:fagsystem` går fra positiv til negativ lift (`crm/eval/profil-for-etter-2026-10-16.txt`). Dialoger får ingen forslag.
3. Åpne faner med gammel dashboard-bundle får 400 «Velg om vi kunne kvalifisert oss» på konkurranser til siden lastes på nytt.
4. (Operatørgatet, separat) `npm run requeue:extract` for å se planen, og `-- --apply` for å køe. Det gir ett haiku-kall per mulighet.

## Verifisert
- Migreringen er kjørt up, down og up igjen mot lokal Postgres 18. Backfillen rører bare v1-rader, og down er ren. Snapshot-porten er i takt.
- crm: tsc 0, vitest 2725/2725. dashboard: tsc 0, 627/627, `next build` ok.
- Kodereview: H1, M1–M5, L1 og L4 er rettet.
- Ikke sett: de rendrede triage-sidene (blindmodus, kvalifikasjonssteget). Det krever en CRM med data.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01YK3aJLuiZMGeviNyp7xonb
