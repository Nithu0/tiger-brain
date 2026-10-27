# Kan TEDs strukturerte kunngjøring løse sitat-med-sideref? — vurdering, 2026-10-11

**Fra:** triage-c · **Oppdrag:** 5 min kartlegging, ingen kode. Følger opp tools-1s
`2026-10-11_dokumentdekning.md` (documents-tabellen 0 rader, 782/782 uten dokument).

## 1. Hva vi henter fra TED i dag

`crm/src/lib/sources/ted.ts` (keyless v3 Search API, `TED_FIELDS`, 304 linjer). Henter i dag:
tittel, kort fritekst-beskrivelse (`description-proc`), oppdragsgiver, CPV, frister, verdi,
prosedyretype, varighet, vinnere, `document-url-lot` (portal-lenke — **lagres, aldri hentet**,
samme hull H2 som Doffin). Kastes/ikke bedt om: alt under BT-540/734/5421 (tildelingskriterier
navn+vekt+beskrivelse) og BT-67/750/809 (kvalifikasjons-/eksklusjonskrav). Disse feltene finnes i
TEDs eForms-feltkatalog (`docs.ted.europa.eu/eforms/latest/fields/`, FACT via nettsøk 2026-10-11:
BT-540 Award Criterion Description, BT-734 Name, BT-5421 Weight, BT-821 Selection Criteria Source)
og er samme mekanisme som feltene vi allerede ber om — men vi ber ikke om dem.

Kunngjørings-teksten som faktisk kan siteres i dag (`crm/src/lib/tenderText.ts:26`,
`verifySources`) er **kun `title + description`** — for TED altså `description-proc`, en kort
fritekst. Tildelingskriterier/kvalifikasjonskrav er IKKE i denne blob-en for noen kilde.

**FACT:** `crm/src/lib/qualification/eforms.ts` viser at et strukturert kriterie-tre allerede
finnes for Doffin — hentet via `doffinWebclient.ts` (udokumentert internt webclient-API) og lagret
på `tenders.qualificationCriteria` — men det brukes bare som **frø/kryss-sjekk** mot krav trukket
ut fra opplastede dokumenter (`eforms.ts:1-6`: «never the source of truth»), IKKE som en siterbar
kilde i `verifySources`/`buildSourceBlocks`. Samme hull finnes altså for Doffin som for TED — det
er ikke TED-spesifikt.

## 2. Gir TEDs XML feltene «Om anskaffelsen» trenger, siterbart?

| Felt | I TED i dag | Tilgjengelig i TED (ikke bedt om) | Form |
|---|---|---|---|
| Omfang/oppdrag | `description-proc` (kort fritekst) | — | fritekst, siterbar |
| Tildelingskriterier + vekt | nei | **ja** — BT-540/734/5421 | fritekst + tall, siterbar, BT-kode som seksjonsref |
| Kvalifikasjonskrav | nei | sannsynlig — BT-750/809/67-familien, samme katalog | fritekst, siterbar |
| Frister | ja (`deadline-receipt-tender-date-lot`) | — | dato |
| Kontraktstype (SSA-x, NS 84xx) | nei | **UNKNOWN** — dette er typisk i konkurransedokumentet/kontraktsvedlegget, ikke en egen eForms-BT i kunngjøringen | — |

`ASSUMPTION`: BT-750/809/67-feltene er hentbare via samme Search API-mønster som de 29 feltene vi
allerede ber om (ikke live-testet i dette oppdraget — 5 min-ramme, ingen kode).

Sitat-formen blir **seksjonsreferanse (BT-kode), ikke sidetall** — «Dokument s. 12» er fysisk
umulig fra en kunngjøring uten sider. Brief-skjemaet støtter allerede dette: `FactSource.kind` kan
være `'notice'` med `page: null, section: string | null` (`crm/src/lib/brief.ts:46-53`) — ingen
skjemaendring nødvendig, bare at `section` fylles med f.eks. «BT-540» i stedet for å stå tom.

## 3. Størrelse på jobben

**Ikke et nytt løp.** Moderat utvidelse av eksisterende TED-rør, samme mønster alle tre lag følger:

1. `ted.ts`: legg BT-540/734/5421(/5423)/750/809/67-feltene til `TED_FIELDS` + `tedNoticeSchema`,
   mapp til en ny `awardCriteria`/`qualificationCriteria`-struktur på `MappedTender` (Doffin-siden
   har allerede typen, se `eforms.ts NoticeCriterion`).
2. `tenderText.ts`: utvid `verifySources`/`buildSourceBlocks` til å ta med denne strukturen i
   kunngjørings-blob-en (ikke bare title+description), med BT-kode som seksjon.
3. `brief.ts`/`requirements.ts`: ingen skjemaendring (kind `notice` + `section` finnes), men
   `verifyLlmBrief`/ekstraksjon må faktisk få teksten servert.

Estimat: **1 dags arbeid**, ikke en ny pipeline — men det er en arkitekturbeslutning, ikke en
ren patch: `eforms.ts` sier i dag eksplisitt at notice-kriterier er «aldri sannhetskilde», bare
frø. Å la triage-kortet sitere kunngjøringen direkte er et bevisst brudd med det prinsippet og bør
stå i en ADR, ikke smettes inn stille — ellers gjentar vi H1-forvirringen tools-1 fant (kortet sier
ikke tydelig at sitatet er kunngjørings- ikke dokument-basert).

**Viktig sidepoeng:** fordi samme hull (kriterier lagret, ikke siterbare) gjelder Doffin også, og
Doffin dekker 471/782 mot TEDs 311/782, er den største enkelttiltaket å fikse blob-en for BEGGE
kilder samtidig — ikke bygge et TED-spesifikt løp. TED gir i tillegg en klarere juridisk
hjemmel (se §5) som gjør det tryggere å sitere derfra enn fra Doffins udokumenterte webclient.

## 4. Hvor mange av de 782 er TED, ikke Doffin?

**FACT** (tools-1, `2026-10-11_dokumentdekning.md`, read-only mot prod-Postgres 2026-10-11
~16:30 CEST): **Doffin 471 · TED 311** av 782 i triage-køen.

`UNKNOWN`: hvor mange av de 311 TED-radene er duplikater av en Doffin-rad for samme anskaffelse.
`crm/src/lib/tenders/upsert.ts:89` dedupliker bare på `(source, externalId)` — **ikke** på tvers av
kilder via `procedureId`, selv om Doffin-notiser over EU-terskel sendes videre til TED
(`doffinWebclient.ts` har feltet `tedId`/`sentToTed`). Noe av de 311 kan derfor allerede ha en
Doffin-tvilling i køen med samme dekningshull — da låser TED-fiksen ikke 311 nye muligheter, bare
et uvisst mindretall av dem. Ikke undersøkt videre (utenfor 5-min-rammen).

## 5. Har Doffin noe tilsvarende strukturert nedlasting?

**FACT** (`data/sources/doffin.json`): et offisielt API finnes (`dof-notices-prod-api
.developer.azure-api.net`, endepunkt «Public»), men krever registrering/abonnement og
gjenbruksvilkårene er **UNKNOWN** (ikke synlig uten innlogging). Det koden faktisk bruker i dag
(`doffinWebclient.ts`) er et **udokumentert, internt webclient-API** — fungerer, men kan endre seg
uten varsel og har ukjente rate limits/vilkår (README-TODO, ikke jurist-sjekket).

**FACT** (`data/sources/ted.json`, TEDs eget «legal notice», hentet 2026-08-30): kunngjøringer «can
be freely reused, for commercial or non-commercial purposes» (EU-kommisjonens 2011-beslutning om
gjenbruk), metadata CC0. Ikke en automatisk jurist-frikjenning av vår konkrete bruk, men en
vesentlig klarere hjemmel enn Doffins webclient eller TendSign/Mercell-portalene H1 er blokkert av.

## Konklusjon

TED-XML-en dekker tildelingskriterier+vekt og trolig kvalifikasjonskrav, siterbart med BT-kode som
seksjonsreferanse (ikke sidetall) — brief-skjemaet støtter formen allerede. Jobben er en utvidelse
av eksisterende rør (~1 dag), ikke nytt løp, men er en arkitekturbeslutning (notice som
sannhetskilde, ikke bare frø) som bør gjennom en ADR. Den løser **ikke** H1 generelt: 782/782
mangler fortsatt ekte konkurransedokumenter med sidetall; TED/Doffin-notice-kriterier er et
begrenset, men juridisk tryggere, delvis-plaster — og bør gjøres for begge kilder samtidig, ikke
TED alene, siden Doffin dekker 60 % av køen mot TEDs 40 %, og et ukjent antall av TED-radene
sannsynligvis dupliserer en Doffin-rad.
