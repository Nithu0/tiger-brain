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
