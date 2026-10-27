---
date: 2026-09-21
project: renseri
source: job-20260921-175353-infra1-27536
author: infra-1
type: research-report
status: report-only (ingen DNS-endringer, kjøp eller kontoer opprettet)
---

# Google Workspace for Renseri (og Veldora): oppsettsplan

Merking: **FACT** = verifisert mot kilde (tilgang 2026-09-21). **ASSUMPTION** = min vurdering eller utledning. **UNKNOWN** = ikke avklart.

Kort konklusjon: én Workspace-tenant per juridisk enhet og sekundærdomener for merkevarer innenfor samme enhet. Renseri får Business Standard med EU-dataregion. Skjemaet sender via Gmail API med service account og domain-wide delegation, autentisert nøkkelfritt fra Vercel via OIDC. SMTP relay er reserveløsning. Workspace dekker kontor, e-post, kalender og filer. SMS, betaling og CRM må komme fra andre.

---

## 1. Workspace-struktur, pris, databehandleravtale og EU-lagring

### Én tenant eller flere?

- **FACT:** Én tenant kan ha opptil 599 sekundærdomener. Hver bruker på et sekundærdomene er lisensiert og betales for som vanlig. Fakturaadresse og logo kan bare settes for primærdomenet. Kilde: https://knowledge.workspace.google.com/admin/domains/add-a-user-alias-domain-or-secondary-domain (2026-09-21)
- **FACT:** Google har en egen prosess for å dele en Workspace-konto i to. Den finnes, men det er en migrering, ikke en innstilling man bare slår av og på. Kilde: https://knowledge.workspace.google.com/admin/domains/separate-a-google-workspace-account-into-two-accounts (2026-09-21)
- **FACT:** CDPA (Cloud Data Processing Addendum) er avtalen mellom Google og kunden. Kunden er behandlingsansvarlig og Google er databehandler. Admin godtar den under Account > Account settings > Legal and compliance. Kunder utenfor Europa som er underlagt GDPR, må i tillegg oppgi tilsynsmyndighet. Kilder: https://knowledge.workspace.google.com/admin/compliance/privacy-compliance-and-records-for-google-workspace-and-cloud-identity (2026-09-21), https://cloud.google.com/terms/data-processing-addendum (2026-09-21)
- **FACT:** BAA er Googles HIPAA-tillegg for amerikansk helselovgivning og er ikke relevant her. Norsk krav er en databehandleravtale etter GDPR art. 28, og den rollen fyller CDPA. Kilde: samme compliance-side (2026-09-21)
- **ASSUMPTION:** Siden CDPA inngås per kunde og konto, blir enheten som eier tenanten avtalepart overfor Google. Legger Renseri AS kundedata i en Veldora-tenant, er Veldora databehandler for Renseri. Da trengs en egen databehandleravtale mellom selskapene, og fakturaen havner på feil selskap med feil fradrag og MVA. For B2B-kunder som ber om databehandlerkjede blir det fort rotete.
- **UNKNOWN:** Om «Veldora» er en egen juridisk enhet (AS/ENK) og hvilke av operatørens prosjekter som er egne selskaper.

**Anbefaling:** Én tenant per juridisk enhet. Merkevarer og prosjekter innen samme selskap legges som sekundærdomener i selskapets tenant. Renseri får egen tenant når selskapet er stiftet og domenet kjøpt. Workspace bør ikke opprettes før det finnes organisasjonsnummer, fordi tenanten er vanskelig å flytte senere. Hensynet til «færrest endepunkter» løses med én admin-identitet per tenant pluss en passordhåndterer. Å blande selskaper i én tenant er ikke veien dit.

### Kost per bruker

- **FACT:** Offisiell norsk prisside (hl=no) viser euro, ikke NOK. Prisene gjelder per bruker per måned eks. avgifter: Starter €6,80, Standard €13,60, Plus €21,10, og Enterprise etter avtale. Nye kunder får kampanje i 3 måneder (Starter −50 %, Standard/Plus −30 %) for de første 20 brukerne. Siden sier «Alle abonnementer faktureres månedlig». Kilde: https://workspace.google.com/pricing?hl=no (2026-09-21)
- **FACT:** I Norge kan man velge fakturering i NOK, EUR eller USD, med kort som betalingsmåte. Kilde: https://knowledge.workspace.google.com/admin/billing/payment-options-in-my-country (2026-09-21)
- **FACT:** Årsavtale (Annual/Fixed-Term) er billigere enn Flexible, med omtrent 17 % forskjell i Googles USD-eksempel. Ved årsavtale kan brukere først fjernes ved fornyelse, og oppsigelse før fornyelsesdato gir krav om restbeløpet. Flexible kan sies opp når som helst. Kilde: https://knowledge.workspace.google.com/admin/billing/compare-flexible-and-annual-fixed-term-payment-plans (2026-09-21)
- **FACT (sekundærkilde):** Flexible-prisene i EUR er oppgitt til Starter €8,10, Standard €16,20 og Plus €25,30. Tallene kommer fra en søkesnutt som gjengir Googles side, og jeg har ikke bekreftet dem direkte.
- **UNKNOWN:** Offisielle NOK-listepriser. Tredjepartskilden medhacloud.com oppgir 60 og 120 kr, men den er fra september 2024, før prisøkningen i 2025, og bør ikke brukes.
- **ASSUMPTION:** Med kurs ≈ 11,7 NOK/EUR, eks. MVA per bruker per måned:

| Plan | Årsavtale | Flexible |
|---|---|---|
| Business Starter | ca. 80 kr | ca. 95 kr |
| Business Standard | ca. 159 kr | ca. 190 kr |
| Business Plus | ca. 247 kr | ca. 296 kr |

Legg på 25 % MVA hvis det ikke er MVA-registrert enhet (omvendt avgiftsplikt ved kjøp fra utlandet, **ASSUMPTION**). Kontroller den faktiske NOK-prisen i checkout før kjøp.

### EU-datalagring

- **FACT:** Data regions policy støttes i Business Standard og Business Plus, i tillegg til Enterprise, Frontline og Education. Rapporter og regionpolicy per OU krever Enterprise Plus eller tilsvarende. Kilde: https://knowledge.workspace.google.com/admin/compliance/choose-a-geographic-location-for-your-data (2026-09-21)
- **FACT:** Prissiden merker «Enterprise-dataregioner» bare på Enterprise. Den utvidede varianten er altså Enterprise, mens grunnpolicyen også finnes i Business Standard og Plus. Kilde: prissiden over.
- **FACT:** Business Starter har ikke data regions. Kilde: prissiden og regionsiden over.
- **ASSUMPTION:** EU-region er ikke et GDPR-krav, siden overføring dekkes av CDPA og SCC-er. For B2B-kunder som spør «hvor ligger dataene?» er det likevel et enkelt og godt svar.

**Anbefaling:** Renseri velger **Business Standard** på Flexible det første året, går over til årsavtale når antall brukere er stabilt, setter dataregion til Europa og godtar CDPA samme dag som tenanten opprettes. Starter holder ikke, fordi den mangler dataregion og bare gir én bookingside per bruker (se §4). Start med 1–2 betalte brukere. `post@`, `booking@` og `faktura@` settes opp som gratis grupper eller aliaser, ikke betalte brukere.

---

## 2. E-post fra nettskjemaet på Vercel

Tre alternativer er vurdert.

**A. SMTP relay (smtp-relay.gmail.com)**
- **FACT:** Relay-tjenesten autentiserer enten på IP-adresse (allowlist) eller med SMTP AUTH, som krever TLS. SMTP AUTH går bare på port 587 med TLS. Uten TLS kan man bruke 25, 465 eller 587, men da uten SMTP AUTH. Grensen er 10 000 meldinger per bruker per døgn og 100 mottakere per SMTP-transaksjon. Man kan begrense avsendere til registrerte brukere eller til adresser i egne domener. Kilde: https://knowledge.workspace.google.com/admin/gmail/advanced/route-outgoing-smtp-relay-messages-through-google (2026-09-21)
- **FACT:** Vercel blokkerer bare port 25 utgående, og 465 og 587 er åpne. Vercel dokumenterer ikke statiske utgående IP-er for SMTP. Sendingen må awaites (eller bruke `after`/`waitUntil`) på Node-runtime, og Vercel anbefaler HTTP-API framfor SMTP. Kilde: https://vercel.com/kb/guide/serverless-functions-and-smtp (2026-09-21)
- **ASSUMPTION:** IP-allowlist fungerer derfor ikke fra Vercel uten en betalt statisk IP-funksjon. Det som gjenstår er SMTP AUTH med en brukers legitimasjon. Siden basic auth ble slått av (se B), betyr det i praksis et app-passord på en betalt bruker.

**B. App-passord mot smtp.gmail.com**
- **FACT:** Google slo av less secure apps og legacy-passord for SMTP/IMAP/POP for alle kontoer 14. mars 2025. App-passord finnes fortsatt. Kilde: https://knowledge.workspace.google.com/admin/sync/transition-from-less-secure-apps-to-oauth (2026-09-21)
- **FACT:** App-passord krever 2-trinnsverifisering. De virker ikke hvis kontoen bare har sikkerhetsnøkler eller er i Advanced Protection, og de blir ugyldige når kontopassordet endres. Google skriver at de «aren't recommended». Kilde: https://support.google.com/accounts/answer/185833 (2026-09-21)
- **FACT:** Grensene er 2 000 meldinger, 10 000 mottakere og 3 000 eksterne mottakere per bruker per døgn. En prøvekonto har 500 per døgn. Kilde: https://knowledge.workspace.google.com/admin/gmail/gmail-sending-limits-in-google-workspace (2026-09-21)
- **ASSUMPTION:** Dette er enklest å sette opp, men gir en langlevd hemmelighet knyttet til en person, og den ryker stille når passordet byttes. Google strammer inn gradvis, så løsningen har kort levetid.

**C. Gmail API med service account og domain-wide delegation**
- **FACT:** DWD settes opp av super admin under Security > API controls > Domain-wide delegation, med klient-ID og scopes. Google advarer om at appen får tilgang til data for alle brukere, og anbefaler minst mulig scope og jevnlig gjennomgang. Kilde: https://knowledge.workspace.google.com/admin/apps/control-api-access-with-domain-wide-delegation (2026-09-21)
- **FACT:** Organisasjoner i Google Cloud opprettet etter 3. mai 2024 har `iam.disableServiceAccountKeyCreation` slått på som standard, så JSON-nøkler er blokkert. Kilde: https://docs.cloud.google.com/resource-manager/docs/secure-by-default-organizations (2026-09-21)
- **FACT:** Vercel støtter OIDC-federering mot GCP Workload Identity Federation. Løsningen bruker kortlevde tokens og ingen lagrede nøkler, med standard env-navn `GCP_PROJECT_ID`, `GCP_PROJECT_NUMBER`, `GCP_SERVICE_ACCOUNT_EMAIL`, `GCP_WORKLOAD_IDENTITY_POOL_ID` og `GCP_WORKLOAD_IDENTITY_POOL_PROVIDER_ID`. Tilgang kan låses til `owner:<team>:project:<prosjekt>:environment:production`. Kilde: https://vercel.com/docs/oidc/gcp (2026-09-21)
- **ASSUMPTION:** DWD krever et JWT med `sub` = brukeren som impersoneres. Med OIDC-flyt har man ingen privat nøkkel, så JWT-et signeres via IAM Credentials `signJwt`. Service-kontoen trenger da `roles/iam.serviceAccountTokenCreator` på seg selv. Deretter byttes JWT-et mot et access token og man kaller `gmail.users.messages.send`. Mønsteret er kjent, men jeg har ikke testet det mot Vercel. Regn med en halv til én dags arbeid første gang.

**Anbefaling: C (Gmail API + DWD, nøkkelfritt via Vercel OIDC), med scope bare `https://www.googleapis.com/auth/gmail.send`.** Kallet går over HTTPS, som passer serverless, og det finnes ingen langlevd hemmelighet i Vercel. Meldingen havner i «Sendt» hos avsenderbrukeren, og DKIM-signeres av Google. Risikoen ved DWD er at tjenesten kan sende som hvilken som helst bruker i domenet. Den er akseptabel her fordi scopet bare gir sending og tenanten er liten. Hvis OIDC-flyten stopper opp, er reserven A med SMTP AUTH på 587 og app-passord for en dedikert bruker. Den bør ikke bli permanent.

Env-variabler (Vercel, Production og Preview separat):

```
# GCP / OIDC (ingen hemmeligheter; identifikatorer)
GCP_PROJECT_ID=
GCP_PROJECT_NUMBER=
GCP_SERVICE_ACCOUNT_EMAIL=          # f.eks. renseri-mailer@<prosjekt>.iam.gserviceaccount.com
GCP_WORKLOAD_IDENTITY_POOL_ID=vercel
GCP_WORKLOAD_IDENTITY_POOL_PROVIDER_ID=vercel
# Gmail
GMAIL_IMPERSONATE_USER=             # betalt bruker, f.eks. daglig leder
MAIL_FROM=                          # f.eks. "Renseri <post@domene.no>" (alias/send-as på brukeren)
MAIL_TO_INTERNAL=                   # f.eks. booking@domene.no (gruppe)
MAIL_REPLY_TO_FROM_FORM=true        # sett Reply-To til kundens adresse
```

Kvitteringsmail til kunden sendes fra samme vei. Volumet på et B2B-kontaktskjema ligger godt under 2 000 per døgn (**ASSUMPTION**). Legg inn hCaptcha/Turnstile og rate-limit før skjemaet går live, slik at ingen bruker det til å spamme kunder i ditt navn.

---

## 3. DNS-poster (per domene)

| Type | Navn | Verdi | Status |
|---|---|---|---|
| TXT | `@` | `google-site-verification=...` (fra Admin) | FACT: kreves ved oppsett |
| MX | `@` | `1 smtp.google.com.` (fjern alle andre MX) | FACT: https://knowledge.workspace.google.com/admin/domains/set-up-mx-records-for-google-workspace (2026-09-21) |
| TXT | `@` | `v=spf1 include:_spf.google.com ~all` | FACT: https://knowledge.workspace.google.com/admin/security/set-up-spf (2026-09-21) |
| TXT | `google._domainkey` | nøkkel generert i Admin > Gmail > Authenticate email, 2048-bit, selector `google`. Trykk «Start authentication» etter DNS-propagering | FACT: https://knowledge.workspace.google.com/admin/security/set-up-dkim (2026-09-21) |
| TXT | `_dmarc` | fase 1: `v=DMARC1; p=none; rua=mailto:dmarc@<domene>; fo=1` | FACT (p=none først, rua alltid, egen postkasse/gruppe): https://knowledge.workspace.google.com/admin/security/set-up-dmarc (2026-09-21) |

Opptrapping av DMARC (**ASSUMPTION** om tidsløp, **FACT** om rekkefølge none → quarantine → reject):
1. `p=none` i 2–4 uker. Les rapportene og sjekk at alt legitimt passerer SPF eller DKIM med alignment.
2. `p=quarantine; pct=100` i 2–4 uker.
3. `p=reject`.

Øvrig:
- **FACT:** Alle som sender til Gmail må ha SPF eller DKIM. Masseavsendere (over 5 000 per døgn) må ha begge og DMARC, og Gmail har håndhevet dette strengere siden november 2025. Kilde: https://support.google.com/a/answer/81126 (2026-09-21)
- **FACT:** SPF tillater maks 10 `include:`. Kilde: SPF-siden over.
- **ASSUMPTION:** En eventuell transaksjonsleverandør i reserve (Resend eller Postmark) bør ligge på et eget subdomene, for eksempel `mail.<domene>`, med egen SPF/DKIM. Da forblir rot-SPF-en ren og omdømmet holdes adskilt.
- **ASSUMPTION:** MTA-STS og TLS-RPT er valgfritt og kan vente.
- `rua`-adressen bør være en gruppe (gratis), ikke en betalt bruker.

**Anbefaling:** Legg inn alle fem postene samme dag som tenanten opprettes. DKIM må være aktiv før skjemaet går live. DMARC starter på `p=none` og trappes opp til `reject` innen omtrent 6–8 uker.

---

## 4. Senere moduler: hva Workspace dekker og hva som mangler

| Behov | Workspace | Vurdering |
|---|---|---|
| Booking av henting/levering | Calendar appointment schedules | **FACT:** Starter gir én bookingside per bruker. Standard og Plus gir ubegrenset antall sider, e-postpåminnelser, verifiserte bookinger, Stripe-betaling ved booking og medverter. Kilder: https://support.google.com/calendar/answer/16287038 (2026-09-21), https://workspace.google.com/pricing?hl=no (2026-09-21). **ASSUMPTION:** Holder for tidlig B2B-avtalebooking. Ruteplanlegging og kapasitet per bil dekkes ikke |
| Bilder av plagg/sko/nøkler, ordremapper | Drive (2 TB/bruker på Standard) + Shared drives | **FACT:** Lagringsmengde fra prissiden. **ASSUMPTION:** Godt nok som arkiv. For opplasting fra skjema eller app trengs Drive API via samme service account, eller heller objektlagring (Vercel Blob eller GCS) med lenke i ordren |
| Enkel ordre-/kundeliste | Sheets | **ASSUMPTION:** Fungerer som MVP de første månedene. Uten skikkelig datamodell faller det sammen ved 24/7-drift og flere sjåfører |
| Intern chat | Google Chat (i alle Business-planer) | **ASSUMPTION** (ikke eksplisitt verifisert per plan i dag). Dekker internt behov. Egner seg ikke for kundedialog |
| Video/kundemøter | Meet | **ASSUMPTION:** inkludert, men ikke kritisk |
| Arkiv/eDiscovery | Vault | **FACT:** Kun Plus og oppover. Kilde: prissiden. Ikke nødvendig nå |

Det Workspace ikke dekker:
- **SMS og varsling for 24/7-utrykning:** trenger en SMS-leverandør (Twilio, Sveve, Link Mobility eller lignende) og vaktrotasjon. **UNKNOWN:** Om Google Voice for Workspace kan brukes med norske nummer. Uansett er det ikke et SMS-API for varsling.
- **Betaling:** Stripe dekker kort og faktura, og Vipps er nesten obligatorisk i Norge (**ASSUMPTION**). B2B krever EHF/faktura via regnskapssystem som Fiken eller Tripletex, og det ligger utenfor Workspace.
- **CRM, ordre og booking med status:** ekte B2B-drift med avtalekunder, faste hentinger og SLA krever egen database, for eksempel Postgres via Vercel-integrasjon, eller et CRM. Sheets og Calendar holder bare som MVP.
- **Reserve for transaksjonell e-post:** en HTTP-API-leverandør (Resend eller Postmark) på eget subdomene, som tas i bruk hvis volum eller leveringsrate krever det. Ikke nødvendig ved oppstart.

**Anbefaling:** Bruk Workspace til identitet, e-post, kalender, filer og intern chat. Calendar appointment schedules brukes til B2B-avtaler i MVP-fasen. Fra dag én planlegges tre tjenester utenfor Workspace: SMS-leverandør (kreves for 24/7), Stripe og Vipps, og en egen ordre-database når første avtalekunde signerer. Da er det fire leverandører totalt (Google, Vercel, SMS, betaling), og det er omtrent minimum for denne forretningsmodellen.

---

## Neste steg (operatør-gated)

1. Avklar juridisk struktur: finnes Veldora som selskap, og blir Renseri eget AS? Dette avgjør tenant-oppsettet.
2. Kjøp domene for Renseri. Dette er et kjøp.
3. Opprett Workspace-tenant for Renseri på Business Standard med Flexible, fakturert i NOK. Dette er kjøp og kontoopprettelse. Samme dag: godta CDPA, sett dataregion til Europa og slå på 2SV for alle.
4. Legg inn DNS-poster (verifisering, MX, SPF, DKIM og DMARC `p=none`). Dette er en DNS-endring.
5. Opprett GCP-prosjekt, Workload Identity Pool for Vercel-teamet `veldora2` og en service account, og autoriser DWD med kun `gmail.send`. Dette er en kontoendring og krever super admin.
6. Implementer skjemasending i Renseri-repoet med env-variablene i §2. Dette går gjennom push-gate («OK kjør»).
7. Trapp DMARC opp til `quarantine` og deretter `reject` etter gjennomgått rapportering. Hvert steg er en DNS-endring.
8. Kontroller den faktiske NOK-prisen i checkout før kjøp (UNKNOWN i dag).
