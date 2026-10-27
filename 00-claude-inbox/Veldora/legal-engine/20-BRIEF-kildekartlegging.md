# Felles brief — fase 2: kildekartlegging for den juridiske kunnskapsmotoren

Operatørens beslutning 2026-10-15: **internt verktøy til å starte med.** `ADR-0010` står. Det
avgjør hva som er godt nok rettighetsmessig (se §2) og hva som kan vente.

Grunnlag du må kjenne: `10-SYNTESE-koblingskart.md` i samme mappe (hva som alt er bygget) og
`09-institusjonell-kunnskap.md` (hva som alt er verifisert av kilder). **Ikke gjør om research som
alt står der med dato.**

## 1. Regler (bindende)

1. **Verifiser, ikke anta.** Hver påstand om et API krever: URL, HTTP-status fra et faktisk kall,
   og et ordrett sitat fra dokumentasjon eller vilkår — med hentedato. Kan du ikke verifisere, skriv
   `UNKNOWN` og oppgi nøyaktig hva du forsøkte (URL/kommando). **«Det finnes sannsynligvis et API»
   er ikke et funn.** Repoet har en dokumentert hendelse der et hentelag leverte en velformet og
   fullstendig oppdiktet gjengivelse av FOA §§ 16-1 til 16-10 (`procurement/qualification/financial-capacity.md:921`)
   — det er feilklassen du skal unngå.
2. **Les-only mot verden.** Ingen innlogging, ingen registrering, ingen kjøp, ingen API-nøkler, ingen
   kontaktskjema. Ingen omgåelse av betalingsmur eller robots.txt — sjekk robots der du henter.
3. **FOA Pro, Anbudsradar og andre kommersielle produkter:** kun offentlige pris- og funksjonssider,
   og kun for å kjenne målestokken. **Innhold skrapes aldri og kopieres aldri** (operatørbeslutning
   2026-10-05, `ARCHITECTURE.md:1079`).
4. **Ingen repo-endringer.** Du skriver kun din egen fil under
   `~/Obsidian/Brain/00-claude-inbox/Veldora/legal-engine/sources/`.
5. **Norsk, maks ~120 linjer, tabeller framfor prosa.** Returner maks 10 linjer + tre viktigste funn.

## 2. Rettighetsrammen, nå som B1 er besvart

Vi trenger, for **intern** bruk: `storage_rights` (kan vi lagre teksten?), `analysis_rights` (kan vi
analysere den?), `ai_processing_rights` (kan den sendes til en modell?). `redistribution_rights`
**registreres** men blokkerer ikke nå — det blir avgjørende først hvis motoren skal selges.

Presisjonen som må holdes: **`lovdata.no` (bruksvilkår: ingen distribusjon uten skriftlig tillatelse)
og `api.lovdata.no/v1/publicData` (NLOD 2.0) er to forskjellige rettsforhold hos samme leverandør.**
Ikke bland dem. Samme øvelse for hver kilde du ser på.

## 3. Formatet du skal fylle (eksisterer alt i repoet)

`data/sources/*.json` har 15 felt per kilde, og fase 2 skal fylle **dette** skjemaet, ikke et nytt:

```
id · name · provider · url · feed_url · access_method · authentication · cost · latency ·
completeness · historical_access · technically_fetchable (RED/YELLOW/GREEN) · storage_rights ·
analysis_rights · redistribution_rights · ai_processing_rights · gdpr_implications ·
licence_status · owner · next_action
```

Lever verdiene som en tabell i fila di, pluss en kort «slik ville vi koblet den»-note som peker på
de eksisterende sømmene: verts-allowlisten i `crm/src/lib/http.ts` (9 verter i dag — en ny kilde
krever en linje der), parseren `crm/src/lib/legal/parse.ts`, datasettleseren `tar.ts`, synkplanen
`sync.ts`, og ID-skjemaet `lov/<dato>-<nr>/§X/ledd-n`.

## 4. Det som alt er verifisert (ikke gjør om)

- Lovdatas åpne datasett: `GET https://api.lovdata.no/v1/publicData/list` gir fire datasett, **ingen
  nøkkel**, **NLOD 2.0**, oppdateres nattlig. `gjeldende-lover.tar.bz2` 5,8 MB,
  `gjeldende-sentrale-forskrifter.tar.bz2` 21 MB (223 MB utpakket) med FOA som `sf/sf-20160812-0974.xml`.
  Verifisert live 2026-10-05 (`prd/juridisk-assistent.md:64-66`). **Bekreft at det fortsatt stemmer,
  men bruk tiden på det som IKKE er dekket: versjonshistorikk, forarbeider, dommer, og hva
  datasettene ikke inneholder.**
- Fem kilder er alt i korpuset (`crm/src/config/legal.ts`): anskaffelsesloven, FOA,
  forsyningsforskriften, offentleglova, klagenemndforskriften.
- Doffin og TED er i drift som kunngjøringskilder. Dokumentene bak `documentsUrl` er **ikke** løst.
