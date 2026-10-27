# 25 — Rettspraksis og forarbeider: kildekartlegging fase 2

admin-1, 2026-10-15, les-only mot verden (ingen innlogging/kjøp). Scope: de to rettskildeklassene
korpuset mangler helt. Skjema følger `data/sources/*.json` (15+ felt); levert som tabell + note per
felt som er langt. Alle statuskoder er faktiske `curl`/`WebFetch`-kall i dag, 2026-10-15.

## 1. Domstolene — rettspraksis

**Konklusjon: finnes ikke maskinlesbart og gratis noe sted. Lovdata.no er eneste frie kanal, og den
er robots-sperret for alt annet enn 5 navngitte søkemotorer — og selv de er sperret fra selve
dommene.**

| Felt | Verdi |
|---|---|
| id/name | `rettspraksis-lovdata` — Høyesterett/lagmannsrett/tingrett/EMD via lovdata.no |
| url | `https://lovdata.no/register/avgj%C3%B8relser` → 200 |
| access_method | web-ui, ingen API/datasett |
| cost | gratis å lese, ingen nøkkel |
| technically_fetchable | **RED** |
| ai_processing_rights | RED (robots) |

`curl https://lovdata.no/robots.txt` (200, hentet 2026-10-15) — ordrett:
```
User-agent: ChatGPT-User
Disallow: /
User-agent: GPTBot
Disallow: /
User-agent: *
Disallow: /
```
og for de 5 tillatte søkemotorene selv: `Disallow: /dokument/*/avgjorelse/*` — Google/Bing får ikke
engang crawle avgjørelse-sidene. Dette er strengere enn det `lovdata.json` allerede har registrert
(generell catch-all); den nye, konkrete regelen er at **ingen** robot, inkl. tillatte søkemotorer,
får dommesidene.

**api.lovdata.no bekreftet live i dag** (`GET /v1/publicData/list`, 200): nøyaktig 4 datasett —
`lovtidend-avd1-2026.tar.bz2`, `gjeldende-lover.tar.bz2`, `gjeldende-sentrale-forskrifter.tar.bz2`,
`lovtidend-avd1-2001-2025.tar.bz2`. **Ingen av dem er rettsavgjørelser eller forarbeider** — Lovtidend
avd. I er lover/forskrifter, ikke traktater (avd. II) eller dommer. Bekrefter brief-punktet.

**Direktør-sitat, Rett24 2025-11-03** (`lovdata-apner-hele-lovverket-for-ki-utviklere`): Lovdata åpnet
*kun* lov/forskrift for API, uttrykkelig ikke avgjørelser — «Dette er statiske dokumenter, i
motsetning til regelverket», og nye avgjørelser er inntektsgrunnlag Lovdata ikke vil gi bort.

**domstol.no**: `robots.txt` → 302 (omdirigerer, ikke sjekket til endestasjon). Et eget API fra
Domstoladministrasjonen (Aktørportalen) ble **ikke** fullført/åpnet for tredjepart (websøk, ikke
primærkilde — se Domstoladministrasjonen). Høyesterett publiserer et utvalg selv
(`domstol.no/no/hoyesterett/avgjorelser/...`), men dette er samme HTML-kanal, ikke en egen
maskinlesbar kilde. **UNKNOWN**: om domstol.no har et separat, ikke-indeksert API — ikke funnet i dag.

## 2. Kommersielle rettskildetjenester (kostnadsbeslutning)

| Tjeneste | Pris (publisert, hentet 2026-10-15) | Maskinell bruk / AI i vilkår |
|---|---|---|
| **Lovdata Pro** | `lovdata.helpscoutdocs.com/article/204-priser`: bedrift 1 bruker kr 6 500/år, 1–3 kr 12 500, 4–6 kr 19 900, 7–10 kr 25 900, …101–120 kr 179 900 (eks. mva, årsfakturert) | Ikke funnet i prislisten selv; `lovdata.no`-vilkårene (allerede i korpuset) forbyr massenedlasting uansett abonnement — **UNKNOWN** om Pro-avtalen åpner for API-uttrekk til en LLM |
| **Rettsdata (Gyldendal)** | Ikke publisert — «etter avtale»/medlemsrabatt via Advokatforeningen (50 % år 1 for nyetablerte). Pris ikke funnet offentlig i dag | **UNKNOWN**, vilkår bak `rettsdata.no/legal/bruksbetingelser` ikke lest (ikke forsøkt hentet — prioriter om B2 blir aktuelt) |
| **Juridika** | `juridika.no/produktkatalog`: Premium 21 990 kr/år eks. mva; fagpakker (Prosess, Eiendom, Kontrakter/Selskap) 5 990–6 990 kr/år hver | Ikke funnet i produktsidene; brukervilkår-lenke funnet men ikke lest i dag — **UNKNOWN** |

Alle tre er **betalingsmur + lov å lese, ikke å maskinbehandle** inntil eksplisitt avklart. Ingen av
dem er skrapet eller kopiert (regel 3).

## 3. Forarbeider

| Felt | `stortinget-forarbeider` | `regjeringen-nou` |
|---|---|---|
| url | `data.stortinget.no` | `regjeringen.no/en/find-document/norwegian-official-reports/id1767/` |
| access_method | REST, XML (JSON **ikke** støttet for publikasjoner — verifisert i dag: «Publikasjoner er ikke tilgjengelige som JSON») | web-søk; RSS finnes for NOU-varsling (`regjeringen.no` RSS-oversikt), ingen API funnet |
| authentication | ingen | ingen |
| cost | gratis | gratis |
| completeness | Innstilling, Proposisjon, Dok8, referater — **fulltekst i XML**. NOU **ikke bekreftet** som egen Stortinget-publikasjonstype i dag (kun websøk, ikke verifisert via API-kall) | NOU- og proposisjonslister, fulltekst på siden, ingen maskinell eksport funnet |
| technically_fetchable | **YELLOW** (API finnes, NOU-dekning uverifisert) | **RED** (ingen API/datasett funnet, kun web-ui) |
| licence_status | kildeplikt («oppgi Stortinget som kilde», FACT fra `stortinget.json`), ellers UNKNOWN | UNKNOWN — lisenstekst ikke funnet i dag, kun lenke til «Right of use... for photos and video», ikke dokumenttekst |
| next_action | Verifiser med et faktisk API-kall om `Innst.`/`Prop.` dekker FOA/anskaffelsesloven-forarbeider (Prop. til anskaffelsesloven 2016), og om NOU-er ligger under en annen publikasjonstype | Sjekk om NOU-tekst er NLOD eller ren copyright; RSS-feed for NOU er kandidat for varsling, ikke for fulltekst-inntak |

**Ikke verifisert i dag** (tidsbudsjett): den konkrete Prop./Innst.-IDen for anskaffelsesloven 2016 og
FOA 2016, og om `data.stortinget.no` returnerer NOU i `publikasjon`-endepunktet. Dette er neste
konkrete handling, ikke en antakelse.

## 4. EFTA-domstolen og ESA

| Kilde | Maskinlesbart? | Robots (hentet i dag) |
|---|---|---|
| EFTA Court (`eftacourt.int/cases/`) | **Nei.** Søkbar HTML-database, ingen API/eksport (bekreftet via sidetekst). `e-EFTACourt` er en innloggingsportal for partsinnlegg, ikke en offentlig datakilde | Blokkerer uttrykkelig `GPTBot`, `CCBot`, `Google-Extended`, `OAI-SearchBot`, `PetalBot`, og har catch-all `*bot → Disallow: /` |
| ESA (`eftasurv.int`) | State aid-register er søkbart web-ui; «Public document database» er innsynsbasert, ikke bulk | `robots.txt` tillater generelt (ingen bot-sperre) — eneste kilde i denne runden uten AI-blokk |
| `technically_fetchable` | **RED** for begge (ingen struktur, kun enkeltsideskraping — og det er ikke bestilt, regel 2/3) |  |

EØS-relevans er reell (anskaffelsesdirektivene tolkes likt), men ingen av de to gir i dag et grunnlag
for annet enn manuell lenking til enkeltsaker.

## 5. GDPR

Kildene selv sier **avidentifisering i rettsavgjørelser er ikke det samme som GDPR-anonymisering.**
Funn (domstol.no, `/hoyesterett/verktoy/avidentifisering/`, websøk i dag): navn/fødselsdato/adresse
fjernes, men avgjørelsen er «normalt fortsatt indirekte identifiserende» — altså fortsatt
personopplysning i personvernrettslig forstand. Konsekvens for oss: dommer kan **ikke** behandles som
anonymiserte bare fordi Lovdata har kjørt dem gjennom et avidentifiseringsprogram; `gdpr_implications`
må settes til noe sterkere enn «anonymisert» for enhver dom vi lagrer, og B2 (rettighetsmatrisen) må
dekke dette separat fra opphavsrett.

## 6. Prioritering — hva en anskaffelsesjurist faktisk slår opp

**Rettspraksis (KOFA + domstolene) først, forarbeider andre — ikke omvendt.** En anskaffelsesjurist
begrunner en vurdering med en *avgjørelse* (presedens på et konkret faktum: var fristen for kort, var
avvisningen riktig), ikke med en NOU-setning — forarbeider brukes sjeldnere, typisk ved uklart
lovspråk. Men rangert etter **nytte per krone og per implementeringsdag** blant det som faktisk er
tilgjengelig i dag:

1. **KOFA (issue 018, allerede bygget)** — billigst: koden er ferdig, kun B3 (operatørbeslutning)
   mangler. Dette er den desidert beste investeringen igjen, fordi den er gratis og allerede betalt i
   utviklingstid.
2. **Domstolspraksis** — dyrest akkurat nå: Lovdata.no er juridisk/teknisk sperret (RED), og en Pro-
   lisens (kr 6 500–25 900/år) løser ikke robots-forbudet mot maskinell bruk uten en separat avtale vi
   ikke har undersøkt. Høy jurist-nytte, lav tilgjengelighet — **gir ikke mening å bygge mot i dag.**
3. **Forarbeider (Stortinget/regjeringen.no)** — gratis og delvis maskinlesbart (XML), men lavest
   jurist-nytte av de tre (slås opp sjeldnest) og krever fortsatt en verifisering (NOU-dekning) før
   noe kan bygges.

