# admin-1 — GOALS

## Aktivt mål (ETT)

**AS-regnskap: august-pakken klar før MVA-fristen 31.08.2026 (termin 3/2026).**

Done-kriterier (status 2026-08-19):
- [x] Juli-lønnssyklus kjørt — skjema fylt 14.08, **faktura 10017 utstedt 31.07** (bekreftet i Fiken-synk 19.08). Close-out: `AS/Lønn Juli/_mangler-og-usikkerheter-juli.md`
- [x] MVA termin 3/2026 avstemt og klar: netto **20 982,41** — stabilt over to uavhengige synk (20.07 + 19.08). Leveringsgrunnlag: `AS/docs/mva-termin3-2026-grunnlag.md`
- [x] Altinn-verifisering forberedt som sjekkliste i samme doc (selve innloggingen krever ID-porten = operatør; report-only)
- [x] Operatør-liste levert (chat 19.08 + grunnlag-doc). Juni-fakturaen (10016) er utstedt — punktet utgår.

**Gjenstår = operatør:** lever+betal MVA termin 3 innen 31.08 (Fiken → Altinn), 3 mai/juni-kjøp uten vedlegg, Altinn-sjekklisten.

Gates: selve leveringen/betalingen i Altinn/Fiken = operatør. Min jobb (alt klart + verifisert grunnlag) er FERDIG.

## Kø (ikke aktive)

- Lønn august-syklus (Verisure-eksporter ventes primo september) — blir neste aktive mål
- Bilagshull: 18 kjøp uten vedlegg i Fiken (netto ~89 400; 20.07-runden sa 17 — én ny i august)
- call-center-ai-demo: push-beslutning for commit 551f852 (HARD_LOCAL_PATHS-flagget lukket av infra-1 14.08)
- Personlig: operatør-beslutninger (mål/mat-fase/split) — kan ikke drives herfra
- Søking-arv: commit/bevar voice-agent + prep-materiale (operatør-gate, ingen remote finnes)

---

## PARKERING 2026-10-13 — Veldora strategiråd runde 1

**Hva jeg hadde i gang:** AS-regnskapssporet. Aktivt mål (MVA termin 3/2026 + juli-lønn) er FERDIG fra min side — alt gjenstående er operatør-gated (Altinn/Fiken-levering krever ID-porten). Ingenting halvferdig i kode.

**MÅ gjøres før noe annet:** Ingenting fra meg. MVA-fristen 31.08.2026 er for lengst passert i kalendertid — hvis den IKKE ble levert er det en operatør-sak (forsinkelsesrenter/tvangsmulkt), ikke noe jeg kan lukke herfra. Jeg flagger det som eneste tidskritiske punkt og går videre.

**Trygt å parkere:**
- Lønn august-syklus (venter Verisure-eksport, ingen frist i dag)
- Bilagshull 18 kjøp uten vedlegg (akkumulerende, ikke akutt)
- call-center-ai-demo push-beslutning commit 551f852 (operatør-gate, ligger trygt lokalt)
- Personlig + Søking-arv (operatør-beslutninger)

**Farlig å etterlate:** Nei. Ingen uncommittede endringer, ingen halvkjørte migrasjoner, ingen åpne skriveoperasjoner mot Fiken/Altinn. Alt AS-arbeid ligger som dokumenter, ikke som kjørende prosess.

**Ny rolle i rådet:** Legal & Regulatory Analyst.

---

## OPPDATERT 2026-10-13 14:15 — bølge 1 levert, og ett tidskritisk AS-funn

**Veldora bølge 1 (rådsrollen):** tre commits på `admin-1/terskel-frist`, upushet, venter «OK kjør».
`dc88a2f` terskel/frist-grunnlaget som data (tabellen tom med vilje — juristgate) · `9318c83`
fristsprik varsles faktisk (`deadline.mismatch` manglet i `IMMEDIATE_TOPICS`, og topicen alene var
ikke nok fordi `immediateItem` har `default: return null`) · `d243acf` helgeadvarselen navngir dagen.
Suiten 2615 grønn, kjørt åtte ganger. Blokkert på to juristgater: `LIK_TERSKEL_ER_OVER` og
`FRIST_REGEL.hjemmel`.

**AS-sporet — tidskritisk, uløst i min egen fil siden 19.08.** Beløp står bevisst IKKE her: denne
mappa ligger i Brain-vaulten, som synkes til et delt repo (`00-firm-bus/feed.md` er sporet), og
`project_as`-regelen sier at beløp ikke skal inn i Obsidian. Tallene ligger lokalt i
`AS/docs/fiken-avstemming.md` og `AS/docs/mva-termin3-2026-grunnlag.md`.

Syv MVA-terminer pluss skattemelding næring 2025 står som **uverifisert levert** — ikke som
«ikke levert». Operatøren kan ha levert alt via Fiken/Altinn uten at det ble ført tilbake.
Sjekklista i `AS/docs/mva-termin3-2026-grunnlag.md:27-31` er uavkrysset. Fristene, eldste først:
termin 5/2025 (10.12.2025) · 6/2025 (10.02.2026) · skattemelding næring 2025 (01.06.2026) ·
1/2026 (10.04.2026) · 2/2026 (10.06.2026) · 3/2026 (31.08.2026) · forskuddsskatt 3. termin
(15.09.2026) · **termin 4/2026 (12.10.2026 — i går, ingen spor av forberedelse etter 19.08)**.

Alvorligere enn «uverifisert» for de tre eldste: `AS/docs/kapitalprioritering.md:29` (01.06.2026)
behandlet 5/2025 + 6/2025 + 1/2026 som **forfalt**, med renter/mulkt, som steg 1 i kapitalvannfallet.
De var altså kjent forfalt i juni. Om juni-opprydningen ble gjennomført, vet repoet ingenting om.

**Rettelse til meg selv:** jeg leste først «Levert + betalt» og ✅-linjene i `kapitalprioritering.md`
som spor av at noe VAR levert. Feil — kolonnen heter «Utløser neste når», og ✅-lista er vilkår for
hardware-kjøp, ikke en logg. Ingen fil i `AS/` dokumenterer at noen termin er levert.

**Beløpsavviket på termin 2/2026 er avklart uten operatøren:** det lavere tallet kommer fra
Fiken-avstemmingen 19.08 med komponenter (utgående − inngående), det høyere fra et anslag 01.06.
Den senere avstemmingen vinner; anslaget bør merkes foreldet i `mva-skatt-action.md`.

**Neste steg er operatørens og tar et par minutter:** skatteetaten.no → «Mva-melding» → innsendte
meldinger svarer på alle radene. Resultatet føres i `AS/docs/regnskap-status.md` (lokalt), og da kan
jeg lukke eller eskalere hver rad. Spørsmålet er smalt: **ble juni-opprydningen gjennomført, og er
termin 3 og 4 levert?**
