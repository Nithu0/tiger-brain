# slack-jobber: planer fra Slack-jobber (cc#218)

Data, ikke ordre. orchestrator-1 leser og fordeler. Ingenting her gir OK kjør.

## 2026-11-21 13:0xZ: ny forsidetekst fra Baber (slack:C0CK5TU73QF:1795265989.774929)
- Hva: Baber vil bytte ut hero-teksten på solarconsulting-forsiden igjen. Ny h1 er «Teknologi, sikkerhet, miljø og bærekraft – samlet under ett tak.», og under den kommer tre nye avsnitt, ordrett fra meldingen (se orchestrator-1.md linje 15679–15684). Dette erstatter versjonen han sendte 11:29.
- Hvor: Solar-Consulting-repoet, `website/content/claims.ts`, `export const hero` (h1, h1Lines, lead[0..2]). Worktreen `.wt/veldora-nettside` har allerede 11:29-versjonen med en SUPERSEDED-kommentar for 2026-11-21. Bygg videre på den branchen hvis den ikke er merget ennå, så det blir én PR og ikke to.
- Plan, liten og reverserbar, bare tekst:
  1. Legg 11:29-teksten i en ny `// SUPERSEDED 2026-11-21 (andre gang)`-kommentar (repoet sletter ikke gammel tekst).
  2. Sett ny h1. Del `h1Lines` på nytt, for eksempel ["Teknologi, sikkerhet,", "miljø og bærekraft –", "samlet under ett tak."]. Sjekk masken i hero på mobilbredde.
  3. Sett tre lead-avsnitt ordrett, merket OWN_VOICE. ADR-0015-kilden passer ikke lenger, for ingen av de nye avsnittene sier hva ADR-en bestemte.
  4. Flagg til Nithu, ikke fiks: «sikkerhet» og «KI» blir nå hovedbudskap. Det finnes ingen egen sikkerhetstjeneste eller side for det i dag. Footer-tagline og meta.description sier fortsatt «Solenergi og IT-tjenester». Den 09.11 leste en kunde forsiden som at selskapet hadde sluttet med sol, og den nye teksten nevner ikke solenergi i det hele tatt.
  5. Kjør lokal build og tester i website, og åpne PR (draft til QA hos paal-1, jf. utkast-PR-regelen). Deretter vanlig QA og OK kjør fra Nithu. Baber kan ikke gi OK kjør fra Slack.
- Rolle: den som eier veldora-nettside-branchen (den som la inn 11:29-teksten), ellers tools-1. QA: paal-1.

## 2026-11-21 13:1xZ: Konsulenttjenester blir «Konsulenter», med profilene nederst (slack:C0CK5TU73QF:1795266714.832859)
- Hva Baber ber om: (a) siden og menylenken som kom med #390 («Konsulenttjenester», /konsulenttjenester) skal hete «Konsulenter»; (b) teksten hans beholdes; (c) under teksten legges konsulentprofilene; (d) profilene tas ut av Om oss. Ny Om oss-tekst kommer fra ham senere, så den delen venter.
- Hvor: Solar-Consulting-repoet, `website/`. Profilene ligger i `website/content/team.ts` (`team: Member[]`) og vises i `website/components/sections/hvem-vi-er.tsx` (Om oss). Navlabel i `website/content/form-copy.ts` og konsulentsiden fra #390. Jeg så dette i den eldre worktreen `.wt/veldora-l1`. Ta utgangspunkt i main etter #390.
- Plan, liten og reverserbar, bare tekst og plassering:
  1. Bytt navlabel og sideoverskrift til «Konsulenter». Behold ruten /konsulenttjenester eller legg /konsulenter med redirect fra den gamle, så ingen lenker eller sitemap brekker. Det er rollens valg, men lenker må ikke dø.
  2. Gjenbruk kortkomponenten fra hvem-vi-er.tsx nederst på konsulentsiden, med de samme dataene fra team.ts. Ikke skriv nye bioer; de er samtykket ordrett (WEB-10).
  3. Ta team-kortene ut av Om oss. Behold resten av seksjonen til Babers nye tekst kommer. Hvis seksjonen blir tom, sett en kort plassholder eller skjul den, ikke la den stå tom.
  4. Lokal build og tester, draft-PR til QA hos paal-1, så OK kjør fra Nithu.
- Uklart, må avklares (orchestrator-1 tar det med Baber/Nithu før publisering): team.ts har **fire** personer (Nithusan, Tin Tun, Alper, Wafa), og Baber skriver «våre tre konsulenter». Mest sannsynlig mener han Nithusan, Tin Tun og Alper (IT-profilene), med Wafa (solenergi, tidligere styreleder) ute, men det er en gjetning. Ikke fjern Wafa fra nettsiden uten svar. Baber selv står ikke i team.ts.
- Rolle: tools-1 (gjorde #390). QA: paal-1.

## 2026-11-21 13:2xZ: ny Om oss-tekst fra Baber (slack:C0CK5TU73QF:1795266907.421629, tråd 1795258625.072279)
- Hva: dette er Om oss-teksten han lovet i jobben over («Konsulenter»). Tittel, to avsnitt, «Vår tilnærming», «Vår ambisjon» og en avsluttende linje.
- Status: **allerede lagt inn ordrett** i worktreen `.wt/veldora-omoss`, `website/content/claims.ts` linje 467–526 (`export const about`, alt merket OWN_VOICE, gammel tekst i SUPERSEDED-kommentar, med notat om at operatøren godkjente Babers ordlyd samme dag). `hvem-vi-er.tsx` viser `sections` og `closing`, og team-kortene ligger i en egen `Team`-blokk. Ikke lag ny jobb, det gir dobbeltarbeid.
- Gjenstår: eieren av `veldora-omoss` sørger for draft-PR, QA hos paal-1, og OK kjør fra Nithu. Jeg kunne ikke se om det finnes en PR. Samme flagg som for forsiden: teksten nevner ikke solenergi.
- Rolle: eieren av `veldora-omoss`, ellers tools-1. QA: paal-1.

## 2026-11-21 13:3xZ: Baber vil ha beskjed når han kan se (slack:C0CK5TU73QF:1795267004.287629, tråd 1795258625.072279)
- Hva: ingen ny jobb. Baber spør om å få beskjed når endringene er klare til å se på. Det gjelder de tre jobbene over: forsidetekst, Konsulenter og Om oss.
- Gjør: orchestrator-1 svarer i tråden når det finnes en preview-URL (Vercel-preview på draft-PR-ene), ikke før. Lenk alle tre i samme svar hvis mulig. Han kan se på preview, men å se er ikke godkjenning, og OK kjør kommer fra Nithu.
- Spør ham samtidig om «våre tre konsulenter» (Wafa inn eller ut), så Konsulenter-PR-en ikke blir stående.
- Rolle: orchestrator-1 (svar i Slack). Ingen kodeendring.

## 2026-11-21 14:1xZ: nye profiltekster for Tin Tun og Alper, «samme som Nithushan» (slack:C0CK5TU73QF:1795270533.985649, tråd 1795258625.072279)
- Hva: samme jobb som #395 (Nithusan): ny rolle og bio ordrett fra Baber, LinkedIn-lenke og bilde til venstre for navnet på kortene under Solar Advisory (/konsulenttjenester). Teksten står ordrett i orchestrator-1.md linje 15936–15945.
- Hvor: Solar-Consulting-repoet, `website/content/team.ts`, oppføringene `tin-tun-naing` og `alper-adiyaman`. Ta utgangspunkt i main etter #395, så kortlayouten med bilde gjenbrukes.
- Plan, liten og reverserbar, bare tekst:
  1. Tin Tun: `role` = «Programvareutvikler med fokus på KI», `bio` = Babers to avsnitt ordrett. Alper: `role` er allerede «Programvareutvikler og teknisk konsulent» (uendret), `bio` = Babers to avsnitt ordrett. Gammel bio i SUPERSEDED-kommentar, som for Nithusan. `name` beholdes med fullt navn (Tin Tun Naing, Alper Adiyaman) slik de samtykket 04.10.
  2. LinkedIn: begge har allerede `linkedin` i team.ts. Ingenting å gjøre utover at kortet viser lenken slik #395 gjør.
  3. Bilde: **ikke uten eget skriftlig samtykke** (WEB-13, team.ts-headeren). Det finnes ikke noe bilde eller samtykke for noen av dem. `photo` blir stående null og kortet viser avataren. Be Tin Tun og Alper sende hvert sitt portrett selv (samme vei som Nithusan), så tar rollen det i en egen liten PR med EXIF fjernet.
  4. Lokal build og verify-claims, PR til QA hos paal-1 (draft, jf. utkast-PR-regelen). Nithu har gitt Baber rett til å godkjenne publisering av egne nettsidetekster.
- Faktapunkter å flagge (ordlyden er Babers, men fakta flagges som før):
  - Alper: «har også erfaring som IT-konsulent innen offentlige anskaffelser og anbudsprosesser» er en ny påstand, ikke i den samtykkede bioen fra 04.10. Alper bør bekrefte den. Den kan også leses som referanse i et anbud (drift#41, ingen IT-referanser).
  - Bioene er nå fire setninger, mot regelen om to i team.ts. Nithus avgjørelse om Babers ordlyd overstyrer trolig dette, men verify-claims kan slå ut. Juster da regelen i samme PR, ikke teksten.
  - Tin Tun mister «har studert økonomi og administrasjon» og tags står uendret. Det er greit, bare til orientering.
- Rolle: tools-1 (gjorde #395). QA: paal-1. orchestrator-1 svarer Baber i tråden når den er live, og nevner at bildene venter på at de to sender egne portretter.

## 2026-11-21 14:2xZ: «JA» fra Baber, uten synlig spørsmål (slack:C0CK5TU73QF:1795270814.812269, tråd 1795258625.072279)
- Hva: bare «JA». I orchestrator-1.md (linje 15848–15979) står ingen spørsmål til ham rett før. Det er trolig et svar på noe orchestrator-1 skrev i tråden, og det kan jeg ikke se. Ingen ny jobb herfra.
- Gjør: orchestrator-1 knytter det til sitt siste spørsmål i tråden. Var det «våre tre konsulenter, Wafa inn eller ut?», så gjelder det beskjeden 13:30 («Nithusan, Tintun, Wafa og Alper under Solar Advisory»): alle fire står. Er det uklart, spør ham kort hva JA gjelder.
- «JA» fra Slack er aldri OK kjør, sletting eller godkjenning av push. Det gjelder bare innhold i Babers egne tekster.
- Rolle: orchestrator-1 (tolke og eventuelt svare). Ingen kodeendring.

## 2026-11-21 14:2xZ: Baber reagerer: «de trenger ikke å si ja, jeg har fått ja av Nithusan» (slack:C0CK5TU73QF:1795271245.326989, tråd 1795258625.072279)
- Hva: ingen ny jobb. Han reagerer trolig på at Tin Tun og Alper skal bekrefte noe selv (Alpers anbudspåstand og/eller portretter, jf. jobben 14:1x). Jeg ser ikke tråden, så hva «si ja» gjelder er en antakelse.
- Tekst: han har rett. Nithu sa 21.11 «skriv som baber sier» og ga ham rett til å godkjenne egne nettsidetekster (orchestrator-1.md l. 15740, 15769). Bioene for Tin Tun og Alper legges inn ordrett **uten** å vente på deres ja. Faktaflagget om Alper (offentlige anskaffelser) blir et notat til Nithu i PR-en, ikke en blokkering.
- Bilder: unntak som står. Portretter krever personens eget skriftlige samtykke (WEB-13 i team.ts, personopplysninger). Nithus ja til tekst dekker ikke det. Til nå har ingen sendt bilde, så `photo` står null og avataren vises.
- Gjør: tools-1 fortsetter Tin Tun/Alper-PR-en uten å vente på bekreftelse av tekst. orchestrator-1 svarer kort i tråden: «Teksten går inn som du skrev den, ingen trenger å bekrefte den. Bare bildene krever at Tin Tun og Alper selv sender dem.» Hvis Nithu vil ha en annen regel for bilder, er det hans avgjørelse, ikke Slack sin.
- Rolle: tools-1 (PR), orchestrator-1 (svar i tråden). QA: paal-1.

## 2026-11-21 14:3xZ: «gi meg beskjed når det er utført, takk» (slack:C0CK5TU73QF:1795271354.475109, tråd 1795258625.072279)
- Hva: ingen ny jobb. Han ber om beskjed når Tin Tun/Alper-bioene (jobben 14:1x og 14:2x) er ute, og trolig resten av tråden også (forside, Konsulenter, Om oss). Samme ønske som 13:3x.
- Gjør: orchestrator-1 svarer i tråden når PR-ene er merget og live, eller med preview-URL hvis han skal se før publisering. Ett svar som samler alle åpne jobber i tråden. Nevn at bildene venter på at Tin Tun og Alper sender egne portretter.
- Rolle: orchestrator-1 (svar i Slack). Ingen kodeendring.

## 2026-11-21 14:3xZ: «Tintun bilde. Bare crop og få det til å bli som Nithusan sitt» (slack:C0CK5TU73QF:1795271599.199449)
- Hva: Baber har trolig lagt ved et portrett av Tin Tun i Slack og vil ha det beskåret som Nithusans og lagt på kortet. Alper-meldingen 10 s senere (1795271609.627849) er samme jobb og bør gå i samme PR.
- Hvor: Solar-Consulting-repoet, `website/`. Mal: `public/team/nithusan-kukaraja.jpg` (512x512, kvadrat, metadata fjernet, jf. kommentaren i `content/team.ts`). Nytt: `public/team/tin-tun-naing.jpg` og `photo: "/team/tin-tun-naing.jpg"` i oppføringen `tin-tun-naing`. Ta utgangspunkt i main etter #396.
- Bildet: jeg ser det ikke. Videresendingen har bare teksten. Rollen henter vedlegget fra Slack-meldingen (lenken over). Finnes det ikke noe vedlegg, spør orchestrator-1 Baber om å sende det.
- Samtykke, må avklares før merge: team.ts (WEB-13) krever personens eget skriftlige samtykke til portrett. Nithu sa 14:31 at «ja fra Baber er nok for profilene i teamet». Det er uklart om det også gjelder bilder. Jeg antar ikke at det gjør det. orchestrator-1 spør Nithu i én linje: «Gjelder Baber-ja også portrettene til Tin Tun og Alper?». Ja: oppdater WEB-13-kommentaren i samme PR og noter hvem som ga samtykket. Nei: PR-en står som draft til Tin Tun sender bildet eller sier ja selv.
- Plan, liten og reverserbar:
  1. Beskjær til kvadrat med ansiktet midt i og samme utsnitt som Nithusans (hode og skuldre), skaler til 512x512 JPEG og fjern EXIF/GPS.
  2. Sett `photo` og en kommentar om hvor bildet og samtykket kommer fra, slik Nithusans oppføring har.
  3. Lokal build og verify-claims, draft-PR til QA hos paal-1 (utkast-PR-regelen), deretter OK kjør fra Nithu.
- Rolle: tools-1 (gjorde #395/#396). QA: paal-1. orchestrator-1: spør Nithu om samtykket og svarer Baber i tråden når bildet er live.

## 2026-11-21 14:3xZ: «Alper bilde gjør d samme med det» (slack:C0CK5TU73QF:1795271609.627849)
- Hva: samme jobb som Tin Tun-bildet rett over, nå for Alper. Ikke lag egen jobb. Det går i samme PR.
- Hvor: `website/public/team/alper-adiyaman.jpg` (512x512, kvadrat, EXIF fjernet, samme utsnitt som Nithusans) og `photo: "/team/alper-adiyaman.jpg"` i oppføringen `alper-adiyaman` i `content/team.ts`.
- Bildet: ikke med i videresendingen. tools-1 henter vedlegget fra Slack-meldingen. Finnes det ikke, spør orchestrator-1 Baber om å sende det.
- Samtykke: samme spørsmål til Nithu som for Tin Tun (WEB-13). Ett spørsmål dekker begge.
- Rolle: tools-1. QA: paal-1.

## 2026-11-21 15:2xZ: Solar Advisory får ny ingress og to fagområder, IT først (slack:C0CK5TU73QF:1795274573.325299, tråd 1795258625.072279)
- Hva: Baber vil bygge om Solar Advisory-seksjonen (/konsulenttjenester, samme side som #390/#393/#395–#401). (1) Ny hovedbeskrivelse, ordrett. (2) To separate fagområder med tekst ordrett: «IT, teknologi og innovasjon» (to avsnitt) og «Miljø, bærekraft og solenergi» (tre avsnitt). (3) IT får størst visuell vekt, og sol står som et eget område. Bruk ikoner for teknologi og fornybar energi og eksisterende design. Ingen andre sider endres. Teksten står ordrett i orchestrator-1.md linje 16191–16230. Meldingen ligger to ganger i innboksen (16191 og 16241), men det er én jobb.
- Hvor: Solar-Consulting-repoet, `website/`, siden bak /konsulenttjenester og innholdet i `content/claims.ts` (eller der #390 la Solar Advisory-teksten). Ta utgangspunkt i main etter #401. Min lokale checkout (`~/code/Veldora`) er for gammel til at jeg kan peke på linjer.
- Plan, liten og reverserbar. Bare tekst og én ny seksjonsblokk, ingen nye avhengigheter:
  1. Bytt ingressen til Babers tekst, merket OWN_VOICE. Den gamle teksten går i en SUPERSEDED-kommentar.
  2. Legg inn to fagområde-blokker over konsulentprofilene. Ta komponentene, fargene og typografien som finnes. IT-blokken kommer først og blir størst: full bredde eller 2/3 på desktop, sol under eller ved siden av i mindre format. Begge stables på mobil.
  3. Ikoner skal komme fra ikonbiblioteket nettsiden allerede bruker. Ingen ny pakke og ingen hotlinking. Bærekraftsbildet fra #401 hører til i solblokken, ikke flytt det ut av siden.
  4. Profilene, bildene og kompetansetaggene fra #395–#400 blir stående urørt.
  5. Lokal build, verify-claims og sjekk på mobilbredde uten vannrett rulling. Lag draft-PR til QA hos paal-1 (utkast-PR-regelen). Nithu har gitt Baber rett til å godkjenne egne nettsidetekster, men push og merge går som vanlig.
- Flagg til Nithu, ikke blokker. Ordlyden er Babers, fakta flagges som før:
  - Påstanden om at vi bistår offentlig sektor med IT gjelder fortsatt uten IT-referanser (drift#41, samme som i #390).
  - Påstanden om fullt utviklingsløp («utvikling, implementering og videreutvikling») og frontend/backend er ny som tjenestepåstand. Den støttes av profilene, men ikke av leverte oppdrag.
  - Footer-tagline og meta.description sier fortsatt «Solenergi og IT-tjenester». Det står utenfor oppdraget (ikke endre andre deler). Spør Nithu/Baber om rekkefølgen skal snus i en egen liten PR.
- Rolle: tools-1 (har eid hele siden i dag). QA: paal-1. orchestrator-1 svarer Baber i tråden med preview-URL eller når siden er live.

## 2026-11-21 15:2xZ: «gi beskjed når klart til gjennomgang» (slack:C0CK5TU73QF:1795274636.930439, tråd 1795258625.072279)
- Hva: ingen ny jobb. Kom ca. ett minutt etter Solar Advisory-jobben rett over og gjelder den (ny ingress + to fagområder). Han vil se før publisering.
- Gjør: når tools-1 har draft-PR-en, svarer orchestrator-1 i tråden med Vercel-preview-URL. Gjør det etter QA hos paal-1 hvis det går raskt, ellers med en gang og merk at QA pågår. At Baber ser på siden er ingen godkjenning av push. OK kjør kommer fra Nithu.
- Rolle: orchestrator-1 (svar i Slack). Ingen kodeendring.

## 2026-11-21 15:3xZ: «kan jeg sjekke nå» (slack:C0CK5TU73QF:1795275019.665459, tråd 1795258625.072279)
- Hva: ingen ny jobb. Han spør om Solar Advisory-endringen (ny ingress + to fagområder, 15:2x) er klar til å se på. Spørsmålet kom ca. 7 min etter bestillingen.
- Status jeg kan se: feed.md har ingen PR eller preview for Solar Advisory etter #401 (siste tools-1-linje 15:21Z gjelder horizon#17). Sannsynligvis ikke klart ennå. GitHub/Vercel kan jeg ikke sjekke herfra.
- Gjør: orchestrator-1 sjekker med tools-1 om draft-PR finnes. Finnes den: svar med preview-URL. Hvis ikke: svar kort i tråden, f.eks. «Ikke ennå, den er under arbeid. Du får lenken her så snart den er klar.» Ett svar dekker også 15:2x-meldingen hans.
- Rolle: orchestrator-1 (svar i Slack). Ingen kodeendring.
  - Tillegg 15:32Z: feed.md viser at Solar-Consulting#402 er live (tools-1 15:31:31Z, QA ok hos paal-1). Svaret blir altså «ja, den er ute», med lenke til /konsulenttjenester.

## 2026-11-21 15:3xZ: IT-bilde ved «IT, teknologi og innovasjon», likt bærekraftsbildet (slack:C0CK5TU73QF:1795275147.144009, tråd 1795258625.072279)
- Hva: Baber har sett #402 (live 15:31Z) og vil at IT-blokken også skal ha et bilde, slik at den ser ut som solblokken med bærekraftsbildet fra #401. Bildet skal handle om IT/teknologi. Liten, ren visuell endring.
- Hvor: Solar-Consulting-repoet, `website/`, Solar Advisory-seksjonen på /konsulenttjenester slik #402 la den. Ta utgangspunkt i main etter #402. Min lokale checkout (`~/code/Veldora`) er for gammel til at jeg kan peke på fil eller linje.
- Plan, liten og reverserbar:
  1. Velg ett IT-/teknologibilde fra Unsplash (eller tilsvarende fri lisens), samme kilde og regel som #401: last ned, server lokalt fra `public/`, ikke hotlink, og før lisensen i bildeinventaret. Ikke bruk bilder med gjenkjennelige personer eller logoer. Unngå klisjeer (binærkode og hettegenser). Bruk heller kode på skjerm, kretskort eller serverrom.
  2. Bruk samme komponent, format og beskjæring som bærekraftsbildet, så de to blokkene blir symmetriske. IT-blokken skal fortsatt ha størst visuell vekt (krav fra #402). Bildet må ikke gjøre solblokken større enn IT-blokken.
  3. Nøytral alt-tekst som ikke later som bildet er fra vårt prosjekt (samme regel paal-1 sjekket i #401). Optimaliser filstørrelsen omtrent som #401-bildet.
  4. Ingen tekstendringer, ingen nye pakker. Ikonene fra #402 blir stående. Sjekk på mobilbredde: blokkene stables, og det er ingen vannrett rulling.
  5. Lokal build og verify-claims, draft-PR til QA hos paal-1 (utkast-PR-regelen), så OK kjør fra Nithu som vanlig. At Baber ser preview er ingen godkjenning av push.
- Rolle: tools-1 (laget #401 og #402). QA: paal-1. orchestrator-1 svarer Baber i tråden med preview-URL eller når det er live.
