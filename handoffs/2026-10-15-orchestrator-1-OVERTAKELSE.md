# 2026-10-15 — orchestrator-1 overtar alle lanene

Operatøren ba meg ta over panenes oppgaver før en restart, og deretter få **anbudsplattformen**
og **dashboardet** opp. Dette dokumentet er tilstanden ved overtakelsen. Alt annet i panenes
inbokser er bevis; dette er det som gjelder.

---

## 1. RETTET: boten har IKKE et hull. Operatøren merget manuelt.

**Jeg tok feil her, og feilen er dagens mønster i min egen overlevering.** Jeg målte at det ikke
fantes noen grønn check-run på #162s head, og sluttet derfra til at auto-merge-boten hadde merget
på rødt. infra-1 sjekket det ene feltet jeg hoppet over:

```
#162 merged_by=Nithu0              14:31:21Z
#163 merged_by=Nithu0              14:31:34Z
#164 merged_by=Nithu0              14:31:45Z
#165 merged_by=Nithu0              14:31:55Z
#167 merged_by=github-actions[bot] 15.10 05:59:54Z
#168 merged_by=github-actions[bot] 15.10 06:41:55Z
```

**Operatøren merget alle fire manuelt**, 13–21 sekunder fra hverandre, mens sjekkene var røde av
fakturering. Det var en forsvarlig vurdering i øyeblikket — ingen jobb hadde startet, sjekkene var
meningsløse. Boten merget dem ikke, og det er grunnen til at botens logger ikke hadde kjøretidslinjer:
**boten gjorde det aldri.**

**Botens nekt-logikk er intakt, målt av infra-1:** `auto-merge.yml:166-168` blokkerer på
`conclusion != success`, fail-closed på manglende check (`:157-159`). De to PR-ene boten faktisk
merget var grønne — #167 hadde alle sju checks `success`, siste fullført 05:59:38Z, merget 16
sekunder senere.

**Ikke let etter et hull i boten. Det finnes ikke.**

### Det som overlever som ekte funn

De fire landet **uverifisert**. #162 og #165 er siden dekket indirekte av grønne main-kjøringer.
**#163 (`cc6b283`) og #164 (`7577098`) kan være de eneste to som aldri har hatt en ekte kjøring på
det treet som landet.** Det er tråden å trekke.

(learning-1 stilte spørsmålet riktig og stoppet på riktig sted. trading-1 hadde svaret halvt inne i
en 10:30-melding — «#162 ble merget av Nithu0 og ikke av boten» — men det ble lest som en detalj om
hvorfor `anbud` kjørte, ikke som svaret på hvem som merget. Jeg leste det ikke i det hele tatt.)

## 2. Åpne PR-er

| PR | Hva | Hvorfor den står |
|---|---|---|
| **SC #166** | røyktesten kaller faktisk modellen (`ANTHROPIC_API_KEY` til jobben) | **rød på `royktest` — ekte feil**, se §3 |
| **CC #90** | `leak-scan.py`, rettet til `9212775` | ingen auto-merge i command-center; venter gjennomgang |
| **aslisten #62** | vaktposten: grønt på registrert tap, rødt på alt annet | stablet på #46 |

Merget siste døgn: SC #162–#168, CC #91 (omnigent-sporing), CC #92 (ci-guard-detektoren).

---

## 3. Dedupliseringsfeilen — IKKE STARTET, ikke delegert videre

PR #166 ga røyktest-jobben nøkkelen. Resultat: **0 skip på manglende nøkkel** (var 11 tasks over 10
av 27 grønne tester), og **`smoke-konfig.ts` ble rød**:

```
FAIL  re-run adds no duplicate fact
```

`ingest-answer` kjøres to ganger på samme svar og lager faktumet på nytt. **Testen passerte før
fordi agenten aldri kjørte** — null kjøringer gir trivielt null duplikater.

**trading-1s egen korreksjon 09:30Z, og den endrer hvordan dette skal leses:** oppdraget landet i
inboksen deres mens de kjørte suiten, og de leste den ikke før nedlukking. **Ingen måling er gjort,
ingenting er utelukket, prod er ikke talt.** Ikke les «ingen rapport» som «undersøkt uten funn».

**Peker trading-1 ga uten å ha målt, så neste person ikke leter:**
`src/jobs/tasks/ingest-answer.ts:110-121`. Idempotensen er `textKey(f.statement)` — normalisert
eksakt-match på **modellens egen fritekst**, avgrenset per spørsmål. Varierer modellen formuleringen
mellom to kall, bommer settet og raden skrives på nytt. **Ikke verifisert.** Målingen som avgjør er
å sammenligne `statement`-strengene fra de to kjøringene.

**Fortsatt helt åpent:** har dette rammet prod? Der finnes nøkkelen og agentene kjører på ekte.
Tellingen må gjøres les-bare, SQL i skriptfil, aldri inline (regelen fra lekkasjen 11.10).

## 4. Destilleringsloopen lekker én rad i døgnet, nå tredje døgn på rad

Natt til 15.10, 03:04Z, uten tilsyn: **384 av 385 rader for 14.10 destillert, én feilet**, samme
trunkeringssignatur (`Unterminated string in JSON at position 2998`). Task `failed 3/3`.

Dermed er 14.10 en **delvis** dag, og `nightly-distill.ts:176-182` rører aldri delvise dager.
Rad `15679` er permanent tapt uten manuell køing — **og den raden er data-1s eget
overleveringssammendrag.** Loopen mistet nøyaktig utvekslingen som listet opp hva som ble levert.

data-1s korrigerte tall (15.10 06:22Z): **50 rader / 7 dager** eldre delvise (ikke 49/8), og
**3 dødbrev med kjent årsak** (12.10 validering, 13.10 + 14.10 trunkering) — ikke 2.

**Fire kodefikser er spesifisert og ikke startet, venter klarering:** kast bare når
`distilled === 0` · radnivå-kø for dødbrev · `stop_reason`-retry ved trunkering ·
`distill.ts:148` degrader ukjent romtype i stedet for å kaste objektet.

---

## 5. Infrastruktur som kom opp 14.–15.10

- **Selvhostet GitHub-runner:** `nithupc-wsl`, systemd user-unit `github-runner.service`, online.
  Verifisert med ekte jobb: `Initialize containers` grønn med `postgres:18-alpine`, node 22,
  docker 29.1.3, 49 s. **Ingen workflow er flyttet til den ennå** — `runs-on` byttes gjennom PR.
- **GitHub-fakturering:** tak hevet til $20, CI tilbake 14:57Z 14.10. Målt forbruk: 2,1 fakturerte
  min per kjøring, ~1455 kjøringer i oktober ≈ 3 100 min i Solar-Consulting alene (gratis kvote
  2 000). **Røyktesten legger 7–11 min per anbuds-PR oppå dette.** Vurder runner-migrering før 1.11.
- **ci-guard** (CC #92, merget): oppdager jobber som ble nektet å starte — `steps.length == 0` på
  `conclusion=failure`. Jobbnivå, ikke kjøringsnivå.
- **modell-vakt** (tools-1, systemd): bygget og kjører. Avdekket et strukturelt blindpunkt i
  infra-1s vakt — ikke lest i detalj ved overtakelsen.

---

## 6. Verktøy installert, og hva som faktisk virker

| Verktøy | Tilstand |
|---|---|
| **VoiceStudio** | installert `~/.local/bin/voicestudio`, AppImage **utpakket** (libfuse2 mangler, ingen sudo brukt), sjekksum verifisert mot `SHA256SUMS.txt`. Kjører, backend bootstrapper (`sherpa-onnx`, `espeakng`, `transformers`) på :3900. **`stage=setup_required` — venter på operatøren i vinduet.** |
| **heygen CLI** | v0.10.0 installert. **IKKE innlogget.** Ingen av de tre skillene kan gjøre noe. `heygen auth login --oauth` bruker abonnementskreditter; `--api-key` bruker API-kreditter. |
| **3 HeyGen-skills** | `heygen-avatar`, `heygen-video`, `heygen-translate` på disk. **Ingen av dem gjør streaming-avatar** — det er HeyGens Interactive Avatar, et eget API. |
| **Remotion** | `~/my-video`, 335 MB, avhengigheter installert. Kjøres med `npx remotion`. Gratis for team ≤ 3. |
| **hyperframes** | plugin installert i cachen, **krever restart** for å bli synlig. |
| **voicestudio.sh** | død URL, 404. Installasjonen via den skjedde aldri. |

**Maskinen:** 6 kjerner, 11 GB RAM, ingen NVIDIA-driver (`/dev/dxg` finnes), WSLg aktiv, 805 GB fri.
CPU-inferens for alt lokalt.

---

## 7. Beslutninger tatt av operatøren 14.–15.10

1. **Dokumentstrategi:** hyyr-adapteren ferdig + manuell opplasting for resten. TendSign og Ivalua
   har `Disallow: /` — 342 lenker, 28,9 % — så legitimasjon løser ikke robots-delen. EU-Supply
   forbyr `/app/docmgmt` eksplisitt. Mercell, hyyr og Artifik svarer HTTP 200 HTML på `/robots.txt`
   (SPA-catch-all): **taushet som leser som samtykke.**
2. **Push-gate:** orchestrator bærer operatørens kommando for igangsatte storoppgaver. Gjelder
   **ikke** merge til main, sletting, prod-skriving eller penger.
3. **Cockpiten:** skal **erstatte hele pane-systemet**. Styrer paner som kjører bak på abonnement
   (Slice 11 Terminal Orchestrator finnes alt). Ikke headless på betalt API — ingen kostnadsledger
   finnes ennå.
4. **Avatar:** én levende samtale-avatar som produkt, bygget på anbudssiden først og gjenbrukt i
   cockpiten. **Ubesvart: hvem snakker med henne** (operatør / kunder / pilotkunder).
5. **Rotasjon av lekket OpenAI-nøkkel:** ikke nødvendig, operatørens vurdering. Nøkkelen er i
   **2 forekomster i én transkripsjonsfil**, og **0 rader i `memory.db`** (min tidligere påstand om
   6 rader var feil — `like '%sk-proj-%'` traff prosa).

---

## 8. Cockpit-spesifikasjonen

`00-claude-inbox/command-center/2026-10-14_cockpit-input.md` — panenes egne svar på hva som hører
på en flate, med datakilde per element, og hva som er bevis og hører i en rapport.

**Den viktigste regelen som kom ut av den:** hver tile må svare på *overlever suksess i denne
kilden, eller bare feil?* `payload_jobs` består ikke — Payload sletter jobber som lykkes, så den
tabellen lyver i begge retninger: «331 jobber venter» når ingenting venter, og «ingenting siden
10:00» når alt har skjedd. Gjennomstrømning måles i `llm_usage` (`ok=true`) og `briefs`.

**Flaten som finnes:** `command-center/apps/web`, 18 komponenter, siste endring **13. juni 2026**,
kjører ikke. `OrchestratorPanel` · `TerminalConsole` · `BrainPanel` · `BrainHealthPanel` · `PRList`
· `DeskStatus` · `RouterPanel` · `AuditTrail` · `PushControls` m.fl.

---

## 9. Står på operatøren

| Sak | Hvorfor den venter |
|---|---|
| **7 saker `READY_FOR_ALTINN` uten dokumenter** | siden 12.09, ingen eier. Kan treffe en ekte kunde (Pål i Brønnøysund). **Dette er det eneste som kan skade noen utenfor firmaet.** |
| `heygen auth login --oauth` | blokkerer all avatar-bygging |
| VoiceStudio førstegangsoppsett | `setup_required`, analytics-samtykke er operatørens |
| `compare-brief-models.ts` | vi byttet modell på den dyreste jobben: −76 %/kall, men ut-tokens falt 61 %. Ingen har sammenlignet kvaliteten |
| De 13 briefløse besluttede | 7 STRONG_BID uten grunnlagsdata, 9 av 13 uten frist. Under én krone å dekke |
| Sletting av 6 landede grener + 6 worktrees | bevist trygt av admin-1 via blob-SHA |
| ToS for TendSign/Ivalua | må åpnes i nettleser av et menneske; `Disallow: /` dekker vilkårssiden |
| Opprydding: 120+ lokale grener, 46 worktrees | trenger ordentlig metode, ikke emne-sammenligning |

---

## 10. Dagens gjennomgående mønster, for den som tar over

Fem ganger på to dager ble **noe stille lest som noe bekreftet**:

- en test som var grønn fordi agenten aldri kjørte
- en tabell som meldte «331 jobber venter» fordi bare feil overlever i den
- en varslingskanal som ikke fyrte og så ut som en rolig natt
- et `robots.txt` som svarte HTTP 200 HTML og leste som tillatelse
- en merge-port som sa den nektet, og merget likevel

**Regelen:** et søk som ikke traff er ikke et fravær, og en kanal som ikke sier noe er ikke en rolig
natt. Hver gang noe er stille: mål at mekanismen faktisk kjørte, ikke bare at den ikke klaget.
