# Sluttrapport 27.10: Solar Consulting og arbeidsoppsettet

Omtrent 150 PR-er er merget i dag. Arbeidet ble gjort av seks paner (infra-1, trading-1, learning-1, tools-1, data-1, paal-1 og admin-1) koordinert av orchestrator-1.

## 1. Arbeidsrammeverket: Solar-Consulting/drift
- **Repo og board.** Repoet `drift` har et GitHub Project-board med kolonnene Venter på eierskifte → Klar → Pågår → Til godkjenning → Ferdig. Alle 120+ oppgaver er issues med hovedissue og deloppgaver, og hver beskrivelse har mål, steg, «ferdig når» og avhengigheter.
- **Arbeidsflyt.**
  - `ARBEIDSFLYT.md` beskriver hvordan vi jobber.
  - `bin/drift` er kommandolinjeverktøyet.
  - En GitHub Action lager *Ukestatus* hver mandag kl. 08.
- **Juristen (veldora-anbud).** Han er onboardet og har et bestillingsskjema. `drift-vakt` sender alle bestillinger og alt merket `agent-kan-ta` til en agent innen 5 minutter.
- **#126 «Beslutninger for eierne».** Alt bare dere kan avgjøre er samlet her, med «→ blokkerer #N». Det vises også i cockpit.

## 2. Dokumenter (utkast i drift, til godkjenning)
- **Personvern og juss**
  - art. 30-protokoll
  - DPIA-mal
  - avviksrutine
  - personvernerklæring
  - underdatabehandlere med DPF-status
  - kartlegging av dataflyt til Anthropic
  - gjennomgang av SSA 2026
  - innhenting om bruksvilkår og KI-forordningen
  - Anthropic AUP 12.11
- **Sikkerhet**
  - ROS-analyse (H-01 og H-02 oppdatert med målinger)
  - dataflytdiagram
  - tilgangsstyring med 6 avvik
  - informasjonssikkerhetspolicy
  - beredskapsplan
  - lagringstid
  - tilgjengelighet (axe: 0 brudd på 9 sider)
  - miljø
- **Anbud**
  - ESPD
  - prisliste og tilbudsbrev
  - CV-mal
  - kvalitetssystem
  - tekster om informasjonssikkerhet
  - innsynsbegjæringer (8, ikke sendt)
  - DPS-oversikt med 25 issues
  - runbook for dag 1 etter eierskiftet
  - kredittvurdering (0–349 kr)
- **Tilganger.** Digdir, Maskinporten, KS Fiks (e-post klar), Feide, FINT, virksomhetssertifikat (trengs ikke, ADR-0024 rettet), anbudsportaler og Google Workspace.
- **Noark.** Den nye arkivloven har ikke Noark-plikt. Anbefalingen er integrasjon via Fiks Arkiv pluss § 5. 100 kunngjøringer er lest.
- **Finansiering.**
  - Oversikt over aktuelle ordninger.
  - Søknadsutkast til Innovasjon Norge (oppstartstilskudd 1, skrevet om til Nova).
  - FORREGION er blokkert fordi det krever ansatte.
  - SkatteFUNN er ikke mulig nå (0 lønn, ingen revisor).
- **Strategi.**
  - Nova bør starte med PPT (20 anskaffelser hos 10 kjøpere, to leverandører vinner).
  - Kravene i Abakus' kravspesifikasjon er kartlagt.
  - Veier til første kunde uten «3 referanser» (pilot, innovasjonskontrakt).
  - Færders markedsdialog er forberedt.

## 3. Horizon (Nithu0/Solar-Consulting), i produksjon
- **Sikkerhet**
  - grense på innloggingsforsøk per IP (verifisert i prod)
  - TOTP for admin (enroll, ikke påkrevd ennå)
  - herding av seed-admin
  - persondata maskeres før KI-kall
  - samtykkefilter
  - riktige datatyper slik at personvernpolicyen kan blokkere
- **Backup.**
  - Daglig og ukentlig backup er slått på for begge volumene. Det fantes ingen før.
  - Gjenoppretting er testet: 154 av 154 tabeller og 1,5 mill. rader var identiske.
- **Data**
  - slettejobb for persondata (tørrkjørt, sletter ingenting før du har satt lagringsregler)
  - sletting av utløpte økter
  - opprydding i tildelinger: MISSING-dubletter 43 → 0, gammel rot 60 → 0
- **DPS-motor.** Kjører i skyggemodus. 20 DPS-er gir «kan søke». Kontroll av 10 vurderinger ligger i #180.
- **CI.** Alt er låst til ubuntu-24.04. e2e var knekt for alle PR-er.
- **Nettside**
  - funksjonene kjører i EU (Stockholm)
  - personvernteksten er rettet
  - 301 fra veldora.no venter på TXT-poster
  - ADR-0013 og `railway.ts` er oppdatert
- **Horizon-repoet.** Importert til Solar-Consulting/horizon og klart for flytting. Venter på deg.

## 4. Terra, Nova og Aurora
- **Merget i Terra:**
  - krav om KI-godkjenning
  - Azure-stacken som Bicep (ikke rullet ut, ca. 21–25 USD/mnd i test)
  - publisering av pakker
  - ScimStore i Prisma
  - vakt på main i alle repoer
- **Venter på Tintun (#164):**
  - Terra #9: 6 nye base-krav
  - Terra #10: revisjonslogg
  - Terra #11: eksport og exit
  - Terra #13: Enhetsregisteret og DSF-grensesnitt
  - nova #2: Nova-skjelett med innlogging, sak, roller, revisjonslogg og WCAG
  - aurora #4
- **Aurora.** NOTICE-filer lagt til og lisenskommentar rettet.

## 5. Cockpit og arbeidsoppsett (command-center)
- **«Hoved»-fanen** viser beslutninger med alder og hva de blokkerer, godkjenningskø, alle panene med tilstand, kontostatus og worktrees med ryddeknapp. Aktivitet-fanen viser PR-er, commits og feed per prosjekt.
- **Cockpit-drift.** Mobilvisning og produksjonsbygg er på plass. To sikkerhetshull i innloggingen er tettet, og det er grense på innloggingsforsøk. Plan for Tailscale ligger i `docs/ops/COCKPIT-TAILSCALE-PLAN.md`.
- **Ryddet.**
  - 118 testforslag i godkjenningskøen
  - testene skriver ikke lenger til ekte databaser
  - 84 ferdige worktrees fjernet
  - vakt for delte checkouter, som skal stå på main
- **Brain**
  - synken hadde stått siden 13.07. `brain-sync.timer` går nå hvert 15. minutt til grenen `sync/NithuPC`
  - morgenbriefen har timer med catch-up og årsaker
  - session-start tar 0,5 s i stedet for 7–12 s
  - distill-retry kjører
  - minnesøket er målt på ekte spørsmål og forbedret: MRR 0,335 → 0,388
- **Flytting til ny PC**
  - workstation-repo
  - sync- og apply-skript
  - backup dekker hullene: bundler, stash, `~/.cache`-staging og shred
  - alt ulagret arbeid er sikret på GitHub (grossist-plattform, leadgen ×2, call-center), men persondata og `.env` går bare til USB

## 6. Opprydding i PR-er (kveld)
- **command-center:** 13 PR-er lukket. 12 var utkast fra mai i code-1/code-2-lanene, erstattet av #77. Den siste (#98) ble tatt inn via #101. Grenene er beholdt.
- **aslisten-crm:**
  - #35 og #36 er lukket fordi migreringsnumrene kolliderer med main. De er sporet i issue #73 for gjenoppliving.
  - #38 er lukket fordi dokumentet finnes på main.
  - #37 står åpen fordi den trenger vurdering.
- **drift:** #104 er merget.
- **Står åpent med vilje:**
  - Terra ×4 og nova #2 venter på Tintun.
  - aurora #1 og #4 er aktive.
  - grossist-plattform #1 og call-center-ai-demo #1 venter på deg.
  - ai-assistent ×3 hører til Nexus, som er på is.

## 7. Nexus
Lagt på is (operatør 27.10). Det som ble funnet før det, ligger i `00-claude-inbox/nexus/2026-10-27/`.

## 8. Det bare du kan gjøre
Solar Consulting står i https://github.com/Solar-Consulting/drift/issues/126. Resten står i `00-claude-inbox/OPERATOR-TODO-2026-10-27.md`. Viktigst:
1. Eierskiftet. Når det er registrert, følger du runbooken `anbud/dps/dag-1-etter-eierskiftet.md` (frist hos Brønnøysundregistrene 22.11).
2. Velg Novas sakstype (anbefalt PPT) og meld interesse i Færders markedsdialog.
3. Gi nova lesetilgang til pakkene (1 min), fjern `sannajammeh`, bytt admin-passordet og sett opp TOTP.
4. Gjør Horizon-flyttingen: installer Railway-appen på org, legg inn 2 secrets og gi go.
5. Gi OPERATOR-APPROVED på tiger-brain#1. Brain har ikke vært på main siden juli.
6. Kjør `preflight-old-machine.sh --apply` før du bytter PC.
