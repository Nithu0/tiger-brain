# PRODUKTKART — Pål-virksomheten (paal-1, 2026-07-27)

Grunnlag: Pål solgte **120 AS-er i fjor** (~2,3/uke) via ASListen.no, og driver i
tillegg løpende regnskap/selskapsendringer. Hver sak i dag = rot på tvers av
WhatsApp/telefon/e-post + manuell dokumentproduksjon + manuell Brønnøysund-innsending.
Plattformens jobb: kundehåndtering skal være hans ENESTE jobb.

## A. Dekket av CRM-en i dag (live)

| Workflow hos Pål | Dekning |
|---|---|
| Henvendelse inn (tlf/WhatsApp/e-post/SMS) | Manuell registrering («+ Ny henvendelse») → sak m/uttrekk (orgnr MOD11, pris, dato, parter) |
| Selskapsopplysninger | Auto fra Brønnøysunds åpne API: enhet, roller (før-bildet), signatur-grunnlag, regnskapstall, kontaktinfo, konkurs-/avviklingsvarsel |
| Innhenting fra kunde | Token-sikret 5-stegs skjema (mobil), prefill, mangler-løkke m/røde felt, purre-meldingsmal |
| Dokumentproduksjon | DOCX-malregister (hans maler lastes opp i /maler) m/autoutfylling + [MANGLER]-krysskontroll; eksempelmaler som fallback; ZIP-pakke |
| Kontroll/godkjenning | Godkjenn/avvis m/kommentar, logges m/bruker+tid, LÅSER dokumentene (filer + rader) |
| Brønnøysund-innsending | Handoff: dyplenke til selskapet i virksomhet.brreg.no, referanse+status registreres (aldri auto-innsending) |
| Oversikt | Dashboard m/KPI-er, søk, filtre, hendelseslogg, NESTE HANDLING per sak, full revisjonslogg |

Robusthet: 53 tester, statusmaskin-vakter, validering, XSS-/DoS-herdet, fail-closed auth.

## B. Neste utvidelser (rekkefølge etter verdi/avhengighet)

1. **Påls ekte maler + e-postleverandør** (venter kun på ham) → ekte dokumenter + automatisk
   innboks-intake via /api/inbound (M365- og Gmail-mønstrene er ferdig utredet; m365-connector
   finnes allerede bygget i grossist-plattformen og kan gjenbrukes).
2. **Purre-/frist-/MVA-varselmodul**: gjenbruk policy-motor-designet fra grossist-arkitekturen
   (nivå 1–4, regler-som-data m/gyldighetsdato: purregebyr 38 kr, 1+inkassovarsel, 12,0 % p.a.).
   Frister som kalenderdata (a-melding 5., MVA-terminer, årsoppgjør) — varsling, aldri innsending.
3. **WooCommerce-webhook**: butikkjøp på ASListen.no → sak automatisk (krever kun API-nøkkel fra WP-admin).
4. **Signeringsadapter** (BankID/Signicat/Penneo — leverandørvalg hos Pål) → status per signatar, låst signert versjon.
5. **Altinn/Maskinporten** (senere trinn): systembruker for UTHENTING (a-melding-status, skattekonto)
   — innsending forblir manuell/hos Pål; juridisk avklart i grossist-researchen.
6. **Historisk import**: gamle kunder/dokumenter inn i CRM-et (arkivsøk).

## C. Multi-tenant-krav (trinn 3–4 — standardisering → kommersielt)

Det som MÅ endres før plattformen selges til flere regnskapsførere:

- **Tenant-modell**: én-bruker-antakelsen ligger i auth (Basic, hardkodet «Pål»), `assigned_to`,
  approvals. Krav: firma-/brukertabell, roller (admin/saksbehandler), per-tenant dataisolasjon.
  Gjenbruk: grossist-plattformens `packages/db` har ferdig herdet DB-per-tenant-mønster m/22 tester.
- **SQLite → Postgres** ved multi-tenant (samme repository-mønster; SQLite er riktig til og med trinn 2).
- **Malregister per tenant** (finnes allerede som register — trenger bare tenant-kolonne).
- **Betaling/lisens**: gjenbruk `@grossist/license` (ed25519-lisens, 17 tester, ferdig bygget)
  eller SaaS-abonnement — beslutning ved trinn 4.
- **Domene/branding per tenant** + databehandleravtale-mal (GDPR fra dag én).
- **Ikke bygg noe av dette nå** — trinn 1-læringen fra Påls daglige bruk avgjør skjæringen.

## Strategisk notat

Grossist-plattformen og aslisten-crm konvergerer: samme mønstre (policy-nivåer, connectorer,
tenant-isolasjon, lisens) er allerede bygget som pakker i grossist-repoet. Når aslisten-crm
når trinn 3 er det sannsynligvis RIKTIG å montere de pakkene inn fremfor å skrive nytt —
det er én produktplattform med to ansikter (regnskapsfører-CRM og SMB-adminplattform).
