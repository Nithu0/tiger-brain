# SC-05 — regelmotor: KOFA-funn, versjonert lovtekst, gullsett, terskler (infra-1)

Dato: 2026-10-16 · branch `sc-05-regelmotor` (worktree `~/code/Veldora-sc05`) · 8 commits, **ikke pushet**.
Migreringskø: nr. 2 etter SC-03. Rebase + regenerert migrering + PR når orchestrator-1 sier fra.

## Levert

| # | Oppgave | Hva | Målt |
|---|---|---|---|
| 1 | KOFA → funn | `legal/kofa/findings.ts`: vurderte §§/ledd, utfall per påstand (egen + kontekst-paragraf), gebyr, beløp med rolle, regime med begrunnelse. `build.ts` lagrer også de fem feltene page.ts kastet. | 308 saker: 100 % ≥1 påstand, regime lest 80,5 %. Stikkprøve 15 saker: 0 feil utfall, 1 glipp, 1 duplikat. Kontekstkobling 8/10. |
| 2 | Versjonert lovtekst (issue 020) | Ingenting slettes. Forsvunne ledd blir «opphevet» med validTo, endret ordlyd gir historikkrad i `legal-chunk-versions`, og søk filtrerer på gjeldende. FOA § 7-9 ligger ordrett fra Lovtidend (NLOD 2.0, sha256-testet). | Kriterium 1 i 020 er oppfylt. Kriterium 2 (varsel) er blokkert av 016/017, men historikkraden har det diffen trenger. |
| 3 | Gullsett + P/R | `eval/feilsjekk-gold.json`, `eval/feilsjekk-kofa-2026-10-16.txt`, `eval/FEILSJEKK-KOFA.md` | 900 saker → 99 med fasit (24 streng). Se under. |
| 4 | Terskeltabeller | 10 rader, alle ASSUMPTION med kilde-URL + ordrett sitat, merket «Juristkontroll». Brukes ikke før FACT (ADR-0018). | Validert mot skjema. |
| 5 | data/sources | `kofa.json` (ny), `lovdata.json` (API ≠ nettsted, robots-funn), `doffin.json` (webklienten). Myhre er ikke rørt. | validate.mjs: alt gyldig. |
| + | Regelverk per regel | `RULE_REGIMES` + `regimeOf`, og regimet stemples på hvert funn. Miljø før 1.7.2026 viser til § 7-9 (før 2024: 2017-utgaven, uten minstevekt). | Det er testet at tabellen dekker alle lawChunkIds. |
| + | Del II/III | `partForTender`: register → TED → verifisert tabell → ukjent med grunn. Koblet til feilsjekk, klage-detalj og klage-oversikt. | **ukjent 481 → 15 av 1074 (44,8 % → 1,4 %)**, prod read-only. 99 hviler på TED-antakelsen. |
| + | page.ts-feil | Slug uten nullutfylling ble avvist. | **15 saker mangler i prod-korpuset** (av 350), alle bekreftet read-only. |

## Presisjon/recall (utvidet fasit, 99 saker)

tildeling P 50 % / R 22 % (9 pos) · miljø P 33 % / R 14 % (7) · spesifikasjon R 0 % (7) ·
rammeavtale P 75 % / R 100 % (3) · kvalifikasjon 1 pos · frist 0 pos. **Tallene er små: ≤ 9 positive per familie.**

Inndata er tilnærmet fra nemndas «Bakgrunn», ikke fra hele konkurransegrunnlaget. Lav recall på
spes-merke og tildeling-uten-vekt sier mest om at kravene ikke står ordrett der.

## Hovedfunn: dekning

Av 150 saker med brudd på en paragraf gjelder **bare 24** en paragraf noen regel håndhever. Topp 5 uten regel:

| Paragraf | Saker | Kan sjekkes i grunnlaget? |
|---|---:|---|
| FOA § 25-1 meddelelse/begrunnelse | 20 | Nei, skjer etter evaluering. Hører til klagesporet. |
| FOA § 24-8 avvisning (tilbudet) | 16 | Nei, gjelder oppdragsgivers behandling. Klage. |
| FOA § 24-2 avvisning (leverandøren) | 14 | Nei. Delvis via uklare kval-krav. |
| FOA § 10-1 meddelelse (del II) | 9 | Nei. |
| FOA § 9-5 avvisning (del II) | 8 | Nei. |

Konsekvens (CLAUDE.md § 8): **feilsjekken av konkurransegrunnlaget kan ikke nå de vanligste KOFA-bruddene.**
Hvis verdien vi selger er «unngå det KOFA slår ned på», er det klagesporet som må måles mot dette.
Anbefalt første nye grunnlagsregel: feil del valgt ut fra verdien (FOA § 5-1/5-3, 3 saker), bygget
på partForTender når terskeltabellen er juristverifisert.

## Gjenstår / til operatør og jurist

1. **api.lovdata.no/robots.txt = `Disallow: /`** (2026-10-16). Det nattlige ingest-lovdata sjekker ikke robots. Operatøren avgjør.
2. **Etter utrulling:** én `ingest-lovdata { force: true }` for å få § 7-9-seedene og validFrom-backfill inn. Det krever at punkt 1 er avklart først. KOFA-backfill for å fylle de nye kofa-feltene og de 15 tapte sakene.
3. **Jurist:** terskeltabellen (10 rader → FACT), LIK_TERSKEL_ER_OVER (FOA § 5-1 (3) sier «lik eller overstiger»), TED-antakelsen, KOFA-rettighetsgrunnlaget (åndsverkloven § 14), og gullsett-utfallene.
4. **Kjente svakheter:** citations.ts gjetter FOA for «§ n-m» i saker om andre forskrifter. decision.ts deler ikke alltid avsnitt i flerdelssaker. Et gjeninnført ledd med samme tekst mister opphevelsesperioden (sjeldent).
5. **Stikkprøv støy:** ramme-maksverdi fyrte i 31 og miljo-vekting i 28 saker uten fasit.
6. Overgangsreglene i FOR-2026-04-14-617 er ikke lest. Regimet avgjøres av kunngjøringsdato (ASSUMPTION, `PERIODE_AVGJORES_AV`).

## Hendelser

- KOFA-cachen kjørte ~40 min før kofa.json fantes. Den gikk gjennom samme klient og regler som prod-inntaket. orchestrator-1 vurderte at det ikke var et brudd.
- Agent B kjørte `npx biome check`, og npx installerte urelatert biome@0.3.3. Det er undersøkt og ufarlig, og slettingen ligger hos operatøren. Ny regel: ingen npx på pakker utenfor package.json.
