# admin-1 — onboarding v2 (2026-07-28)

Rolle: admin-1 (arver personal-1; overtar eget AS-regnskap fra as-1). Domene: salg/call-center, eget ENK-regnskap, personlig, frister. Kartlagt med 4 parallelle Explore-agenter + egne verifiseringer. PII-nivå: dette notatet holder helsedata ute og økonomidetaljer på grovnivå — detaljer står i repo-docs (lokalt).

## 1. AS/ — eget regnskap (VIKTIGSTE FLATE — fristdrevet)

**Korreksjon av premiss:** Entiteten er **ENK Kukaraja Sikkerhet** (org 930 320 412), ikke AS. Mappa heter "AS" og `AS/CLAUDE.md` (aldri oppdatert siden bootstrap 14.05) har tre motbeviste premisser: AS-vs-ENK "uavklart" (avklart: ENK), 50k MVA-grense-tracking (foretaket er MVA-registrert — irrelevant), a-melding/årsregnskap-frister (gjelder ikke ENK, jf. `docs/frister.md:73-79`). CLAUDE.md bør oppdateres.

**Fiken = sannhetskilde** (`docs/fiken-avstemming.md`, generert 20.07 — ferskeste regnskapsbilde): 16 fakturaer + 159 kjøp; lokal bilagskatalog dekker bare en brøkdel (4/16 fakturaer, 3/159 kjøp). `docs/fiken-drift-alert.md` står i VARSEL: 3 passerte terminer avviker >1000 kr mot lokal katalog.

**Frister** (kanonisk: `docs/frister.md`, verifisert 24.05):
- **Nærmeste: 31.08.2026 — MVA termin 3/2026, ~21k per 20.07-avstemming.** NB: eldre `mva-skatt-action.md` sier "til gode" for samme termin — motbevist av nyere avstemming. Sommerfristen 31.08 (ikke 10.08) bør dobbeltsjekkes i Altinn (WebFetch mot Skatteetaten feilet da kalenderen ble bygget).
- Deretter: forskuddsskatt 15.09, MVA T4 12.10, MVA T5 10.12, forskuddsskatt 15.12.
- **UVERIFISERT:** ingen fil bekrefter at skattemelding 2025 (frist 01.06) faktisk ble levert, eller Altinn-status for de 4 passerte MVA-terminene. `mva-skatt-action.md` sin 6-punkts action-liste fra 01.06 har ingen dokumentert utførelse.

**Lønn:** siste syklus = juni (FERDIG 10.-11.07; Fiken-kladd 12577080707 venter operatør-kontroll + manuell sending; åpen bekreftelse "Brann pending bytte = 70 kr?"). **Juli ikke startet** (i dag 28.07). Runbook finnes (`docs/lonnsskjema-utfylling-runbook.md`). Teknisk blokker: H16-recalc krever Excel (LibreOffice headless funker ikke i WSL) + Lockguard-bug i malen.

**Åpne bilagshull:** `Lønn mars/` tom; 12 fakturaer mangler lokalt; 17 kjøp uten vedlegg i Fiken (~81k netto); «Bot» 660 kr skal ompostéres; Twelvedata-abo hører trolig ikke til ENK-et; privat/næring uavklart (telefon, én flyreise, hjemmekontor-sats).

**Aktivt vs dødt:** Aktivt i juli: grossist-nisje-sporet (hovedaktivitet 20.-21.07), Fiken-scripts, Lønn juni, `Verspa/` (untracked ny sidestrøm, udokumentert). Superseded/utdatert: `oversikt.md`, `regnskap-status.md`, `bilag-katalog.md`, `mva-skatt-action.md`, `EXECUTION-DASHBOARD.md` (8 uker stille). Dødt: lofoten/, refi/, refi-business/, slidev/, inntekt-spor-A/. Ingen remote på repoet; 7 dager siden siste commit; ucommittet: slidev-pakkfiler, `.playwright-mcp/`-rusk (60+ filer, kan ryddes), `Verspa/`.

**Operatør-beslutninger som venter (AS):** (a) Fiken-kladd juni kontrolleres/sendes; (b) Brann-linja 70 kr; (c) Altinn-verifisering skattemelding + 4 terminer; (d) grossist-plattform §11-lista (inkl. selskapsform for produktinntekter — AS vs ENK); (e) avvikle eller regenerere superseded docs; (f) `Verspa/` — hva er det, skal det inn i strukturen?

## 2. call-center-ai-demo — salg/voice

**Tilstand: demobar, halvt dvalende.** Kjørbar offline uten nøkler (mock-providere, 13 norske demo-transkript, 25 ruter, 19 testfiler). Målgruppe eksplisitt Loyalty (13 use-cases mappet). Pluggbart STT/LLM/TTS-lag (`DEPLOY_TARGET`-bryter lokal/Azure). Intens burst 12.-23.06, så full stopp (35 dager).

- **Upushet:** siste commit `551f852` (ElevenLabs ConvAI) ligger kun lokalt; `project_state.md` untracked. Push = OK kjør-gate → operatør.
- **Ikke salgbar som produkt ennå:** auth, PII-maskering ikke koblet i STT-pipelinen (bevisst demonstrert som gap), samtykke/audit-logg, voice-loop ikke verifisert ende-til-ende, Azure-deploy skrevet men aldri bevist kjørt.
- **SIKKERHETSFLAGG (arvet fra security-review 23.06):** `HARD_LOCAL_PATHS` i `firm-job-run.sh:53` dekker ikke call-center-stier → feilmerket jobb med kundelyd kan nå Vast GPU. Uklart om fikset — **bør verifiseres av infra-1/tools-1** (fila eies av command-center-lanen, ikke min).
- Strategisk: produkt A1 (sales-roleplay) + Sales-Training-modulen i managed-AI-ops gjenbruker denne riggen; `salg`-launcheren (sales-1..3) peker hit. `callcenter.js-mcp` er urelatert tredjepartsrepo (navnelikhet tilfeldig).

## 3. Personlig — PII-STRENG (metanivå her)

**Verktøylag ferdig, datalag dødt.** Dashboard/aggregering/korrelasjonsmotor bygget+testet (siste commit 03.06), men kjører mot tomt datagrunnlag: 1 ekte daglig-logg totalt (21.05), 68 dager stillstand. Kjerneblokkeren er registrert i 4 filer uavhengig: **operatør må definere mål (alle 3 målfiler er PLACEHOLDER), mat-fase og trenings-split.** Q2-treningsprogrammet er utløpt uten etterfølger.

**Sikkerhet: SOLID og verifisert.** Gamle §0-flagget (helsedata-lekkasje til tiger-brain) er LØST 10.06: `07-personlig/` gitignorert i Brain, 0 filer tracket, aldri i git-historikken (ingen scrub nødvendig). Path-guard-hooks installert. Restrisiko (liten): `project_state.md`/`GOALS.md`/`CURRENT-STATE.md` er untracked men ikke gitignorert — `git add -A` ville committe dem (metadata-nivå, ikke helsedata). BESLUTNINGER-TRENGS.md lister 3 løste punkter som fortsatt åpne (bør avkrysses).

**Git:** står på `node-migration-personlig`, 1 commit foran `main`, aldri merget tilbake. Gamle personal-1-inbox-flaggene (mål-filer mangler, gitignore-mismatch, dashboard-orphan) er alle foreldet/løst — detaljer i agentrapporten; eneste rest er logger-mappestruktur-avviket (koden skriver flatt, docs sier uke-mapper) + at CLAUDE.md er bootstrap-signert og motsagt av virkeligheten.

## 4. Søking fulltid — arkivert, kun arv

**Formelt arkivert 27.07** (RETIRED-banner i GOALS.md + project_state.md): mål nådd — **rolle sikret hos Ambita (AI-ingeniør, ProspektAI)**. CLAUDE.md/README ikke oppdatert med arkivstatus. **Ingen løpende forpliktelser:** alle frister utløpt, `conductor.timer` IKKE installert i systemd (verifisert av meg 28.07). Merk: ingen arbeidsavtale/oppstartsdato dokumentert i repoet.

**Arv-risiko:** betydelig materiale ligger KUN ucommittet i arbeidstreet, uten remote: voice-agent (`agent/voice/`, gjenbrukbar WSL-lydstack), hele Ambita-intervjuprep-en, CV-generatorer v2/v3, søknads-skillen (oppdatert ucommittet). Gjenbruksverdi ellers: NAV-API-scanner (auth-fri), Excel-CRM-mønster, Streamlit-CRM, søknadsagent «bevis-ikke-adjektiver», 293-raders nettverksliste (gitignorert, lokal). Bevaring = commit/backup-beslutning → operatør (repoet har ingen remote; innhold delvis PII).

## 5. MCP-tilgangssjekk (F1)

| MCP | Status |
|---|---|
| Gmail (claude.ai) | ✔ tilkoblet |
| ClickUp (claude.ai) | ✔ tilkoblet |
| Google Drive (claude.ai) | ✔ tilkoblet |
| **ms365** | **! trenger re-auth** (operatør-handling) |
| fetch | ✘ nede (connection closed) |
| obsidian / filesystem / playwright / github | ✔ |

Forbehold: claude.ai-connectorene svarer ✔ på CLI-helsesjekk men er ikke eksponert i denne panens verktøyliste — faktisk bruk kan kreve sesjonsrestart. Samsvarer med tools-1 sitt inventar (ms365 re-auth + fetch nede).

## 6. Foreslått aktivt mål (GOALS.md satt)

**AS august-pakken før 31.08:** juli-lønn + MVA T3 klar til levering + Altinn-verifisering av passerte terminer (report-only) + operatør-liste (Fiken-kladd, bilagshull). Begrunnelse: eneste flate med hard frist; alt annet venter på operatør-beslutninger eller er strategisk kø.

## 7. Samlet operatør-liste (på tvers)

1. **AS:** Fiken-kladd juni-faktura kontroll/sending; Altinn-sjekk (skattemelding 2025 + 4 MVA-terminer); Brann 70 kr.
2. **ms365 re-auth** hvis ClickUp/mail-flyt skal brukes fra denne lanen.
3. **call-center:** OK kjør for push av `551f852`; be infra-1 verifisere HARD_LOCAL_PATHS-fikset.
4. **Personlig:** definere mål/mat-fase/split (blokkerer hele prosjektet) — eller eksplisitt parkere det.
5. **Søking-arv:** beslutning om commit/backup av ucommittet materiale (voice-agent m.m.).

— admin-1, 2026-07-28
