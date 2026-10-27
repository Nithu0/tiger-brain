# Teknologikart: hvilke teknologier, plattformer og leverandører etterspør offentlig sektor?

trading-1, 2026-10-19. Prod er bare lest (skriptfil, testet mot engangs-PG18 først), målt 2026-10-18T22:19Z, kode `168cf1e`.
Rådata: `scratchpad/teknologikart-prod.txt` (blir sjekket inn som `crm/eval/` hvis du vil). Ingen kode, ingen push.
**DOKUMENTERT** = navnet står i kunngjøringen. **ETTERSPURT** = det kjøpes eller kreves. **ANTAKELSE** = statistikk, overslag eller AI.

## Hva vi kan i dag (FACT, tall fra prod)

- **Grunnlag:** 110 059 kunngjøringer (Doffin 69 320, TED 40 739), 2021–2024 + 2026. Teksten i `tenders` er kort: **snitt 496 tegn (Doffin) og 232 (TED)**.
  Rå-arkivet har hele eForm-treet: 68 149 Doffin-kunngjøringer, snitt 22,7 kB, og 39 996 TED-kunngjøringer.
- **Ordliste uten LLM** (76 produkter og leverandører, regex, akronymer med riktige store bokstaver): **1 274 kunngjøringer med treff (1,2 %) hos 256 av 1 500 kjøpere.**
  Fordeling: COMPETITION 573, RESULT 560, PLANNING 139. Flest treff: Visma 135, Azure 102, Microsoft 365 88, VMware 74, SAP 73, Unit4/Agresso 68,
  Chromebook 65, Oracle 64, .NET 63, Cisco 56, Citrix 52, iPad 50, ArcGIS 49, SharePoint 49, Teams 41, DIPS 35.
- **Presisjon** (60 tilfeldige treff, lest av trading-1, ikke av et menneske): riktig produktnavn **59/60 (98 %)**, eneste bom «EMC» = elektromagnetisk
  kompatibilitet. Ekte bruk eller etterspørsel: **56/60 (93 %)**. Bommene er Teams og Zoom som møteplass, og «Oracle … omfattes ikke».
- **Rå-arkivet øker dekningen:** av 2 000 Doffin-kunngjøringer uten treff i `tenders`-teksten fikk **117 (5,9 %) treff i eForm-teksten**. Fremskrevet (ANTAKELSE):
  ca. 6 000 flere kunngjøringer, altså **~5x dagens dekning**, gratis og uten LLM.
- **DOKUMENTERT bruk er gull:** mange treff beskriver *dagens* installasjon, ikke bare kjøpet. Eksempler: «erstatte dagens databaseplattform for Oracle» (Statens vegvesen),
  «Hammerfest bruker i dag ePhorte», «Visma Profil fases ut av leverandøren» (Ringsaker), «VMware cluster … Windows Server OS».
- **Teknologibilde per virksomhet** finnes allerede som rådata. Eksempel Sykehusinnkjøp HF: DIPS 3 → 5 → 10 → 10 (2021–24), Oracle 3 → 2 → 0 → 7, Cisco 0 → 1 → 0 → 8, Citrix 3 → 1 → 1 → 0.

## Hull (som avgjør om dette blir et produkt)

1. **Teknologilistene står i konkurransegrunnlaget, ikke i kunngjøringen.** Eksempelet 2021-397146 (M365, VMware, Citrix, MSSQL, NetIQ, Veeam, Dell EMC)
   er unntaket. 0 konkurransegrunnlag er lastet inn (DOKUMENTKILDER), og de ligger bak portaler (ikke skrape, ARCHITECTURE §10). Dekningstaket for tekstuttrekk er derfor lavt, også med LLM.
2. **2025 mangler:** 45 kunngjøringer. Backfillen har bare tatt RESULT 2021–24 og løpende 2026. Steg 2 (`all`) må kjøres før vi kan si noe om «over tid».
3. **Avtaleutløp mangler historikk:** awards finnes bare for 2026 (historikk venter på SC-02-batchene). Uten historiske tildelinger med `contractEnd` får vi ikke en utløpsradar for teknologiavtaler.
4. **Leverandør ≠ produsent:** ordlisten finner produktnavn. Hvem som leverte (Atea, Crayon, Tietoevry) finnes bare i RESULT og awards.

## Haiku-alternativet (ANTAKELSE, MODEL_PRICES 2026-10-06: 1 / 5 USD per MTok)

- **Bare `tenders`-teksten:** ~1,0k tokens inn (system + ~200 tekst) og ~150 ut per kunngjøring ⇒ **~1,75 USD per 1 000** (~1,0 med prompt-caching). Alle 110k ≈ 110–190 USD.
- **eForm-tekst trukket ut av rå-arkivet** (~1,5k tokens): **~3 USD per 1 000** ⇒ ~330 USD for alt. Begrenses til IT-relevante CPV (antatt 15–20 %): **~50–70 USD**.
- Gevinsten over ordlisten er hovedsakelig *klassifisering* (DOKUMENTERT bruk mot ETTERSPURT mot nevnt, produkt mot leverandør) og nye produkter utenfor listen.
  **Rekkefølge:** ordliste på eForm-tekst først (gratis, ~5x), Haiku bare på treffene for klassifisering (~6–7k kunngjøringer ≈ 20 USD).

## Beste mulighet: «teknologiskifte-radar» (også utenfor oppdraget)

Et register over **dagens installasjon per virksomhet** (DOKUMENTERT: «bruker i dag», «eksisterende», «erstatte») med kilde og dato, koblet til
RESULT (hvem leverte) og `contractEnd` (når det går ut). Det gir varsler 6–18 måneder før et bytte, særlig når en produsent fases ut
eller endrer lisenser. Det treffer mange kjøpere samtidig: ePhorte, Visma Profil, VMware og Oracle i datasettet.
- **Hvorfor dette:** det er referanseverdi i praksis. Sak/arkiv har allerede 14–15 kjøpere per system (WebSak, Acos, Public 360), og helse/velferd har Gerica (14) og Visma Flyt (11).
  En vunnet migrering gir en referanse som gjelder hos de neste. Det passer operatørens mål: én vunnet kontrakt i et felt med flere.
- **Gjenbruk, ikke parallelt:** ordlisten blir en del av kjøperprofilen (3.1, `buyer.profile`). Skifte-signalet går inn i overvåker B (radar.expiring)
  og utløpsradaren (paal-1). Kildeteksten ligger allerede i rå-arkivet. Det trengs ingen ny tabell for første versjon (signal med `data`).
- **Verdi (ANTAKELSE):** 1 274 → ~7 000 kunngjøringer med teknologi, ~250 → ~600 virksomheter med et teknologibilde. Datamengden er beskjeden. Verdien ligger i tidlig varsel om kjøp vi ellers ser først når de lyses ut.
- **Kostnad:** ordliste på eForm (~1 dag kode, 0 USD drift) + Haiku-klassifisering av treffene (~20 USD én gang, så ~0,1 USD per døgn løpende).
- **Risiko:** (1) lav dekning fordi listene står i dokumenter vi ikke har; ærlig tall: dagens 1,2 % blir kanskje 7 %. (2) Ordlisten må vedlikeholdes (nye produkter, navnebytter som Agresso → Unit4 og Azure AD → Entra).
  (3) «Nevnt» er ikke «brukt»: klassifisering må vises, og gamle nevnelser må merkes med dato. (4) Leverandørnavn i analyse og visning er greit for intern bruk (ARCHITECTURE §10), men ikke for kunder uten avklaring (CLAUDE.md §7).

**Før noe bygges:** (a) backfill steg 2 for 2025, (b) historiske awards (SC-02-batchene), (c) operatøren bekrefter at teknologiskifte-radar er en retning. Da er neste steg å sjekke inn ordlisten som `lib`-modul med eval (presisjon ≥ 0,9 på 100 treff som et menneske merker).
