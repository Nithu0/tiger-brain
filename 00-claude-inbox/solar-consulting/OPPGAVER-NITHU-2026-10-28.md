# Oppgavene dine (28.10)

Alt agentene ikke kan gjøre for deg. Hvert punkt har en lenke. Avkrysningslisten er https://github.com/Solar-Consulting/drift/issues/126, og den vises også i cockpit-fanen «Hoved». Nexus er på is og er ikke tatt med.

## A. Kan gjøres i dag, hver tar under 15 minutter
1. [ ] **Gi nova lesetilgang til base-pakkene** (1 min). Da blir nova-CI grønn.
   https://github.com/orgs/Solar-Consulting/packages/npm/tilgang/settings og https://github.com/orgs/Solar-Consulting/packages/npm/ui/settings → Manage Actions access → Add repository → nova (Read)
2. [ ] **Fjern `sannajammeh`** (FrendDigital) fra Nithu0/Solar-Consulting. Hun har skrivetilgang i dag. Gå til Settings → Collaborators.
3. [ ] **Bytt admin-passordet i Horizon** (/admin), og slett `SEED_ADMIN_EMAIL` og `SEED_ADMIN_PASSWORD` fra crm på Railway.
4. [ ] **Slå på TOTP for admin.** Gå til /innstillinger/sikkerhet, lagre kodene, test én gjenopprettingskode og si fra. Da settes den som påkrevd.
5. [ ] **Legg inn to TXT-poster** på `_vercel.veldora.no` hos Webhuset, så veldora.no sender videre til solarconsulting.no:
   `vc-domain-verify=veldora.no,b1c0d562b036757c8bfd`
   `vc-domain-verify=www.veldora.no,c9e07e06be841c7a9e21`
6. [ ] **Fasit for rødt lag** (ca. 10 min, du eller Alper): https://github.com/Solar-Consulting/drift/issues/189
7. [ ] **Kontroller 10 DPS-vurderinger** (ca. 10 min): https://github.com/Solar-Consulting/drift/issues/180. Da kan motoren slås på.
8. [ ] **Opprett personlig Mercell-konto** (hver av dere). Den trengs for å lese anbudsdokumenter. Se #17.
9. [ ] **Godkjenn tiger-brain#1** med OPERATOR-APPROVED. Brain har ikke vært på main siden juli. Godkjenn også rettingen av gitleaks-skannet: https://github.com/Nithu0/tiger-brain/pull/1

## B. Beslutninger (svar i #126 eller til meg)
10. [ ] **Novas første sakstype.** Anbefaling: PPT. Se `strategi/nova-sakstype.md`.
11. [ ] **Noark.** Integrere via Fiks Arkiv og arkivlova § 5, uten egen kjerne? (#54)
12. [ ] **Prismodell.** Timepris eller ikke? (#46)
13. [ ] **Søknaden til Innovasjon Norge (oppstartstilskudd 1).** Skal den gjelde Nova? Den krever 3–5 kundesamtaler. (#98)
14. [ ] **FORREGION.** Ansette eller lønne noen, og en FoU-partner? Det trengs for å søke. (#99)
15. [ ] **Revisor og lønn.** Avgjør om SkatteFUNN er mulig. (#64)
16. [ ] **Lagringsregler i Horizon.** Forslag: kunde-e-post 365 dager, WhatsApp 90 dager. Ingenting slettes før 29.12. (`sikkerhet/lagringstid.md`)
17. [ ] **Personvernerklæringen.** Bestem lagringstid for skjema, om skjemadata kan gå til Anthropic, og hvilken kontaktadresse som skal stå. (#22)
18. [ ] **Juristen.** Ned fra admin til medlem med skrivetilgang bare til drift? (A1)
19. [ ] **2FA.** Alle slår på 2FA, og så skrur vi på kravet i organisasjonen. (A2)
20. [ ] **Penger:**
    - GitHub Team (ca. 4 USD per bruker i måneden) for branch protection og 2FA-krav
    - Vercel Pro for databehandleravtale
    - Ansvarsforsikring (kreves ved første kontrakt, ikke ved DPS-opptak)
21. [ ] **NTNU-DPS for solceller.** Gå inn sammen med en installatør? (#192)

## C. Horizon-flytting til organisasjonen (ett vindu, ca. 1 time)
22. [ ] **Installer Railway-appen** på org Solar-Consulting (railway.com → Account settings → GitHub).
23. [ ] **Legg inn to secrets.** Kjør hver kommando på én linje:
    `gh secret set ANTHROPIC_API_KEY -R Solar-Consulting/horizon`
    `gh secret set VERCEL_TOKEN -R Solar-Consulting/horizon`
24. [ ] **Gi go for vinduet.** tools-1 følger `00-claude-inbox/solar-consulting/horizon-cutover-sjekkliste.md`. Nithu0/Solar-Consulting flyttes inn i organisasjonen i samme runde (#52).

## D. Sende eller kontakte (tekstene er skrevet)
25. [ ] **Meld interesse i Færders markedsdialog** for PPT, og bestem hvem som deltar. (#170, `strategi/faerder-markedsdialog.md`)
26. [ ] **Send to e-poster:** til fiks@ksdigital.no om testtilgang og til servicedesk@digdir.no med spørsmål. (`tilganger/`, #13 og #9)
27. [ ] **Send innsynsbegjæringene** (8 stk.) når juristen har sett malen. (`anbud/innsyn/`, #125)
28. [ ] **Kundesamtaler om Nova og PPT.** Kandidatlisten ligger i `finansiering/in-oppstart-1/kundefunn.md`.

## E. Når eierskiftet er registrert (samme dag)
Følg `anbud/dps/dag-1-etter-eierskiftet.md` i denne rekkefølgen:
29. [ ] **Kontroller roller, signaturrett og reelle rettighetshavere** i Brønnøysundregistrene, og endre næringskoden til IT (62.0x). (#4, #161)
30. [ ] **Hent firmaattest, skatteattest og kredittvurdering:**
    - firmaattest (#3)
    - skatteattest (#2)
    - kredittvurdering: Creditsafe er gratis, Proff Premium koster 349 kr (#190)
31. [ ] **Søk DPS:** Brønnøysundregistrene (frist 22.11), Stortinget og Sjøfartsdirektoratet. Totalt er det 20 DPS-er vi kan søke.
32. [ ] **Digdir og Altinn:**
    - signer bruksvilkårene i Samarbeidsportalen (#9, #10)
    - deleger rettigheter i Altinn (#11)
33. [ ] **Oppdater aksjeeierboken.** (#5)
34. [ ] **Send adressebevis til Microsoft Partner.** (#71)
35. [ ] **Send søknadene** til Innovasjon Norge og eventuelt FORREGION. (#98, #99)

## F. Ellers
36. [ ] **Anthropic Console.** Sjekk hvem som er avtalepart, og om nullagring (ZDR) er på. Finn også ut hvilken Microsoft-avtale vi har. (#20, #21)
37. [ ] **Google Workspace.** Velg utgave og fyll inn brukere og aliaser. (#72, `tilganger/google-workspace.md`)
38. [ ] **Testfaktura EHF** fra DNB Regnskap. Vi kan allerede motta EHF. (#8)
39. [ ] **Azure-abonnement** når Terra skal rulles ut. Koden ligger klar og koster ca. 21–25 USD i måneden i test. (#47)
40. [ ] **Tintun:** review-køen https://github.com/Solar-Consulting/drift/issues/164 (Terra #9, #10, #11 og #13, nova #2, aurora #1 og #4). aurora #1 trenger godkjenning fra deg.

## Utenfor Solar Consulting
41. [ ] **aslisten-crm:**
    - Flytting til EU: velg vindu (`aslisten-crm/docs/flytt-til-eu.md`).
    - Send Pål `docs/oppgaver/nytt-for-paal-2026-10-27.md`.
    - Ta stilling til #37 og #73.
42. [ ] **Se gjennom og merge** grossist-plattform #1 og call-center-ai-demo #1.
43. [ ] **Veldora-checkouten** står på `feat/secure-age`, med 2 commits som ikke er pushet og 7 filer med research som ikke er committet. Push, committ eller la den ligge.
44. [ ] **Før du bytter PC:** kjør `~/code/command-center/_bin/preflight-old-machine.sh --apply`. Noter passphrasen. Se `00-claude-inbox/workstation/klar-for-flytting-2026-10-27.md`.
45. [ ] **Etter flyttingen:** ja eller nei til cockpit over Tailscale (`command-center/docs/ops/COCKPIT-TAILSCALE-PLAN.md`).
