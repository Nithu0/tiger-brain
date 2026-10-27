# Kompetanseintervju og leveranseklarhet — status 2026-10-18 (admin-1)

## Gjennomført
| Hva | Status | Hvor |
|---|---|---|
| Intervju Nithusan | **Importert til prod** etter eiergodkjenning. Verifisert read-only: 13 fakta, 6 referanser (Sauda + Sastech, Hassel Solar Design, Suncel, Provitaz, El-24, alle med kundesamtykke) koblet til Nithusan, profil flettet inn | `~/Solar-Consulting-kompetanse/intervju/nithusan-2026-10-18.yaml` (utenfor git) |
| Intervju Tintun | **Utkast**, `godkjent: nei`. 5 kompetanser, 3 personlige referanser (Nevion ×2, frilans), 10 fakta | `~/Solar-Consulting-kompetanse/intervju/tintun-2026-10-18.yaml` |
| Intervju Alper | **Ikke mottatt.** Spørreskjema sendt | `~/Solar-Consulting-kompetanse/intervju/sporreskjema-alper.md` |
| Sjekkliste for leveranseklar dokumentasjon | Ferdig, med kilder | `LEVERANSEKLAR-SJEKKLISTE.md` |
| Utkast databehandleravtale | Ferdig, ikke juridisk gjennomgått | `UTKAST-DATABEHANDLERAVTALE.md` |
| Utkast kvalitetssystem | Ferdig, rettet etter Tintuns svar (ende-til-ende i stedet for «stresstest») | `UTKAST-KVALITETSSYSTEM.md` |

## Kommer i morgen (operatør, 2026-10-19)
- Alpers svar på spørreskjemaet. Admin-1 lager YAML, Alper godkjenner, og så importeres det.
- Tintuns oppdateringer på [SJEKK]/[FYLL INN]:
  - om masteren er fullført;
  - hvilke frilanskunder som kan navngis;
  - tofaktor på Azure og passordhåndterer;
  - målbare resultater;
  - om Nevion godtar at prosjektene nevnes.
  Deretter `godkjent: ja` og import.

## Åpne funn som krever beslutning
1. **Faktum i prod er feil:** «Hele systemet stresstestes før levering» (fra Nithusans intervju). Tintun sier det er ende-til-ende-tester (Playwright), ikke lasttest. Operatøren må rette det i CRM-admin (Kompetanse → Fakta). En ny import oppretter et nytt faktum og lar det gamle stå.
2. **Konkurranseklausul:** Tintun kan ikke ta oppdrag innen kringkasting/media (fast stilling hos Nevion). Det må avklares om sporet *medieovervåking* (tracks.ts) omfattes.
3. **Nevion-referanser:** «må spørre». Moxela er et produkt som ikke er lansert, og kan være konfidensielt. Ingen bruk i tilbud før Nevion har sagt ja.
4. **IT-kundereferanser:** selskapet har ingen (`[mangler]`). Tintuns er personlige (arbeidsgiver). Kravet «erfaring fra tilsvarende oppdrag» kan bare delvis dekkes via CV-er.
5. **Eierskiftet** er ventet uke 43. Firmaattest, signaturrett og ansvarsforsikring kommer etter det.
6. **Databehandleravtalen (jurist):** avvik 48 t hos Anthropic mot 24 t mot kunden, og varsel om underleverandører 15 mot 30 dager.
7. **Regelendring 1.7.2026:** anskaffelsesforskriften §7-2 og §7-9 er opphevet og flyttet til loven §§5b/5e/5l. Plattformens egne tekster (klage/juridisk) bør sjekkes for referanser til de gamle paragrafene.

## Teknisk
- Importen for prod: `bash ~/.cache/firm/import-intervju.sh` (tørrkjøring) / `--apply`. Den spør etter innlogging skjult, så passordet aldri står i en kommando.
- Verifiserings-SQL (ikke committet): `~/code/Veldora-import/projects/anbud/crm/scripts/baseline/intervju-import-sjekk{,2}.sql`.
- Ikke pushet: grenen `tre-scopes-tall` (8605fd5) med SQL og eval for tre-scopes-notatet. Venter på svar om den skal i repoet.
