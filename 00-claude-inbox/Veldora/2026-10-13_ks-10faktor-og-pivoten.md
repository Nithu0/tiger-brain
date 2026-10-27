# Medarbeiderundersøkelser: holder 10-FAKTOR-forbeholdet, og finnes markedet i pivot-segmentet?

Status: `ACTIVE` · Skrevet 2026-10-13 · Eier: learning-1 · Alle kilder hentet 13.10.2026

## Hvilken beslutning dette svarer på

[`strategy/proposals/2026-10-12-tre-scopes.md`](../strategy/proposals/2026-10-12-tre-scopes.md)
§ 6 punkt 2: «Sjekk forbeholdet om medarbeiderundersøkelse før 19.10.» Punktet sto uten eier.
Forbeholdet i § 4 lyder:

> `ASSUMPTION` — KS tilbyr en medarbeiderundersøkelse (10-FAKTOR) til kommunene, så mange kommuner
> kjøper den ikke. Er det riktig, er målgruppen statlige etater, helseforetak og offentlige
> selskaper, ikke kommuner.

Scope 3 (medarbeiderundersøkelse og pulsmålinger) står og faller på dette. Det har **ett** ja i
triagen og **null** tildelinger i vår egen `awards`-tabell.

## Svaret kort

`FACT` **Premisset holder. Konklusjonen holder bare delvis, og for helseforetak er den motbevist.**

| Segment i pivoten | Egen incumbent? | Kjøper de likevel? | Dom |
| --- | --- | --- | --- |
| Statlige etater | Ja — **MUST**, gratis, 115 virksomheter | **Ja, 14 kunngjøringer, 0,6–4,7 MNOK** | Eneste segment dataene støtter |
| Helseforetak | Ja — **ForBedring**, felles for alle HF, krav i oppdragsdokument | **Nei, 0 kunngjøringer på 3 år** | `AVKREFTET` — strammere lukket enn kommunene |
| Offentlige selskaper | Ingen funnet | Ja, 4 kunngjøringer, 0,5–2 MNOK | Åpent, men tynt volum |

Pivoten bytter altså én incumbent (10-FAKTOR) mot en annen (MUST) — men **i staten lekker
incumbenten, i helse gjør den det ikke.**

## 1. Kommune-segmentet er trangere enn forbeholdet sier, ikke romsligere

`FACT` 10-FAKTOR er aktiv i 2026 og driftes av Kommuneforlaget (KF), som er KS-eid.
304 unike kommuner har gjennomført den, 100 487 respondenter i 2024 — mot 357 kommuner totalt,
altså ~85 % som har brukt den minst én gang (https://10faktor.no/, hentet 13.10.2026).
Tilleggsmodulen 10-FAKTOR Omstilling ble publisert 04.05.2026.

`FACT` Og KS har **utvidet fra ett til to** instrumenter mot sektoren i 2026: KS kunngjorde
11.06.2025 «Arbeidsmiljøundersøkelser i kommunen» for «hele kommunesektoren»
(Doffin 2025-109054, https://doffin.no/notices/2025-109054). Agenda Kaupang leverte, lansert
13.08.2026, og avgrenser forholdet selv: 10-FAKTOR måler motivasjon og mestring, den nye måler
«risikofaktorer som påvirker helse og sykefravær»
(https://www.agendakaupang.no/ny-arbeidsmiljoundersokelse-for-kommuner-og-fylkeskommuner/).

Den egentlige kommune-barrieren er altså ikke bare 10-FAKTOR, men at KS nå dekker **begge** sider.

`FACT` Men kommunesektoren er ikke lukket: **fylkeskommunene kunngjør dobbelt så ofte som
kommunene** (6 mot 3 siste 3 år) selv om 10-FAKTOR er skreddersydd for dem også. Det er et signal
om at KS-instrumentene ikke dekker alt behov. Forslaget avskriver kommunesektoren raskere enn
dataene forsvarer.

`UNKNOWN` Pris på 10-FAKTOR (ingen offentlig prisliste; KF ber om kontakt). `UNKNOWN` hvordan
KS/KF-arrangementet ble anskaffet — null kunngjøringer funnet; egenregi via heleid datterselskap
er en **inferens**, ikke verifisert. `UNKNOWN` aktiv årlig base, til forskjell fra «brukt minst én
gang».

## 2. Staten: incumbenten finnes, og den lekker — dette er funnet som betyr noe

`FACT` **MUST** (Medarbeiderundersøkelsen i staten) er «et kunnskapsbasert, digitalt verktøy …
utviklet til **gratis** bruk for virksomheter i det statlige tariffområdet», fra STAMI og DFØ,
tilbudt siden 2022, frivillig
(https://arbeidsgiver.dfo.no/strategisk-hr/medarbeiderundersokelsen-i-staten-must/beslutte-bruke-must).
115 virksomheter har gjennomført den minst én gang
(https://arbeidsgiver.dfo.no/nyhetsarkiv/ta-ledelsen-i-skape-et-godt-arbeidsmiljo, 06.05.2026).

`FACT` **Og likevel kjøpes det kommersielt gjennom hele 2025–2026:** Skatteetaten tildelt
Winningtemp AB 4,7 MNOK (08.09.2026) · Statsbygg tildelt Rambøll 1,177 MNOK (05.05.2026) ·
Bufdir tildelt Rambøll 2,2 MNOK (06.10.2025) · Politiets fellestjenester utlyst 4,5 MNOK
(27.05.2026) · Kulturdirektoratet 0,6 MNOK · Norges Bank til Ennova.

Påstanden «staten har ikke egen standard» er altså feil, men konklusjonen «staten er et bedre
marked enn kommunene» holder likevel — på volum. `ANTAKELSE` (konsistent med
kunngjøringstekstene, ikke bevist): sprekken MUST ikke dekker er **hyppige pulsmålinger og
lederoppfølging**. Skatteetaten ber om å «måle medarbeiders opplevelser kontinuerlig, gjennom hele
ansattreisen»; Bufdir, Statsbygg og Udir etterspør tilsvarende. Det er kilen, og den er den samme
som scope 3s eget navn («… og pulsmålinger»).

Konkurrentene i segmentet er navngitt av dataene: Rambøll Management Consulting (2 av 4
tildelinger), Winningtemp AB, Ennova. Øvrige tilbydere hos Skatteetaten: Sopra Steria, Eletive AB,
CatalystOne Solutions.

## 3. Helseforetak: segmentet er motbevist

`FACT` **ForBedring** er «en samordnet undersøkelse av pasientsikkerhet, HMS og arbeidsmiljø …
felles for alle helseforetak, og gjennomføres for niende gang i 2026» (Finnmarkssykehuset HF,
styresak 29/26, 29.04.2026,
https://www.finnmarkssykehuset.no/498320/siteassets/dokumenter-til-sider-i-sidetre/styremoter/2026/april/sak-29-2026-forbedring-2026-finnmarkssykehuset-hf.pdf).
Besluttet av de fire RHF-direktørene i 2017, dekker alle helseforetak og institusjoner med avtale
(https://www.helse-sorost.no/forbedring), oppfyller krav i internkontrollforskriften og forskrift
om ledelse og kvalitetsforbedring (https://www.helse-vest.no/forbedring/), og oppfølging er krav i
oppdragsdokumentene for 2025 og 2026.

`FACT` **Null kunngjøringer fra helseforetak** på medarbeiderundersøkelse / pulsmåling /
arbeidsmiljøundersøkelse / 10-FAKTOR siste 3 år.

Helseforetak er dermed et **dårligere** segment enn kommunene, ikke bedre, og bør ut av pivoten.
`UNKNOWN` hvilken leverandør som driver ForBedring-plattformen — ikke oppgitt på RHF-sidene, ingen
kunngjøring funnet.

## 4. Konsekvens for kriterium 3 — og en retting av min egen måling

Forslagets kriterium 3 er «små kontrakter finnes, slik at første referanse kan komme under
terskelverdi». Min interne måling 13.10
([`crm/eval/SCOPE-KATEGORIER-19OKT.md`](../projects/anbud/crm/eval/SCOPE-KATEGORIER-19OKT.md))
fant **0 tildelinger** for medarbeiderundersøkelse i vår egen `awards`-tabell, og ingen tildeling
med kjent beløp under 2,2 MNOK i noen kategori.

`FACT` **Det var en dekningsmangel hos oss, ikke et markedsfunn.** Doffin har 28 reelle
kunngjøringer på disse søkeordene siste 3 år, og flere ligger godt under terskelverdi:
Bergen kommune BME **0,3 MNOK** · Norsk Helsenett SF **0,5 MNOK** · Kulturdirektoratet **0,6 MNOK**
· Andøya Space **0,7 MNOK**. Til sammenligning har `awards` 552 rader hvorav bare 54 med beløp.

**Kriterium 3 er dermed oppfylt for scope 3** — små kontrakter finnes beviselig. Og advarselen jeg
skrev («med 90 % manglende beløp er *ingen små kontrakter* like forenlig med en datamangel som med
markedet») var riktig: det var datamangelen.

`RETTET` Jeg skrev først at dette var et ingest-hull — «28 relevante konkurranser på tre år, og
`awards` kjenner ingen av dem». **Det var en feilslutning fra fravær, og den er målt bort:**

| Måling (prod, 13.10) | Resultat |
| --- | --- |
| `tenders` publisert-vindu | **2026-09-20 → 2026-10-12**, altså 23 dager (1751 kunngjøringer, alle med dato) |
| Treff på søkeordene i vårt eget korpus | **1 av 1 mulige** — «Medarbeiderundersøkelse og pulsmålinger», COMPETITION, publisert 23.09.2026 |
| `awards` | 552 rader, alle knyttet til RESULT-kunngjøringer publisert i **samme 23-dagersvindu** |
| `awards.awarded_at` | 09.03 → 12.10.2026 — rekker 7 måneder tilbake i *tildelingsdato*, men bare via resultatkunngjøringer publisert i vinduet |

Segmentet **hentes altså inn**. Den ene kunngjøringen som finnes i vinduet er nettopp den
operatøren sa ja til. De 27 øvrige er publisert før vi begynte å hente inn — de er ikke mistet,
de er eldre enn korpuset.

Det virkelige funnet er et annet, og det gjelder hele programmet: **plattformen har ingen
historisk dybde.** 23 dager med kunngjøringer betyr at ethvert markedsstørrelse-spørsmål —
kriterium 3 inkludert — ikke kan besvares fra våre egne data i det hele tatt. Det må gå til
Doffin/TED direkte, slik denne rapporten gjorde, til en backfill finnes. Det er en dekningssak
for data-lanen, ikke en feil i ingest.

## 5. Doffin-grunnlaget

Fritekstsøk på medarbeiderundersøkelse, medarbeiderundersøkelser, pulsmåling,
arbeidsmiljøundersøkelse og 10-FAKTOR: 129 unike kunngjøringer totalt, 49 publisert ≥ 01.10.2023,
hvorav **28 der undersøkelsen faktisk *er* anskaffelsen** (de øvrige 21 er HR-/BHT-rammeavtaler
der den bare nevnes).

| Segment | Kunngjøringer | Kjøpere |
| --- | --- | --- |
| Statlig forvaltning/etat/direktorat | **14** | Skatteetaten, Politiets fellestjenester, Statsbygg, Udir, Bufdir, Kulturdirektoratet, Forsvarsbygg, Norges Bank, Statens vegvesen |
| Statlige foretak/selskaper | 4 | Norsk Helsenett SF (×2), Bane NOR SF, Andøya Space |
| Fylkeskommune | 6 | Innlandet, Rogaland, Trøndelag, Troms, Akershus, Buskerud |
| Kommune | 3 | Bergen (BME), Horten, Sola |
| KS | 1 | «Arbeidsmiljøundersøkelser i kommunen» |
| **Helseforetak/RHF** | **0** | — |

TED gir bare 2 norske treff (Norges Bank 718851-2024, Bufdir 25106-2026) — TED er delmengde av
Doffin over EØS-terskel, så Doffin-tallene gjelder.

Metodenote: Doffins backend-API (`api.doffin.no/webclient/api/v2/search-api/search`) svarer åpent
og `robots.txt` har ingen restriksjoner. **ks.no er bak Cloudflare og blokkerte all henting
(HTTP 403)** — KS' egne sider er sitert via søkeindeks-utdrag og ett Wayback-snapshot
(https://web.archive.org/web/20250323084255/https://www.ks.no/fagomrader/arbeidsgiverpolitikk/ledelse-og-organisering/et-vellykket-10-faktor-arbeid/om-10-faktor/),
ikke direkte. Det er det eneste reelle kildehullet.

## 6. Hva jeg vil at beslutningen 19.10 tar med

Jeg teller og belegger; operatøren velger. Fire ting følger av kildene:

1. **Ta helseforetak ut av pivoten.** ForBedring er felles, i niende år, med krav i
   oppdragsdokumentene, og null konkurranseutsetting. Som formulert hviler forslagets § 4 på et
   segment som er motbevist.
2. **Statlig tariffområde + fylkeskommuner er det segmentet dataene støtter** — 14 + 6 av 28
   kunngjøringer, og tildelinger fra 0,6 til 4,7 MNOK gjennom 2026.
3. **Kilen mot MUST er pulsmåling og kontinuerlig måling**, ikke årlig arbeidsmiljøkartlegging.
   Det er `ANTAKELSE` fra kunngjøringstekstene og bør bekreftes mot ett konkurransegrunnlag før
   det legges til grunn.
4. **Kriterium 3 er oppfylt for scope 3**, men ikke fra våre egne data — fra Doffin. At vi ikke
   fanget 28 relevante konkurranser på tre år er et eget funn om dekningen.

## Kilder

Alle hentet 13.10.2026. https://10faktor.no/ · https://www.kf.no/10-faktor ·
https://doffin.no/notices/2025-109054 ·
https://www.agendakaupang.no/ny-arbeidsmiljoundersokelse-for-kommuner-og-fylkeskommuner/ ·
https://arbeidsgiver.dfo.no/strategisk-hr/medarbeiderundersokelsen-i-staten-must/beslutte-bruke-must ·
https://arbeidsgiver.dfo.no/nyhetsarkiv/ta-ledelsen-i-skape-et-godt-arbeidsmiljo ·
https://arbeidsgiver.dfo.no/nyhetsarkiv/ny-og-kortere-versjon-av-medarbeidsundersokelsen-i-staten-must-er-tilgjengelig ·
https://stami.no/vare-tjenester/medarbeiderundersokelsen-i-staten-must/ ·
https://www.helse-sorost.no/forbedring · https://www.helse-vest.no/forbedring/ ·
Finnmarkssykehuset HF styresak 29/26 (lenke i § 3) · https://snl.no/KS_-_Kommunesektorens_organisasjon ·
https://www.spekter.no/om-spekter/dette-er-spekter · https://www.proff.no/selskap/kf/oslo/forlag/IF2DDR200FH ·
https://no.wikipedia.org/wiki/Kommuneforlaget · https://businesswith.no/system/10-faktor/ ·
Wayback-snapshot av ks.no/om-10-faktor (lenke i § 5) ·
https://api.ted.europa.eu/v3/notices/search · enkeltkunngjøringer via https://doffin.no/notices/<id>
