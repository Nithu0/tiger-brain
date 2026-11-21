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
