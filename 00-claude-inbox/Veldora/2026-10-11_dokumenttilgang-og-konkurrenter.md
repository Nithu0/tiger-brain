# Dokumenttilgang og konkurrenter — anbudsplattform

Dato: 2026-10-11 · Status: `ACTIVE` · For: operatør + orchestrator-1

## Kortversjon

1. **Artifik er ikke en konkurrent.** Det er en KGV/KAV-plattform bygget av Comono + Vaar Advokat,
   solgt til OPPDRAGSGIVERE (Oslo kommune, Statsbygg, Ruter, Statens vegvesen, Nye Veier m.fl.).
   De lager konkurransen; vi svarer på den. `FACT` artifik.no + anbud365.no 2023-06-28.
   Filosofien deres er å fjerne vedlegg via strukturerte eForms-felt, ikke å hente dem for andre.
2. **De ekte konkurrentene på leverandørsiden** er Finndoff, Bidflow, Tendium og TenderEdge.
   Finndoff henter automatisk fra Mercell, TendSign, EU-Supply og Artifik, med manuell opplasting
   som reserve for resten. Bidflow overvåker Doffin og henter dokumenter automatisk.
   `FACT` finndoff.no, bidflow.no, fetched 2026-10-11.
3. **Doffin-API-et gir metadata, ikke dokumenter.** Tittel, frister, CPV, oppdragsgiver, estimert
   verdi. Dokumentene ligger hos oppdragsgivers portal. `FACT` medium tillit, varsly.no —
   bør dobbeltsjekkes mot api.doffin.no før noe bygges på det.
4. **TED/eForms har samme begrensning**: kunngjøringen, ikke de fulle konkurransedokumentene.

## Tre veier, rangert etter innsats

1. **Lavest:** integrer eller kjøp en eksisterende aggregator (Finndoff fra 829 kr/mnd, Bidflow).
   De har løst hentingen. Risiko: avhengighet og marginpress.
2. **Middels:** Doffin/TED-API for metadata og varsling, og la brukeren dra inn dokumentene selv
   fra portalen. Samme reserveløsning Finndoff bruker for uvanlige portaler. Ingen vilkårsbrudd,
   men friksjon per sak.
3. **Høyest, frarådes uten juridisk avklaring:** egen automatisert henting fra Mercell/TendSign.
   Teknisk gjørbart, ingen offisiell API-vei funnet, og det kolliderer med Mercells vilkår.

## Juridisk kjerne — holdt adskilt fra det tekniske

- `FACT` anskaffelser.no: anskaffelsesdokumenter er i utgangspunktet OFFENTLIGE etter offentleglova.
  **Innsyn kreves direkte fra OPPDRAGSGIVER**, ikke fra portalen. Unntak for forretningshemmeligheter
  i tilbud, offentleglova § 13.
- `FACT` Mercells vilkår § 10: «All tilgjengelig informasjon må på ingen måte distribueres eller
  selges videre». Dette er en KONTRAKT med den registrerte brukeren, og gjelder uavhengig av
  dokumentenes offentligrettslige status.
- **Spenningen:** å be oppdragsgiver om innsyn er trolig trygt å lagre, analysere og vise kunden.
  Å hente de samme dokumentene fra Mercell og så videreformidle dem i et eget produkt kan bryte
  § 10. Det er et avtalespørsmål, ikke et offentlighetsspørsmål.
- `UNKNOWN` hvordan Finndoff og Bidflow rettferdiggjør sin automatiske henting. Ingen offentlig
  kilde funnet. Den raskeste måten å avklare floken på er å spørre dem, eller Mercell, direkte.

## Anbefaling

Skill de to sporene. **Offentleglova-sporet mot oppdragsgiver har lav juridisk risiko** og gir oss
dokumentene lovlig. **Portal-skraping har kontraktsrettslig risiko** og bør ikke bygges før en
jurist har sett på det. I mellomtiden: de 675 anskaffelsene som alt har en direkte dokumentlenke
er gratis gevinst, og de hentes nå.

## Ikke verifisert

- Offisiell Doffin-API-dokumentasjon ikke lest direkte, kun sekundærkilder.
- Om Mercell krever registrering for å LESE norske kunngjøringer. Primærkilden ga 404.
- Rettspraksis i Norden på skraping av anskaffelsesportaler. Ikke søkt.
- TenderEdge ikke undersøkt i detalj.

Kilder: artifik.no · anbud365.no 2023-06-28 · finndoff.no · bidflow.no · varsly.no/doffin-api ·
developer.ted.europa.eu · support.mercell.com · get.mercell.com MTS-vilkår § 10 ·
anskaffelser.no «Innsyn og offentlegheit». Alle hentet 2026-10-11.
