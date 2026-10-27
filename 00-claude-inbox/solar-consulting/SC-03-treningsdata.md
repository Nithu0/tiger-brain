# SC-03 — treningsdata og en måling vi kan stole på (admin-1, 2026-10-16)

Branch `sc-03-treningsdata` (worktree `~/code/Veldora-sc03`), commits 4fc8f67 · 76a0514 · 9222ec7 · ef8d9a8 på origin/main 342d332. **Ikke pushet.**

## Levert (alle sju punkter)
1. **To målvariabler** — `crm/src/lib/learning/split.ts`: bid (COMPETITION) og respond (PLANNING). INVESTIGATE har ingen etikett. `sideOf` heter nå `reasonSideOf` (den velger årsaksliste, ikke etikett) i crm og dashboard. Alle lesere er gått gjennom: profile, agreement, similar (precedentRecords), triageAgents (legacy + stats), score.ts (ingen preferanse på dialog), morning-briefing og dashboardets trend og historikk. Profilen lærer bare bid; `profileOf` avviser profiler uten target.
2. **Snapshot v2** — fryser noticeType, aboveEeaThreshold, scopeScore, scopeCategory og kravtelling (weMeet), pluss `summaryMissing`. Kunngjøringsteksten ligger i egen kolonne `tender_text`. Migreringen backfiller bare noticeType og aboveEeaThreshold på gamle rader, merket `snapshot.reconstructed`. scopeScore backfilles bevisst ikke, fordi den lekker. Legacy-beslutninger er merket `reconstructed: true`.
3. **Påkrevd årsak på mulighetssiden** — `requireReasonedDecision` (beforeChange på Opportunities). En menneskelig beslutning utenom triage-endepunktet gir 400. Angre er tillatt.
4. **Kvalifikasjonsstatus** — `qualification` (yes / no-references / no-other / unknown), påkrevd på COMPETITION, både i server og dashboard (kø, mulighetsside, møte). Valg av årsaken `references` forhåndsvelger no-references.
5. **Tidsdelt testsett** — cutoff 2026-10-14 00:00 Oslo, DECISION orchestrator-1, ADR-0019. Manifest `3d6e21c0b2a5`, fixture med 142 rader fra read-only prod.
6. **Blindmodus** — forslaget vises først etter valget, og første valg lagres som `blindDecision`. `anchored` i manifestet = vist før valget, eller byttet etter avsløring.
7. **Issue 055** — `profileN: profile?.n ?? null`, og UI-et viser «Profilen er ikke bygget ennå».

## Målt
- `eval/TRIAGE-TARGETS-BASELINE.md` (+ txt), manifest-hash verifisert av skriptet. bid test 8 ja / 6 nei: fit 0,635 [0,32–0,92], prio 0,781 [0,49–1,00], winP 0,646 [0,31–0,92] (bootstrap 95 %). **Alle intervaller inneholder 0,5.** respond test: 0 ja, så AUC er udefinert.
- Issue 054 før/etter (`eval/profil-for-etter-2026-10-16.txt`, bare dev): n 110 → 62, foreslåtte regler 4 → 0, 18 av 156 features bytter fortegn (`kw:fagsystem` +0,33 → −0,44). Preferanseleddet bytter fortegn på 18 av 71 dev-konkurranser.
- Verifisert: migreringen up/down/up mot lokal PG18 (backfill rører bare v1-rader), snapshot-porten i takt. crm tsc 0, vitest 2725/2725. dashboard tsc 0, node:test 627/627, `next build` ok (før siste review-runde).
- Review (code-reviewer): H1 og M1–M5, L1, L4 er rettet. Gjenstår: L2 (gamle utkast), L3 og L5 (se under).

## Gjenstår / for operatør
- **Etter deploy:** kjør `npm run queue:job -- learn-preferences` én gang. Ellers er forslag og preferanseledd av til 02:50, fordi profiler uten target avvises (review L3).
- Gamle nettleserfaner uten kvalifikasjonsfeltet får 400 på konkurranser til de lastes på nytt (L5).
- Det rendrede triage-UI-et er ikke sett. Det krever en CRM med data. Noen må se på blindmodus og kvalifikasjonssteget.
- «Lignende beslutninger» vises fortsatt før valget og kan forankre. Det er utenfor omfanget.
- Operatørspørsmålet i 054 (hvorfor dialoger triageres 4× så ofte) er åpent.
- Det må triageres mer etter 14.10, særlig dialog-ja, før noen test-AUC kan skille modeller.
