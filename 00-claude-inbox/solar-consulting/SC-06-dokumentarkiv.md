# SC-06 — dokumentarkiv, Zotero og «dokumenter mangler»

learning-1, 2026-10-16. Branch `sc-06-dokumenter`, commit `cf33127` (lokal, ikke pushet). Worktree `~/code/Veldora-sc06`.

## Levert

- **KOFA-PDF-er til `documents`** med sha256, kilde-URL, hentedato og hentet-av. Samme høflige klient som ingest-kofa (robots.txt, minst 3 s mellom kall), maks 40 per kjøring, dedup på URL og hash. `legal-documents` er ikke endret (SC-05 eier den). Tekstuttrekk med sidetall (`\f`), og OCR (pdftoppm + tesseract nor+eng) når PDF-en mangler tekstlag.
- **Zotero-synk** (web-API v3): bare `purpose = literature` går dit, til én samling, med metadata og PDF. Grensen håndheves tre steder: valideringen, spørringen og en sjekk per rad. I tillegg er `purpose` låst etter opplasting. Gjennomgangen fant at et medlem ellers kunne merke om et bevisdokument til litteratur.
- **Kø «dokumenter mangler»**: `GET /api/anbud/dokumentarkiv/mangler` og dashbordsiden `/dokumenter-mangler`.
- **Portalvilkår** i `data/sources/{mercell,tendsign,hyyr}.json`.
- **Dekning målt før**: `crm/eval/DOKUMENTDEKNING.md`.

Verifisert lokalt: crm `tsc` rent, 2683/2683 tester, migreringssnapshot i takt. Dashboard: tsc og lint rene, 621/621 tester. Røyktesten `scripts/smoke-dokumentarkiv.ts` lastet ned en ekte KOFA-PDF (202 kB, 11 sider), gjorde 0 nettkall på andre kjøring, leste en skannet PDF med OCR, viste køen og sendte bare litteraturraden til (falsk) Zotero. Planleggeren startet i `next dev` med flagget på. En uavhengig kodegjennomgang fant 2 blokkere og 7 andre funn, og alle er rettet.

## Dekning før (prod, read-only)

| | |
| --- | --- |
| Dokumenter i arkivet | 0 |
| KOFA-PDF-lenker / nedlastet | 348 / 0 |
| Passert triagen uten dokumenter | 47 |
| … på Mercell / TendSign / hyyr | 12 / 6 / 8 = 26 |

«Etter»-tallet kan først måles når koden er migrert og deployet, og nedlastingen har gått i prod. Det står som TODO i eval-filen.

## Portalvilkår (kort)

- **Mercell:** krever konto og «Show interest» per konkurranse. `my.mercell.com/robots.txt` er `Disallow: /`. Ikke automatisk.
- **TendSign:** krever leverandørinnlogging. robots.txt er `Disallow: /`. Ikke automatisk.
- **hyyr:** konkurransesiden lenker åpent til ZIP-nedlasting, og robots.txt finnes ikke (404). Leverandørvilkårene ligger bak innlogging, så innholdet er UNKNOWN. Teknisk åpent, juridisk uavklart.

Alle juridiske felt (lagre/analysere/vise/redistribuere) er `UNKNOWN`. Hver fil sier i `next_action` hvem som må spørres.

## Kø for manuell henting (26, sortert på frist)

Ingen Claude in Chrome i denne sesjonen, så ingenting er hentet med nettleser. Ingen innlogging, ingen vilkår godtatt, ingen interesse registrert.

| Portal | Mulighet | Beslutning | Frist | Tittel | Lenke |
| --- | --- | --- | --- | --- | --- |
| tendsign | #152 | INVESTIGATE | 2026-10-16 | Digital renholdsplanlegger | https://tendsign.com/doc.aspx?MeFormsNoticeId=100184 |
| mercell | #275 | BID | 2026-10-19 | 2026/4163 - Anskaffelse av overvåkningsverktøy for  databaseadministra | https://permalink.mercell.com/290919630.aspx |
| hyyr | #116 | STRONG_BID | 2026-10-20 | Ny skybasert EPJ-løsning for Innherred Interkommunale Legevakt IKS | https://hyyr.no/procurement/cmttxznjq000b04jln4brakbl |
| tendsign | #659 | BID | 2026-10-20 | ANSK-26-0109 Bistand til prosjekt UiB ATLAS | https://tendsign.com/doc.aspx?MeFormsNoticeId=101123 |
| hyyr | #252 | STRONG_BID | 2026-10-21 | Medarbeiderundersøkelse og pulsmålinger | https://hyyr.no/procurement/cmue20lyr000i04l2izbv330e |
| tendsign | #460 | STRONG_BID | 2026-10-26 | Kommunalt innfordringssystem | https://tendsign.com/doc.aspx?MeFormsNoticeId=100830 |
| mercell | #1016 | INVESTIGATE | 2026-10-29 | Kjøp av tjeneste - SMS Gateway | https://permalink.mercell.com/291972533.aspx |
| mercell | #82 | INVESTIGATE | 2026-10-30 | Procurement of a SAP Solution Architect for DRIV 2026036846 | https://permalink.mercell.com/291473485.aspx |
| mercell | #19 | BID | 2026-11-03 | Procurement of a digital caring tool for the school environment. | https://permalink.mercell.com/291501970.aspx |
| mercell | #825 | STRONG_BID | 2026-11-06 | Stoffkartotek til Finnmark fylkeskommune | https://permalink.mercell.com/292265784.aspx |
| tendsign | #837 | STRONG_BID | 2026-11-09 | Procurement of consultancy services ICT - backend/full stack | https://tendsign.com/doc.aspx?MeFormsNoticeId=101412 |
| mercell | #710 | INVESTIGATE | 2026-11-09 | EPJ Nursing and care for Vardø municipality | https://permalink.mercell.com/291701941.aspx |
| hyyr | #959 | BID | 2026-11-13 | Fagsystem for PPT- og logopedtjenesten i Nord-Østerdal | https://hyyr.no/procurement/cmv0xvztd000006l2x4hvtow2 |
| mercell | #821 | STRONG_BID | 2026-11-13 | Møtegjennomføringsverktøy | https://permalink.mercell.com/292346311.aspx |
| hyyr | #942 | BID | 2026-11-16 | Advertising services | https://hyyr.no/procurement/cmuwg7kiu004h04jqzxs4o3qc |
| mercell | #452 | STRONG_BID | ukjent | 2026 -  System for administrasjon og oppfølgning av kommunale gebyrer  | https://permalink.mercell.com/291836532.aspx |
| tendsign | #354 | STRONG_BID | ukjent | Kompetansekartlegging for Nettalliansen | https://tendsign.com/doc.aspx?MeFormsNoticeId=99943 |
| mercell | #124 | STRONG_BID | ukjent | Markedsdialog - Innkjøpsløsning | https://permalink.mercell.com/290982967.aspx |
| hyyr | #967 | INVESTIGATE | ukjent | Markedsdialog: automatisert håndtering av post, dokumenter og arkiveri | https://hyyr.no/marketdialog/cmue2aztn000804i0a8x9kwbb |
| tendsign | #375 | INVESTIGATE | ukjent | Avinor AS - T-193361 - RFI - Instrument Flight Procedure Design System | https://tendsign.com/doc.aspx?MeFormsNoticeId=99998 |
| hyyr | #935 | STRONG_BID | ukjent | Digital substance register | https://hyyr.no/procurement/cmub3voaz000d04jm5ob5gr47 |
| hyyr | #634 | STRONG_BID | ukjent | Customer dialogue and case handling contact centre system | https://hyyr.no/procurement/cmq0utavn000004jvcehujtjk |
| mercell | #103 | STRONG_BID | ukjent | Markedsdialog - nytt inkassosystem i Bodø kommune | https://permalink.mercell.com/291044708.aspx |
| mercell | #113 | STRONG_BID | ukjent | Markedsdialog – mulig anskaffelse av KGV- og KAV-løsning | https://permalink.mercell.com/291623769.aspx |
| hyyr | #805 | STRONG_BID | ukjent | Markedsdialog: programvare for timeregistrering og internfakturering | https://hyyr.no/marketdialog/cmup9i54h000004i7erz6g3xh |
| mercell | #359 | INVESTIGATE | ukjent | Markedsdialog - Fremtidens sourcing-, plattform- og skytjenester for D | https://permalink.mercell.com/291033868.aspx |

NB: #152 «Digital renholdsplanlegger» (TendSign) har frist **i dag 16.10**. 7 av hyyr-radene er vanlige konkurranser (`/procurement/`). Den åttende, #967, er en markedsdialog (`/marketdialog/`). Mange av radene uten frist er markedsdialoger og har kanskje ikke konkurransegrunnlag ennå.

## Gjenstår (operatør)

1. **Zotero-nøkkel** på Railway `crm`: `ZOTERO_API_KEY` (skrivetilgang), `ZOTERO_LIBRARY_ID` og `ZOTERO_LIBRARY_TYPE` (`user` eller `group`). Uten dem hoppes synken over med en melding.
2. **Push/PR** etter «OK kjør». Migreringen står sist i køen (SC-03 → SC-05 → SC-07 → SC-01 → SC-02 → SC-06).
3. **Etter deploy:** `DOKUMENTARKIV_ENABLED=true` på `crm`. Da går KOFA-nedlastingen 05:20 hver natt og Zotero-synken hver 30. min. Imaget får poppler + tesseract (litt større image).
4. **hyyr:** skal de 8 hentes automatisk når vilkårene er uavklart? Det er en beslutning for operatøren. Adapteret er trading-1s (`trading-1/dokument-pipe`).
5. **Etter-måling:** `./scripts/baseline/run-triage-baseline.sh --sql dokumentdekning.sql` når nedlastingen har gått.

## Kjente begrensninger

- Feilede KOFA-URL-er lagres ikke. Startpunktet roteres per døgn, så alle lenker blir prøvd i løpet av ⌈n/40⌉ netter, også de som feiler.
- OCR kjører i opplastingskallet, avgrenset til 90 s og 40 sider.
- Litteratur lastes opp av medlemmer uten egen godkjenning før Zotero. Si fra hvis dere vil ha et admin-flagg.
