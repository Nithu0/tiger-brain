# inbox: renseri-orchestrator

---
## 2026-09-21T18:10Z — fra admin-1: job-20260921-175353-admin1-28446 LEVERT (klar for fletting)

**Fil:** `~/Obsidian/Brain/00-claude-inbox/renseri/2026-09-21_oppstart-og-kontoer.md`
**Søsterleveranser fra samme dispatch:** `2026-09-21_ads-plan.md` (data-1), `2026-09-21_google-workspace-plan.md` (infra-1). Alle tre ligger i samme mappe.

Headless-executoren feilet med `claude: command not found`. Jobben er derfor kjørt manuelt i admin-1-panen, med samme prompt og scope. Rapporten er report-only: ingen kjøp, DNS-endringer, kontoopprettelser eller push, og `~/code/Renseri` er ikke rørt. Påstandene er merket FACT (med kilde og dato), ASSUMPTION eller UNKNOWN.

**Innhold:**
- **Del 1:** Oppstartssjekkliste i 8 steg: AS/ENK, Altinn, MVA, forsikring, lås/FG, 1953-loven om uavhentede varer, GDPR og drift.
- **Del 2:** Konto-oppsett for Google Business Profile uten adresse (SAB), Google Ads, Meta, samtykke og DNS, og hva som må vente til selskapet har org.nr.
- **Del 3:** 15 navn, sjekket mot Norid og Brreg. Topp 2 er i tillegg søkt i varemerkeregisteret hos Patentstyret.

**Nøkkelfunn for fletting:**
1. **AS anbefales.** Tøy i varetekt, døråpning døgnet rundt og systemnøkler gir høy ansvarsrisiko. (ASSUMPTION)
2. **Alarmrespons** vil sannsynligvis kreve tillatelse etter vaktvirksomhetsloven § 2. Hold «utrykning» til lås og døråpning. **Dette påvirker tjenestetekstene på nettsiden.**
3. **Ingen offentlig låsesmedlisens.** FG-godkjenning via Foreningen Norske Låsesmeder er frivillig, men i praksis nødvendig mot B2B. Systemnøkler (ASSA/TrioVing) kan bare kopieres av autoriserte forhandlere. **Nettsiden bør ikke love kopiering av systemnøkler.**
4. **Vanlig ansvarsforsikring dekker ikke kundegjenstander i varetekt.** Det trengs egen dekning.
5. **Uavhentede varer:** 1953-loven tillater salg når det har gått mer enn 3 måneder siden arbeidet ble gjort og kunden er varslet rekommandert. Gjelder både B2B og forbruker. Bør inn i kundevilkårene.
6. **Google Ads:** Låsesmedannonser er stengt i Sverige, Tyskland, Nederland, Spania og Belgia. Norge er ikke nevnt ennå, så dette er en policyrisiko for ads-planen. **Kryss-sjekk med data-1.**
7. **Consent Mode v2 og ekomloven § 3-15:** GA4, Ads-taggen og Pixel skal ikke sette cookies før samtykke er gitt. «Avvis alle» må ligge på første nivå. **Dette påvirker nettsidebygget.**
8. **Én Google Business Profile** med primærkategori pluss sekundære kategorier, ikke én profil per tjeneste.
9. **Navn:**
   - **Utkall** har ledig .no-domene, 0 identiske i Brreg og 0 i varemerkeregisteret. Svakheten er at et vanlig ord kan gi svakt særpreg som varemerke.
   - **Døgnfiks** (`dognfiks.no`) er ledig og har 0 identiske. Nærliggende registrerte merker er Fru Fiks (klasse 37/44/45), Miljø DØGNVAKTEN (klasse 37) og DØGN (klasse 45).
   - Anbefalingen er Utkall først og Døgnfiks som nummer to.
   - Serviro og Nordfiks bør droppes, fordi Brreg har SERVIRO AS og det veldig like NORFIKS AS.

**Operatørbeslutninger** (ikke tatt):
- Navnevalg, og om domene og varemerke skal sikres (kjøp).
- Om alarmrespons skal være med i tilbudet.
- Tilbud fra forsikringsmegler.
- Hvordan FG-godkjenning og forhandleravtale for systemnøkler skal håndteres.

**Åpne UNKNOWN:**
- Om kravet på 250 000 kr for forhåndsregistrering i MVA-registeret fortsatt gjelder.
- Om samlet ENK-gebyr er 3 883 kr eller 3 185 + 2 181 kr.
- Hvilke dokumenter Meta godtar ved verifisering i Norge.
- Nøyaktige kategorinavn i Google Business Profile.
- Om .no-domene krever org.nr.
- IDN-varianter med ø og æ, og om internasjonale varemerkeregistreringer (WIPO) er med i søket.

— admin-1
