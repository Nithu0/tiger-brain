# Lærer triagen av beslutningene som tas i dag?

**Dato:** 2026-10-11 · **Rolle:** learning-1 · **Oppdrag:** code-1-dispatch 09:47Z
**Kode:** `origin/main` @ `3bf5142`, lest fra worktreet `Veldora-lanes`
**Data:** produksjonsbasen på Railway (`anbud`/Postgres), kun SELECT
**Omfang:** ren lesing. Ingen kodeendringer, ingen push, ingen skriving til basen.

## Kort svar

Ja, men med ett døgns forsinkelse, og tellerne operatøren ser i dag er ikke de samme
tallene som styrer forslaget.

Det er **9 beslutninger** i basen. **7 av dem ble tatt i dag** mellom 10:40 og 12:10.
Læringsprofilen kjenner bare **2** av dem, fordi den sist ble beregnet kl. 02:50 i natt,
før dagens økt. Grensen for at forslag vises er 30. Dagens sju beslutninger lander i
profilen klokka 02:50 i natt, og da går den fra 2 til 9.

Det svakeste leddet er ikke en feil i læringen. Det er at kortet i triagen viser
profilens telling, som henger et døgn bak, så operatøren ser «Systemet lærer (n=2 av 30)»
etter å ha tatt sju beslutninger i dag. Arbeidet teller, men skjermen sier ikke det.

---

## 1. Hvor mange beslutninger, og hvor nær grensen?

| Tall | Verdi |
|---|---|
| Beslutninger i basen | 9 |
| Tatt i dag (11.10) | 7 |
| Profilens `n` akkurat nå | 2 |
| Profilen sist beregnet | 11.10 kl. 02:50 |
| Grense for at forslag vises | 30 |
| Lærbare rader i dag | 9 av 9 |
| Rader siden profilen, debounce-telleren | 7 av 10 |

Fordeling: 7 `NO_BID`, 2 `INVESTIGATE`. Alle ni kommer fra triagekøen, én per mulighet,
ingen angret og ingen merket `not-a-tender`. Alle ni er altså lærbare, så nattens kjøring
setter `n = 9`.

Avstand til grensen: **21 beslutninger**. Ved dagens tempo, sju på en økt, er det tre til
fire økter unna.

Det finnes en snarvei i dag: debouncen i `hooks/queueLearnPreferences.ts:14-28` kjører
læringen med én gang det er ti nye rader siden forrige profil. Telleren står på 7.
**Tre flere beslutninger i dag, og profilen oppdateres innen tjue sekunder** i stedet for
i natt. Det er ikke dokumentert noe sted operatøren ser.

## 2. Kjeden, ledd for ledd

Alle tre ledd virker i produksjon. Jeg har verifisert hvert av dem både i koden og mot basen.

**Beslutning lagres.** Triagekøen poster til `POST /api/anbud/triage/decide`
(`crm/src/endpoints/triage.ts:126-180`). Raden skrives i transaksjon, deretter oppdateres
muligheten. Serverfeltene (`snapshot`, `suggestion`, `decidedBy`, `decidedAt`, `source`,
`durationMs`) strippes fra klientens data og settes på nytt fra request-konteksten
(`TenderDecisions.ts:19,40,60-64`), så klienten kan ikke dikte opp sitt eget snapshot.
Verifisert i basen: alle 9 rader har `source = triage` og utfylt snapshot.

**Profil oppdateres.** Jobben `learn-preferences` har kjørt uten feil hver natt siden 05.10,
syv kjøringer på rad. Siste: 11.10 kl. 02:50, «Profil fra 2 beslutninger, 0 regelforslag»,
status ok. Profilen ligger i globalen `decision-profile` med `version = pref-1`, `n = 2`,
fire features og ingen regelforslag ennå.

Utløserne er tre: `afterChange`-hooken med tiers-debouncen, nattlig cron kl. 02:50
(`jobs/registry.ts:118`), og manuelt `worker:once`. Jobben krever en egen prosess, siden
`payload.config.ts:186-190` ikke setter `autoRun`; det er `crm/src/worker.ts:113` som
drenerer køen hvert tiende sekund. CRM og worker kjører på Railway fra samme image, bare
dashboardet ligger på Vercel. Køen tømmes altså faktisk.

**Forslag beregnes.** Beregnes på hver item-GET (`endpoints/triage.ts:119`) og stemples inn
i raden ved skriving. Under grensen beregnes ingenting: `crm/src/lib/triage.ts:313-320`
returnerer `{decision: null, shown: false, reasons: ["lærer (n=X)"]}` før den rører profilen.
Det ligger altså ikke et ferdig forslag og venter på å bli sluppet løs ved 30.

Matematikken er `adjust.ts:115-146`: ett bidrag per feature-familie,
`delta = clamp(signal × 5, ±15)`, retning først når `|signal| ≥ 1.5`. De to tallene 5 og 1,5
er merket `ASSUMPTION — tune` i koden (`adjust.ts:15-16`). De avgjør om det i det hele tatt
foreslås en retning, og ingenting i repoet justerer dem eller måler om de er riktige.

## 3. Svakeste ledd

**`crm/src/endpoints/triage.ts:120` — `profileN: profile?.n ?? decidedCount`.**

Linjen sender profilens telling når profilen finnes, og ellers antall avgjorte muligheter.
Det er to forskjellige populasjoner på samme ledning, og kodekommentaren rett over
(`:98`) sier det selv. Tre konsekvenser, i rekkefølge etter hvor nær de er i dag:

**1. Telleren står stille mens operatøren jobber. Dette skjer nå.**
Kortet viser «Systemet lærer (n=2 av 30)». Operatøren har tatt sju beslutninger i dag.
Tallet rører seg ikke før i natt. Det er ikke feil i betydningen «data går tapt», men det
er feil signal på det eneste stedet operatøren ser etter framdrift.

**2. Telleren kan gå bakover.** Hvis profilen en gang mangler, faller `profileN` tilbake på
`decidedCount`, som er høyere fordi den teller alle avgjorte muligheter uten å luke ut
angrede og `not-a-tender`. Når profilen så landes, hopper tallet ned igjen.

**3. En død pipeline ville sett ut som et ærlig «ingen retning».** Dashboardet kaster bort
`shown`-flagget fra CRM: `dashboard/src/lib/triage.ts:192-194` sjekker bare
`profileN >= 30 && suggestion != null`, og API-et sender alltid et forslagsobjekt. Med 30
avgjorte muligheter og en profil som aldri ble beregnet, ville `TriageCard.tsx:213-226`
rendret «Forslag: Ingen tydelig retning fra tidligere beslutninger · n=30».
Dette er latent i dag, ikke aktivt, siden profilen finnes og `n` er 2.

I systemets favør: begrunnelseslinjen under overskriften sier fortsatt `lærer (n=…)`, og
kalibreringssiden har en ærlig tomtilstand. Sannheten er tilgjengelig, men bare for den som
leser punktlisten nøye eller går til `/calibration`.

### Nest svakeste: læringen er nattlig i praksis

Debouncen teller rader med `createdAt > computedAt`, og den nattlige cronen skriver
`computedAt` på nytt hvert døgn. Intra-dag-læring krever derfor ti beslutninger innenfor
samme døgn. I dag står telleren på 7, så terskelen er innen rekkevidde, men ved normalt
volum er dette en nattlig batch, ikke en løpende loop.

### Tre mindre funn

- **Grensen 30 står fire steder:** `adjust.ts:13` (`MIN_PROFILE_N`), `crm/src/lib/triage.ts:27`
  (`SUGGESTION_MIN_N`), `dashboard/src/lib/triage.ts:18` (`LEARNING_MIN_N`) og hardkodet i
  teksten på `AgentVsHuman.tsx:126`. Bare én heter `LEARNING_MIN_N`, så et søk på navnet
  finner ikke portene som faktisk gjelder. Ingen test sjekker at de fire er like.
- **`suggestionShown` underrapporteres:** møtemodus (`mote/MoteDecision.tsx:51`) og
  mulighetssiden (`OverviewTab.tsx:346`) sender hardkodet `false`, og enighetsmålingen
  teller bare rader med `shown === true` (`agreement.ts:64`). Beslutninger tatt i møte
  havner dermed aldri i «Agent mot menneske».
- **Læringen leser ikke to av de tre kalibreringsfeltene.** Se neste punkt.

## 4. Lagres `durationMs`, `agentVerdict` og `confidence`?

Ja. Alle ni rader har alle tre feltene utfylt, ingen nullverdier. Kolonnene finnes i
`migrations/20261004_123744_triage_decisions.ts:36,37,43`, og den migrasjonen er den eneste
som rører tabellen. Ingen skjemadrift mot kolleksjonen.

Fordelingen så langt, ni rader, altfor lite til å konkludere:

| `agentVerdict` | n |
|---|---|
| vet-ikke | 4 |
| for-høy | 3 |
| riktig | 2 |

Når operatøren først har en mening om agentens score, sier tre av fem at den var for høy.
Retningsgivende, ikke mer.

`confidence`: 5 sikker, 4 usikker.

To hull i oppsamlingen, begge strukturelle og ikke synlige i dagens tall fordi alt så langt
er tatt i triagekøen:

- `recordDecision.ts:17-23` (beslutning endret direkte på muligheten) sender ingen av de tre.
- `TriageForm.tsx:130` beregner `durationMs` bare i kø-varianten, så mulighetssiden sender
  den aldri. Møtemodus sender `durationMs`, men hardkoder `agentVerdict` og `confidence`
  til null.

Viktigere enn hullene: **læringspipelinen henter bare ett av de tre feltene.**
`DECISION_RECORD_SELECT` (`crm/src/lib/decisionStore.ts:10-21`) utelater `confidence`,
`durationMs` og `primaryReason`. `agentVerdict` brukes i enighetsmålingen,
mens `confidence` og `durationMs` i dag bare leses av historikk-UI-et. De samles inn
korrekt, men kalibrerer ingenting ennå.

## 5. Testdekning

Grensen på 30 er godt dekket, på seks steder, inkludert begge sider av 29/30
(`learning/learning.test.ts:146-161`, `lib/triage.test.ts:241-243`,
`scoring/priority.test.ts:166-176`, `dashboard/test/triage.test.mjs:208-212`,
`endpoints/triage.test.ts:73-77`). CI kjører på både push til main og PR
(`.github/workflows/anbud.yml`), og de åtte siste kjøringene er grønne.

Hullet: **ingen test beviser at kjeden lukker seg.** Den er dekket som tre segmenter med en
mock i hver skjøt. Skriveleddet sjekker at `payload.create` ble kalt. Læringsleddet mater
tolv håndskrevne rad-literaler inn i `buildProfile` og sjekker at `updateGlobal` ble kalt.
Forslagsleddet konstruerer en 40-raders profil og injiserer den via `findGlobal`.
Rad-formen det første leddet skriver blir aldri matet inn i det andre, og ingen test
rundturnerer en profil gjennom `updateGlobal → findGlobal → profileOf`.

Det siste betyr noe, fordi `profileOf` (`crm/src/lib/triage.ts:323-326`) returnerer `null`
på enhver versjons- eller formavvik, og systemet degraderer da stille til «lærer (n=X)»
for alltid. Et felt som skifter navn ville ikke gjort noen test rød.

## 6. Observabilitet

Bedre enn forventet, med én blindsone.

Finnes: `decision-profile` i Payload admin med `n` og `computedAt` som readOnly,
«Læringsprofilen» på `/calibration` med «Bygd fra N beslutninger, sist …», og en ærlig
tomtilstand når profilen mangler. Hver kjøring skriver en `agent-runs`-rad med status og
melding, og feil telles i morgenbriefen på Slack.

Blindsonen: **ingen flate i dashboardet viser `agent-runs`.** En operatør som ikke leser
Slack-briefen eller åpner Payload admin ser *når* profilen ble beregnet, men aldri *om siste
forsøk feilet*. En læringsjobb som har feilet i en uke ser identisk ut med en som bare ikke
har fått nye beslutninger: `computedAt` slutter å bevege seg, uten feilmelding noe sted
operatøren ser.

## 7. Utenfor oppdraget, men pågår nå

To ting i produksjon feiler i dag og rammer datagrunnlaget operatøren beslutter på. Jeg
flagger dem fordi de er aktive mens anbud vurderes, ikke fordi de er min lane.

**Anthropic-kvoten er tom.** `assess-requirements` feilet 48 ganger i dag, sist 08:40.
`tender-brief` feilet 9 ganger, sist 02:00. `extract-requirements` feilet sist 10.10.
Alle med samme årsak i `payload_jobs.error`: `invalid_request_error: Your credit balance is
too low`. Kravvurderingen og anbudsbriefen operatøren leser mens hun eller han beslutter,
blir altså ikke generert nå. Dette er en operatørhandling: fyll på kreditt, eller pek
`LLM_PROVIDER`/`LLM_BASE_URL` mot GPU-boksen.

**Google Workspace-tokenet er ugyldig.** `sync-workspace` har feilet 75 ganger i dag, sist
10:15, med `invalid_grant: reauth related error (invalid_rapt)`. Gmail-innboksen synker ikke.
Krever ny OAuth-godkjenning.

## 8. Anbefalinger

Ingenting er utført. Jeg har meldt til code-1 og rører ikke kode før det er avklart,
per dispatchen.

1. **Vis to tall i stedet for ett.** Send `profileN` som profilens tall og `decidedCount`
   som eget felt, og la kortet si «9 beslutninger logget, 2 i profilen, neste oppdatering
   i natt». Det fjerner både den stillestående telleren og muligheten for at den går bakover.
   Lite diff i `endpoints/triage.ts:120` og `dashboard/src/lib/triage.ts:192-194`.
2. **Bruk CRM-ens `shown`** i dashboardet istedenfor å utlede det på nytt. Da kan en død
   profil aldri presentere seg som «ingen tydelig retning».
3. **Samle grensen på ett sted** og eksporter den til dashboardet, med en test som binder
   de fire stedene sammen.
4. **Send `suggestionShown` ærlig fra møtemodus og mulighetssiden**, ellers måler
   «Agent mot menneske» bare en del av beslutningene.
5. **Ta `confidence` og `durationMs` inn i `DECISION_RECORD_SELECT`** hvis de skal brukes
   til kalibrering. I dag er de arkiv.
6. **Én test som lukker kjeden:** skriv en beslutning, kjør jobben, les profilen tilbake
   gjennom `profileOf`, sjekk at forslaget endrer seg. Det er den ene testen som ville
   fanget et feltnavn som glir.
7. **Overvei å si fra i UI-et når tre beslutninger står mellom dagens økt og en
   oppdatering.** Debouncen finnes allerede, den er bare usynlig.

---
_learning-1. Kode lest fra `origin/main` @ `3bf5142`. Produksjonsbasen kun lest, via
`railway ssh` til Postgres-tjenesten. Ingen hemmeligheter skrevet ut, ingen endringer gjort._
