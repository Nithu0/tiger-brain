# Tilganger, avtaler og sertifiseringer (2026-10-26)

En agent samlet dette fra disse kildene:
- `AVTALER-DIGDIR-KSFIKS.md`
- `LEVERANSEKLAR-SJEKKLISTE.md`
- `krav.json`
- ADR-0022 og ADR-0024
- `UTKAST-DATABEHANDLERAVTALE.md`

Stier i tabellene:
- T = `~/code/Terra`
- SC = `~/code/Terra/solar-consulting`
- OB = `Brain/00-claude-inbox/solar-consulting`

Merking:
- S = skal-krav
- B = bør-krav
- [LT] = har ledetid
- [ORG] = krever org.nr. eller en som har signaturrett

Org.nr. 931 949 837 er verifisert i Brreg. Eierskiftet er ikke bekreftet registrert, og det blokkerer alt som er merket [ORG].

Fordelingen er et forslag. Den skal bekreftes av operatør.

## 1. Innlogging og identitet

| Hva | Krav | Status | Forslag eier | Kilde |
|---|---|---|---|---|
| Azure-testtenant (Entra ID) for testing av OIDC/SSO | S [LT] | Kode i tilgang 0.1.0, ingen tenant | Nithu oppretter, Tintun tester | T/krav.json:14-17, SC/ADR-0022:51 |
| Avtale og onboarding hos Sikt for Feide | S for skole og fylke [LT][ORG] | Ikke diskutert noe sted, bare config i koden | Alper | T/krav.json:14,19 |
| ID-porten-klient | B [LT] | Kunden eier klienten, vi står som `supplier_orgno` | (følger Digdir) | OB/rammeverk/AVTALER-DIGDIR-KSFIKS.md:9,36 |
| Virksomhetssertifikat eller egne JWK-nøkler | ? | ADR-0024 og admin-1 er uenige. Må avklares. | Alper avklarer | SC/ADR-0024:78; OB/rammeverk/AVTALER:10,41 |
| ScimStore i Prisma | S | TODO | Tintun | T/packages/tilgang/README.md:111,151 |
| SAML 2.0 | B | Ikke bygd | (senere) | T/packages/tilgang/README.md:152 |
| Innlogging for Aurora (Google, Microsoft eller e-post) | ? | UNKNOWN, krever endring i base | Tintun | T/aurora/README.md:77 |

## 2. Integrasjoner og API-er

| Hva | Krav | Status | Forslag eier | Kilde |
|---|---|---|---|---|
| Bruksvilkår hos Digdir (Samarbeidsportalen) | S [LT][ORG] | Ikke søkt. Venter på eierskiftet i Brreg. | Nithu (signatar) | OB/rammeverk/AVTALER:4,11,18-19 |
| Delegering i Altinn (Altinn II fases ut 31.12.2026) | S [ORG] | Mangler | Nithu | OB/rammeverk/AVTALER:20,52 |
| Testklient i Maskinporten | S | Mangler, selvbetjent etter delegering | Alper | OB/rammeverk/AVTALER:21 |
| KS Fiks test (e-post til fiks@ksdigital.no). Prod signeres av kommunen. | S [LT] | Mangler | Alper | OB/rammeverk/AVTALER:22-34 |
| FINT-adapter | S for fylke | Ikke startet, tilgangskrav ikke undersøkt | Tintun undersøker | T/krav.json:23-25 |
| Arkiv (Noark, Acos, P360) | B | Ikke startet | (senere) | OB/OPERATOR-TODO.md:24 |
| Doffin API-nøkkel | B | Mangler | Nithu | OB/OPERATOR-TODO.md:48 |
| Anthropic API | har | Har, plantype UNKNOWN | Nithu | OB/SC-TAVLE.md:10 |
| Azure OpenAI EU | B | Mangler, modeller i Norway East UNKNOWN | (følger Azure) | SC/ADR-0024:39,70-74 |
| Slack, Google, Fiken | har / valgfri | Slack og Google OK | — | OB/OPERATOR-TODO.md:38-39 |

## 3. Hosting og kontoer

| Hva | Krav | Status | Forslag eier | Kilde |
|---|---|---|---|---|
| Azure-abonnement: Container Apps, Postgres Flexible, Blob, Key Vault, App Insights | S for Terra [LT] | Mangler | Nithu (betaling), Tintun (oppsett) | SC/ADR-0024:30-39 |
| Railway og Vercel | har | Region og DPA UNKNOWN, ingen kundedata | Nithu sjekker DPA | SC/ADR-0016:41 |
| GitHub-org og CI-tilgang til private pakker | har / TODO | Org OK, pakketilgang i CI er TODO | Tintun | SC/ADR-0023:118 |
| Konto i KGV-ene (Mercell m.fl.) | ? | UNKNOWN. Vilkårene til Mercell forbyr videreformidling. | Alper | SC/procurement/qualification/espd.md:737 |

## 4. Personvern og databehandling

| Hva | Krav | Status | Forslag eier | Kilde |
|---|---|---|---|---|
| Databehandleravtale med kunden (DFØ-mal) | S [ORG] | Utkast v0.1, ikke juridisk gjennomgått | Alper utkast, jurist, Nithu signerer | T/krav.json:32; OB/UTKAST-DATABEHANDLERAVTALE.md |
| Liste over underdatabehandlere og DPA-er med Anthropic, Microsoft, Railway og Vercel | S | Mangler. Anthropic-DPA-en strider mot utkastet: 24 mot 48 t og 30 mot 15 d. | Alper | OB/LEVERANSEKLAR:39-41 |
| Vurdering av tredjelandsoverføring til Anthropic (SCC/DPF) | S | Mangler | Alper | OB/LEVERANSEKLAR:41 |
| ROS-analyse og dataflytdiagram | S | Mangler | Tintun (teknisk), Alper (form) | T/krav.json:30-33 |
| Avviksrutine, art. 30-protokoll, DPIA-mal | S/B/B | Mangler | Alper | OB/LEVERANSEKLAR:42-44 |
| Personvernerklæring for nettsiden og DBA-er (Vercel, Webhuset) | S, sperrer skjemaet | Mangler | Alper | SC/OPPGAVER.md:448-456 |

## 5. Attester og sertifiseringer for anbud

| Hva | Krav | Status | Forslag eier | Kilde |
|---|---|---|---|---|
| Firmaattest etter eierskiftet | S [ORG] | Venter på Brreg | Nithu | OB/LEVERANSEKLAR:24 |
| Skatteattest (Altinn) | S [ORG] | Kan hentes nå, ikke hentet | Nithu | OB/LEVERANSEKLAR:25 |
| Ansvarsforsikring (DPS-frist hos Brreg 22.11) | S i praksis [LT 1-2 uker] | Mangler | Nithu, haster | OB/LEVERANSEKLAR:99 |
| ESPD, regnskap, referanser, CV-er | S | Mangler | Alper samler | OB/LEVERANSEKLAR:26-30 |
| HMS-egenerklæring, lønns- og arbeidsvilkår | S | Mangler | Alper | OB/LEVERANSEKLAR:100-101 |
| Beskrivelse av kvalitetssystem og ISMS (i stedet for ISO) | S | Utkast finnes | Alper ferdigstiller | OB/LEVERANSEKLAR:46-74 |
| ISO 27001 | B [LT, måneder] | Kan vente (2 % av kravene) | (senere) | SC/projects/anbud/crm/eval/sakssystem-krav-2026-10-20.md:91 |
| WCAG 2.1 AA og tilgjengelighetserklæring | S | axe-test finnes, erklæringen mangler | Tintun | T/krav.json:40 |
| StartBANK (2 920 kr/år), Achilles | B | Mangler | Nithu ved behov | SC/procurement/qualification/tender-readiness-checklist.md:300 |

## 6. Øvrig

- Les SSA-B, -O, -T og -L, særlig forsikringskravet i SSA-B. Forslag eier: Alper.
- Normen (helse): ikke vurdert.
- Varemerkesøk for Aurora: Tintun.
- Krav til bærekraftige datasentre og SLA: følger Azure.

## Usikkerheter

- Eierskiftet i Brreg er ikke bekreftet. Alt som er merket [ORG] venter på det.
- Det er ikke avklart om vi må kjøpe virksomhetssertifikat.
- At Feide krever avtale med Sikt, er en antakelse. Ingen av kildene sier det.
- Ledetid hos Digdir og KS er ikke dokumentert. Spørsmålene ligger klare i `AVTALER-DIGDIR-KSFIKS.md:59-61`.
- Skal-kravene i `krav.json` kommer trolig fra én mal (Viken). De er ikke hentet fra mange anbud.
