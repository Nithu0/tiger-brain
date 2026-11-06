# Plattformen v2: app på telefonen, og dokumenter rett i riktig Drive-mappe

Oppdrag fra operatøren 06.11 kl. 16:50: «tintun har lagd dashboard for solarlabs nå, sjekk det ut, fiks samme type og la oss få koblet alt sammen. Legger jeg inn et dokument der, så blir det puttet i riktig mappe i GWS.»

**Mål:** plattformen blir en app på hjemskjermen av samme type som Tintuns Solar Labs-dashbord. Et dokument lastet opp i appen havner i riktig mappe i Google Drive innen ett til to minutter, og appen viser lenken.

## Forbildet: Tintuns dashbord

Det ligger i `Solar-Consulting/solarlabs`, under `web/src/app/(studio)/dashboard`, `web/src/components/dashboard`, `web/src/app/api/dashboard/push`, `web/public/dashboard.webmanifest`, `dashboard-sw.js` og `dashboard-icons/`. Det har:
- installerbar PWA (manifest, ikoner, service worker, `display: standalone`, safe-area, svart stripe bak statuslinjen på iOS)
- sidemeny fra 1024 px og bunnmeny på telefon (tommelavstand), med teller for nye ting
- temabryter (lys/mørk) og hopp-til-innhold-lenke
- push-varsler med `web-push` og VAPID, abonnement lagret på serveren, testvarsel
- rolig design og norsk tekst

**Regler for gjenbruk:**
- Kopier og tilpass inn i `plattform`. **Ikke rør `solarlabs`.** Nevn i PR-teksten hvilke filer i solarlabs det bygger på (Tintun).
- Vil noe passe i Terra `@solar-consulting/ui` (felles for alle apper), skriv det som forslag i drift#198. Ikke flytt det nå.
- Behold det som virker i plattformen: Entra-innlogging, roller, revisjonslogg og broen. Ikke bytt til passordinnlogging som i solarlabs.

## Dokumentflyten

1. Brukeren trykker **Last opp** under Dokumenter (fil eller kamera på telefon) og velger hva det er. Forslaget kommer fra filnavnet, og brukeren bekrefter.
2. Appen lagrer filen **midlertidig** i Postgres og legger handlingen `arkiver-dokument` i køen. Maks 25 MB, og bare tillatte typer (pdf, docx, xlsx, pptx, png, jpg, heic, txt, csv).
3. Broen på PC-en henter filen, laster den opp med `gws drive files create --upload` til mappen kategorien peker på, og melder tilbake fil-id og lenke. **Deretter sletter appen den midlertidige kopien.**
4. Er kategorien usikker, havner filen i `00 Til sortering`, og eier får beskjed.
5. Appen viser «venter», så «arkivert» med lenke. Feiler det, vises feilen. Den skjules aldri.

**Mappestruktur** (Drive har i dag ingen delte disker og ingen struktur). Én delt disk, `Solar Consulting`:

```
00 Til sortering
01 Selskap        (stiftelse, overdragelse, styre, vedtekter)
02 Avtaler        (kunder, leverandører, partnere, NDA)
03 Økonomi        (faktura ut, faktura inn, kvitteringer, bank, regnskap)
04 Anbud          (ett undernivå per anbud)
05 Søknader       (stipend, fond, investorer, Microsoft/Azure-program)
06 Juridisk og personvern (DPA, personvernerklæring, vurderinger)
07 Kunder         (ett undernivå per kunde)
08 Markedsføring og salg
09 Maler
```

Kartet fra kategori til mappe ligger i `drift` (`drive/mapper.json`), så teamet kan endre det med en PR. Koden har ingen mappe-id-er.

**Roller:**
- **Eier:** alle kategorier.
- **Utvikler:** alt unntatt 01 og 03.
- **Jurist:** bare 02 og 06.

Rollen sjekkes både i appen og i broen.

## Fordeling

| Pane | Lane |
|---|---|
| tools-1 | PWA og skall av samme type: manifest, ikoner (Solar Consulting, ikke Solar Labs), service worker, sidemeny og bunnmeny, temabryter, safe-area. Lenke til Solar Labs-dashbordet i menyen for eier og utvikler. |
| learning-1 | Push-varsler (`web-push`, nye VAPID-nøkler bare for plattformen, abonnement i Postgres): ny beslutning, svar i oppdrag, dokument arkivert eller feilet, broen borte i over 10 min. Pluss sikkerhet for opplastingen: størrelse, MIME mot innhold, filnavn, rolle per kategori, CSRF og rate limit. |
| data-1 | Opplasting i Dokumenter: skjema, kategorivalg med forslag, midlertidig lagring, status (venter, arkivert, feilet) med Drive-lenke, sletting av kopien etter bekreftelse, og liste over siste opplastinger. |
| trading-1 | Broen: handlingen `arkiver-dokument` (hent, last opp, meld tilbake, idempotent per opplasting-id, prøv på nytt med ventetid, aldri dobbelt i Drive). Les `drive/mapper.json` fra drift. |
| admin-1 | Drive: opprett delt disk `Solar Consulting` og mappene, skriv `drive/mapper.json` i drift, og **mål om gws-innloggingen kan skrive**. Kan den ikke, meld det til orchestrator-1 straks, med hvilket scope som mangler. Ingen deling, invitasjon eller medlem uten operatøren. Med `sendNotificationEmail=false` hvis noe må settes. |
| paal-1 | QA på mobil når hver del er merget: installer appen på Android, last opp fra kamera og filer, prøv å laste opp i en kategori rollen ikke har, og prøv for stor fil og feil type. Bekreft at filen ligger i riktig mappe, og at kopien i Postgres er borte. |
| infra-1 | Fortsetter med sitt. |

## Rekkefølge

1. admin-1: delt disk, mapper og måling av skrivetilgang. trading-1 og data-1 bygger mot en testmappe imens.
2. data-1 og trading-1: én fil helt fra telefon til Drive. **Da melder orchestrator-1 til Nithu.**
3. tools-1 og learning-1 parallelt: PWA og push.
4. paal-1 QA hele veien.

## Grenser

- **Ingen hemmeligheter** i kode, logg, issues eller feed. Nye VAPID-nøkler genereres og pipes rett til Railway. Tokenfilene til gws leses ikke.
- **Dokumentinnhold:** broen og appen flytter filen, men leser den ikke, og sender den ikke til noen modell. Forslaget kommer bare fra filnavnet. Ingen kopi blir liggende igjen, verken på PC-en eller i Postgres, etter at filen er bekreftet i Drive.
- **Google Workspace:** ingen e-post, ingen deling, ingen invitasjoner og ingen nye brukere. Bare den delte disken og mapper. Ingenting slettes i Drive.
- **Penger:** ingen nye Railway-tjenester. Postgres er nok for midlertidig lagring.
- **Tintun:** ikke rør solarlabs. Logg i drift#198 at plattformen bygger på dashbordet hans.
- Små PR-er, og merge selv når CI er grønn. Maks 2 subagenter per pane. Kjør målrettede tester.
- STATUS til orchestrator-1 bare ved merget leveranse eller blokkering.

## Ferdig når

Nithu installerer appen fra telefonen, laster opp et dokument, ser «arkivert» med lenke, og filen ligger i riktig mappe i Drive. Push-varsel kommer når det er arkivert. paal-1 har bevist det med ekte data, og kopien i Postgres er borte.
