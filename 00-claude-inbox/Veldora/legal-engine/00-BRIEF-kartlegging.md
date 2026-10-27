# Felles brief — kartlegging av Veldora/Solar-Consulting før juridisk kunnskapsmotor

Oppdrag fra operatøren: **først** full kartlegging av hvordan dagens plattform er koblet sammen.
Ingen design, ingen implementasjon, ingen eksterne API-forslag i denne runden.

## Regler (bindende for alle kartleggingsagenter)

1. **Repo:** `/home/nithu/code/Veldora-frist`, gren `admin-1/legal-engine-map` = `origin/main` (`fae0ddd`).
   **LES ONLY.** Ingen filendringer, ingen git-skriving, ingen `npm install`, ingen nettverkskall,
   ingen DB-tilkobling. Andre paner jobber i samme repo-familie — ikke rør noe.
2. **Hemmeligheter:** aldri skriv ut verdier fra `.env*`. Variabelnavn er greit.
3. **Bevis per påstand:** `fil:linje` eller kommando + utdrag av output. **Ingen gjetting.**
   Finnes noe ikke, skriv `FINNES IKKE (målt: <kommando>)`. Et søk som ikke traff er ikke et fravær —
   prøv minst to formuleringer før du skriver at noe mangler.
4. **Skill mellom:** `KODE` (finnes i src), `DOKUMENTERT` (står i ARCHITECTURE.md/docs men ikke
   verifisert i kode), `I DRIFT` (det finnes bevis for at den kjører), og `TOMT` (kode finnes, men
   ingen konsumenter eller 0 rader).
5. **Format:** norsk, tabeller framfor prosa, maks ~150 linjer. Skriv fila selv til stien du får.
6. **Returner:** maks 10 linjer sammendrag + de tre viktigste funnene, ikke hele fila.

## Kontekst du trenger

- `projects/anbud/ARCHITECTURE.md` er 4548 linjer og er arkitekturkontrakten. Seksjonene som angår
  juss: 2341 legal corpus · 2387 KOFA · 2496 legal assistant · 2613 legal-questions · 2640 feilsjekk ·
  2933 klage og innsyn. §5 er datamodellen (fra linje 291), §6 agenter (3287), §8 dashboard (3468).
- Stack: Payload CMS + Postgres (CRM, `projects/anbud/crm`), Next.js-dashboard
  (`projects/anbud/dashboard`), begge på Vercel. Dashboardet leser CRM-et over REST.
- Kjent fra tidligere målinger: `documents` har 0 rader i prod, 0 av 1184 `documentsUrl` peker på en
  fil, `payload_jobs` sletter vellykkede jobber (`deleteJobOnComplete: true`), så bare feil overlever.
