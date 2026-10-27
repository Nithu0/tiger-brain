# Stoppunkter som mangler — forslag til spørsmål og oppførsel

paal-1, 27.10.2026. Grunnlag: `docs/golden-flow-styreendring.md` oppgave 1 og `docs/tjenestekonfigurasjon.md`, målt mot koden på main (`src/lib/stoppunkter.ts`).

## I dag

`vurderStopp()` har tre regler, og alle blokkerer: `kun_as`, `tvangsavvikling` og `konkurs_avvikling`. I veiviseren gir de 400, og i Woo-kanalen `NEEDS_REVIEW`. Aksjer som ikke summerer er en egen hard 400 (`orders.ts:409`). Ingen regel varsler først, selv om dokumentet anbefalte det.

## De fire som mangler, og hvorfor de ikke kan leses fra data

Ingen av dem finnes i Brønnøysunds åpne API eller i det veiviseren spør om i dag. De krever ett nytt spørsmål til kunden, og **ordlyden er en operatørbeslutning**.

| Regel | Forslag til spørsmål i veiviseren (styre-steget) | Svar som utløser | Oppførsel først |
|---|---|---|---|
| Flere aksjeklasser | «Har selskapet mer enn én aksjeklasse (for eksempel A- og B-aksjer)?» Ja / Nei / Vet ikke | Ja eller Vet ikke | Varsel i saken: «Flere aksjeklasser — protokoll og stemmeregler må kontrolleres manuelt» |
| Tvist | «Er det uenighet mellom aksjeeierne eller i styret om denne endringen?» Ja / Nei | Ja | Varsel, og saken går til `NEEDS_REVIEW` før dokumenter |
| Kunden bestrider BRREG-dataene | Allerede «Vi fant følgende — stemmer dette?» Legg til «Nei, noe er feil» med fritekst | Nei | Varsel med kundens fritekst, ingen dokumenter før Pål har sett på det |
| Uvanlige selskapsforhold | «Er det noe spesielt vi bør vite? (for eksempel aksjonæravtale, pant i aksjer, eierskifte pågår)» Fritekst, valgfritt | Ikke tomt | Varsel med teksten |

Den femte, **person uten norsk fødselsnummer eller D-nummer**, kan leses fra data i dag: en ny rollehaver med `land` ≠ Norge og uten fnr. QA-regelen R09 varsler allerede når fnr er tomt, men først ved dokumentgenerering. Et varsel ved innsending ville sagt det tidligere: «trenger D-nummer før registrering». Det er lite arbeid og kan bygges uten beslutning.

**Vedtekter mangler** er ikke et stoppunkt i dagens data. «Nei» i vedtektssteget betyr «vi skriver nye vedtekter», og det er det anbefalte valget. «Ja, men ingen fil» gir allerede 400 (`orders.ts:437`).

## Foreslått mekanisme (kan bygges når ordlyden er bestemt)

- `vurderVarsler()` ved siden av `vurderStopp()` i `stoppunkter.ts`, kalt fra begge kanalene.
- Et varsel blokkerer ikke. Det skrives i saksloggen (`automation_runs`, type `stoppunkt_varsel`) og vises øverst i saken. Saken går til `NEEDS_REVIEW` bare der tabellen sier det.
- Hver regel kan gjøres om til blokkerende enkeltvis når den er sett mot ekte saker, som dokumentet anbefalte.
- Woo-kanalen har bare fritekst og får ikke de nye spørsmålene før kundereisen flyttes inn i CRM-et.

## Beslutning som trengs

1. Godkjenn eller endre ordlyden i tabellen.
2. Skal «tvist» gå rett til `NEEDS_REVIEW` (foreslått), eller bare varsle?
