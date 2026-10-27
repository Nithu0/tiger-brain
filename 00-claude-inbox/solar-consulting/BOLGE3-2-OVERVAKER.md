# BØLGE 3.2 — overvåker: SPEC (til godkjenning, ikke bygget)

trading-1, 2026-10-18. Oppdrag fra orchestrator-1. Bygger på [AGENT-GRANSKNING.md](AGENT-GRANSKNING.md) §5 bølge 3 og §6.6,
agentstandarden (`projects/anbud/docs/agenter.md`, #193) og det som finnes på `origin/main`: `watch-match`, `lib/watch.ts`,
`radar-expiry` + `lib/radar/expiry.ts` (paal-1), kjøperprofilen `buyer.profile` (tools-1, 3.1/#218), lese-verktøyene i `lib/agents/tools`.
Tall: `crm/eval/overvaker-grunnlag-2026-10-18.txt` (prod, read-only skriptfil, SQL testet mot engangs-PG18 først).

## Kort

- **Én overvåker, tre strømmer, og modellen bare der koden er usikker.** (A) tidlige signaler hos kjøperne våre, (B) utløpsradaren, (C) nye kunngjøringer som ligner tidligere ja.
  B er ren kode. A og C bruker et enkeltkall (ikke sløyfe) bare for tvetydige saker. Alt annet avgjøres i kode, som i dag.
- **Ingen ny task, ingen migrering.** A og C bygges inn i `watch-match`, som allerede køes per kunngjøring av `classify` og sveiper de siste 14 dagene hver natt.
  B leses av `morning-briefing` rett fra `retender-predictions`. Bak flagget `MONITOR_AGENT_ENABLED` (av). Med flagget av er `watch-match` uendret.
- **Kost:** anslått ≤ 0,15 USD per døgn ved dagens volum, med tak 0,50 USD per døgn (døgntaket i `lib/llm.ts`, #205). Dagens totale modellkost er 0,6–2,4 USD per døgn (12,8 på en uteliggerdag).

## Hva som finnes, og hva som mangler (FACT, prod 2026-10-18)

| | I dag | Mangler |
|---|---|---|
| Tidlige kunngjøringer | `watch-match` merker PLANNING + markedsdialog-ord som `early.signal` når fit ≥ 40 eller et produkt treffer. 68 signaler på 30 d | Ingen vurdering av *hva* dialogen gjelder. Nøkkelord bommer begge veier. 8,7 tidlige kunngjøringer per dag, 126 på 30 d hos 23 av våre 42 kjøpere |
| Utløpsradar | `radar-expiry` hver natt: 22 prediksjoner, 12 innen 6 mnd, 18 innen 12 mnd. Ett `radar.retender`-signal når topp-20 endres | Ingen enkeltvarsel når *en* kontrakt hos *våre* kjøpere går inn i forberedelsesvinduet |
| Ligner tidligere ja | Ingenting. `watch-match` matcher bare mot forventede anbud (`watch-items`) | 31 ja (STRONG_BID/BID) i trening, 10 i test (cutoff 2026-10-14, ADR-0019) |

## Rolle og mål

Overvåkeren leser det som kommer inn hver dag og sier fra om det teamet ellers ville gått glipp av: en markedsdialog hos en kjøper vi har
vurdert, en kontrakt vi kan ta som snart lyses ut på nytt, og en ny kunngjøring som ligner det vi har sagt ja til før. Den gir aldri
bud/ikke-bud, skriver aldri `decision` og lagrer aldri kontaktpersoner.

## Strømmene

### A. Tidlige signaler hos våre kjøpere (hendelsesdrevet + nattsveip)

- **Hvem:** «våre kjøpere» = kjøpere med en mulighet besluttet STRONG_BID/BID/INVESTIGATE, eller med en tildeling til oss (`OUR_ORG_NUMBERS`). Regnes i kode.
- **Kode først:** `isEarlyNotice` (PLANNING eller dialogord), som i dag. Hos våre kjøpere: alltid kandidat. Hos andre: kandidat bare med fit ≥ 40 eller produkttreff (dagens `early.signal`-regel, uendret).
- **Modellen:** ett kall per kandidat hos våre kjøpere, og bare når koden ikke kan avgjøre: fit mellom 20 og 60, eller ingen produkt- eller CPV-treff.
  Spørsmålet er smalt: *Gjelder dialogen noe innenfor våre tre scope? Svar med scope (lukket liste) eller «nei», og ett ordrett sitat fra kunngjøringen.*
  Haiku 4.5 (klassifisering, agentstandarden §3.1). Strukturert output (`outputSchema` når #219 er merget).
- **Output:** signal `early.signal` som i dag, beriket med `data.monitor = { scope, quote, quoteVerified, model }`. Ingen nye topics i innboksen.

### B. Utløpsradar (nattlig, ingen modell)

- **Kilde:** `retender-predictions` (paal-1s radar). Den brukes som den er og regnes ikke på nytt. Kjøperprofilens `facts.expiring` (3.1) er samme kilde.
- **Regel i kode:** en prediksjon med `earliest_end` innen 6 mnd (radarens `RADAR_LEAD_MONTHS`), i vertikal it/sol, hos en av våre kjøpere eller med importance i topp-20 → én linje i morgenbrifen
  «forbered: <tittel> hos <kjøper>, sittende <leverandør>, slutt <dato>». Én gang per prediksjon (nøkkel `t:<rootTenderId>`), og på nytt bare hvis datoen flytter seg mer enn 30 dager.
- **Output:** signal `radar.expiring` (FACT, data = prediksjonen med kilde-id). Den eneste nye topicen, og den får en egen linje i `lib/inbox.ts`.

### C. Ligner tidligere ja (hendelsesdrevet per ny COMPETITION-kunngjøring)

- **Prekvensielt (ADR-0019):** en kunngjøring sammenlignes bare med beslutninger som var tatt *før* den ble publisert. Testrader (fra 2026-10-14) brukes aldri til å justere noe.
- **Kode først:** likhet mot tidligere ja og nei med de samme featurene triage-profilen bruker (`lib/learning`, `snap_*`-felt): CPV-prefiks, kjøper, scope og ord i tittel/beskrivelse (TF-IDF, ingen embeddings, siden prod ikke har det).
  Skåren er differansen mellom likhet til nærmeste ja og nærmeste nei.
  - Høy skår (topp-bånd): signal direkte, uten modell.
  - Lav skår: ingenting.
  - **Tvetydig bånd:** ett modellkall (Haiku) med kunngjøringen og de 3 nærmeste ja og nei (titler + teamets begrunnelse fra `tender-decisions`, ingen personnavn).
    Spørsmål: *Ligner denne mest på ja-sakene eller nei-sakene? Svar ja/nei/uklart med ett sitat fra kunngjøringen og id-en til saken den ligner mest.*
  - Grensene i båndet settes på trening (dev), ikke på test.
- **Erstatter nøkkelordsmatchen bare for tvetydige saker:** `watch-match` sin `matchTender` mot `watch-items` står uendret. Overvåkerens C kommer i tillegg og vises som «ligner tidligere ja».
- **Output:** signal `early.signal` med `data.monitor.kind = 'similar'`, eller `tender.similar` hvis du vil skille det i innboksen. Det siste krever bare en linje i `lib/inbox.ts`.

## Selvkontroll (i kode, hver kjøring)

1. Sitatet finnes ordrett i kunngjøringsteksten (`verify.ts`). Feiler det, faller signalet tilbake til kodens avgjørelse og merkes «ikke verifisert».
2. Scope og ja/nei er lukkede lister (skjema). Andre verdier avvises.
3. Ingen kontaktdata: modellsvaret avvises hvis det inneholder e-post, telefonnummer eller ord fra `stripContacts`-listen. Data som sendes inn har kontaktfeltene fjernet (`stripContacts`), som i rå-arkivet.
4. Ingen `decision*`-felt i noe output (decision-guard håndhever det uansett).
5. Én varsling per (kunngjøring, strøm). Idempotent ved nattsveip.

## Eval (forhåndsregistreres i egen commit før første kjøring)

| Strøm | Sett | Metrikk | Port |
|---|---|---|---|
| A | 30 tidlige kunngjøringer hos våre kjøpere siste 60 d, trukket med frø, merket relevant/ikke av en eier (**HITL, ~20 min**) før kjøring | presisjon og recall for «relevant» | presisjon ≥ 0,80 og recall ≥ 0,80, og ikke lavere recall enn dagens `early.signal`-regel på samme sett |
| B | ren kode | enhetstester mot `retender-predictions`-former | ingen modell, ingen port utover grønne tester |
| C | testraden COMPETITION-kunngjøringer besluttet fra 2026-10-14 (10 ja, fryst manifest fra SC-03), prekvensielt | recall av ja blant flaggede, og andel flagget | recall ≥ 0,90 (9 av 10) **og** andel flagget ≤ andelen nøkkelordsporet (`scope_score ≥ terskel`) flagger på samme rader |

`ASSUMPTION`: n = 10 ja i testen er tynt, og én bom er 10 prosentpoeng. Resultatet rapporteres med intervall, og «holder» betyr skyggemodus først
(signal logges, vises ikke i morgenbrifen) i 2 uker før operatøren slår det på.

Kost for eval: A ≈ 30 Haiku-kall, C ≈ 10–30 kall. Under 0,20 USD totalt.

## Kost per døgn (ASSUMPTION, overslag fra MODEL_PRICES)

- A: ~4 kandidater per døgn hos våre kjøpere (126 / 30), anslagsvis halvparten tvetydige → ~2 Haiku-kall à ~3k inn / 200 ut ≈ 0,01 USD.
- C: ~30 nye COMPETITION-kunngjøringer per døgn, ~20 % i tvetydig bånd → ~6 kall à ~5k inn / 300 ut ≈ 0,04 USD.
- B: 0.
- **Sum ≈ 0,05–0,15 USD per døgn. Tak 0,50 USD per døgn** for oppgavene `monitor.early` og `monitor.similar`. Over taket faller strømmene tilbake til ren kode og sier fra i morgenbrifen (rapporterer, deaktiverer ikke).

## Byggerekkefølge (når du godkjenner)

1. B (ren kode, ingen modell): `radar.expiring` + linje i morgenbrifen. Liten PR.
2. Forhåndsregistrering for A og C (egen commit), og operatøren merker de 30 A-radene.
3. C i skyggemodus (koden + modellen i tvetydig bånd), eval på testraden.
4. A, eval på de merkede radene.
Hver del bak `MONITOR_AGENT_ENABLED`, test lokalt mot engangs-PG18, én push per PR.

## Åpne spørsmål til deg

1. Skal C få egen topic (`tender.similar`) i innboksen, eller gå inn som en variant av `early.signal`? Anbefaling: egen topic, siden det er en annen handling for teamet (vurdere nå, ikke følge med).
2. A krever at en eier merker 30 rader før evalen. Godtar du det som HITL-steg, eller skal A vente?
3. Ingen migrering i planen. Hvis du vil ha C som egen task (egen kø, egen agent-run-logg), trengs en enum-migrering, og den kan gå i samme kø-plass som b23.
