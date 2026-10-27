# Kunnskapsgraf: virksomheter, leverandører, kontrakter, kunngjøringer, CPV og teknologi (data-1)

Målt read-only i prod 2026-10-19 (`crm/scripts/baseline/kunnskapsgraf-2026-10-19.sql`, ikke committet).
**D** = DOKUMENTERT (står i kunngjøringen, med kilde), **E** = ETTERSPURT (krav i anbudet), **A** = ANTAKELSE.

## Hva som finnes og er fylt i dag

| Node/kant | Kilde i modellen | Fylt |
|---|---|---|
| Kunngjøring | `tenders` (Doffin/TED, rå-JSON beholdt) | 110 059. 81 425 har `buyer_id` (D) |
| Kunngjøring → CPV | `tenders_texts` path `cpvCodes` | 110 023 kunngjøringer, 323 799 koder (D) |
| Virksomhet (kjøper) | `buyers` (org.nr., type, kommunenr.) | 1 500. Alle har org.nr., 1 377 har kommunenr. 500 kommuner, 301 stat, 22 fylkeskommuner, 21 helseforetak (D) |
| **Kontrakt → vinner** | `tenders_lots` → `tenders_lots_winners` (per delkontrakt) | **30 315 vinnerrader på 18 996 kunngjøringer, 10 582 unike leverandører. Bare 13 276 (44 %) har org.nr.** (D) |
| Kontrakt (beriket) | `awards` (verdi, kontraktslutt, antall tilbud, kilde) | **bare 387 rader** (mars–okt 2026), 95 med verdi, 209 med sluttdato (D) |
| Leverandør | `suppliers` (org.nr., NACE, kommune, Brreg-match) | 475. 386 har org.nr., **4** har NACE og kommune |
| Teknologi | finnes ikke | 0. Nærmeste kilde: kravrader (892 på 169 muligheter, E) og beskrivelser/CPV 72xxxx (D, grovt) |

Grafen finnes altså allerede som relasjoner i Postgres. Kjernekanten kjøper → kunngjøring → delkontrakt → vinner er
fylt for nesten 19 000 kunngjøringer. Det som mangler, er **identitet** (56 % av vinnerne har bare et navn), **berikelse**
(awards dekker 2 % av vinnerkontraktene) og **teknologi** som egen node.

## De tre spørsmålene med dagens data

1. **Hvem leverer til kommuner i Vestland** (kommunenr. 46xx, 593 vinnerkunngjøringer, D): Sweco Norge 13 kontrakter / 6 kommuner,
   Visma Enterprise 10 / 4, Norconsult 9 / 3 *og* «NORCONSULT NORGE AS …» 9 / 7, Multiconsult 8 / 4, Asplan Viak 8 / 5.
   Svaret er brukbart, men Norconsult telles to ganger. Det viser hullet i identiteten.
2. **Hvilke kjøpere bytter leverandør oftest:** kan **ikke** besvares pålitelig i dag. En naiv måling (ny vinner i samme
   CPV-divisjon hos samme kjøper) gir «bytte» i 97 % av tilfellene (Sykehusinnkjøp 1 302 av 1 343), fordi rammeavtaler med flere
   vinnere og ulike delkontrakter ser ut som bytter. Ekte bytte krever kontraktsrekker: hvilken kontrakt erstatter hvilken
   (forrige kunngjøring/«related tender», kontraktslutt). Det har vi bare i `awards` (387). **A**
3. **Hvilke leverandører opptrer sammen** (samme kunngjøring, D): Asplan Viak + Norconsult 28, Multiconsult + Norconsult 25,
   Sweco + Norconsult 20, Sweco + Multiconsult 20, Sweco + COWI 20, Asplan Viak + COWI 19. Det er nesten bare rammeavtaler med
   flere vinnere. Samarbeid i konsortium kan ikke skilles ut uten rollen i kunngjøringen.

## Minste endring som gir en spørrbar graf (én migrering)

1. **Ingen ny database og ingen nye kopier av data.** Grafen er relasjonene vi har. Én migrering legger til:
   - **en SQL-view `graf_kanter`** (kilde, mål, type, kunngjøring, dato, beviskode D/E/A) over `tenders`, `tenders_lots_winners`,
     `tenders_texts` (CPV) og `awards`, så alle tre spørsmålene blir én enkel spørring;
   - **samlingen `teknologi_omtaler`**: kunngjøring/mulighet, normalisert teknologi, `bevis` (D/E/A), ordrett sitat, kilde og dato.
     E kommer fra kravagentens rader, som allerede har sitat. D kommer fra beskrivelse/CPV ved regel. A brukes bare med modell og
     merkes.
2. **Identitet uten migrering:** fyll `suppliers` fra `tenders_lots_winners` (org.nr. der det finnes, ellers navn) og la den
   eksisterende jobben `supplier-brreg-match` (cron 02:20) matche navn til org.nr. Den finnes, men har bare sett 475
   leverandører. Det gjenbruker det som finnes.

## Beste mulighet jeg ser

**Identitetsoppløsning av de 30 315 vinnerne** er billigst og gir mest. Den gjør Q1 og Q3 riktige, gir markedsandel per kjøpertype,
fylke og CPV, og gir **sittende leverandør** (incumbent) på de 26 mulighetene i spill. `opportunities.incumbent_id` finnes, men
er ikke fylt. Utenfor oppdraget: rådgiverne som opptrer sammen (Q3), er en ferdig liste over **partnerkandidater** for
underleveranse og konsortier. Det er salgsverdi for Solar Consulting direkte.

- **Verdi (A):** markedskart per segment og incumbent i triagen. Vi vet ikke hvor mye vinnsjansen øker, så det må måles etter innføring.
- **Datagrunnlag:** 30 315 vinnerrader (D), Brreg (åpent).
- **Kostnad:** Brreg-matchingen finnes. Et fyll-skript og en migrering (view + samling) er en liten PR hver, og koster ingen modell.
  Teknologi-uttrekk med modell koster ~0,02 USD per kunngjøring hvis det gjøres på alle, så start med kravradene (gratis, E).
- **Risiko:**
  - navnestøy («INVITASJON ØNSKES HER»)
  - rammeavtaler blåser opp «samarbeid» og «bytter»
  - **enkeltpersonforetak er persondata**, så navnet til en ENK skal ikke ut i rapporter uten vurdering
  - awards-dekningen er for tynn til byttemål før kontraktsrekker er på plass
