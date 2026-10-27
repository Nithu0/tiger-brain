# admin-1 — alt levert 2026-10-14 (overlevering)

Pane-kjøring, `f4cb3f0` som referanse. Ingenting pushet, ingenting slettet, ingen prod-skriving.
Fire leveranser, fem sidefunn, fem gater som venter på operatøren.

## 1. Dom over de seks agent-grenene — ALLE SEKS er på main

Rapport: `00-claude-inbox/Veldora/2026-10-14_dom-seks-agentgrener-pane.md`

| Gren | Landet som |
|---|---|
| `feat/036-046-prising` | `5e021c9` (#108) |
| `feat/044-045-klage` | `c179afa` (#107) |
| `feat/037-041-tilbudskvalitet` | `3bf5142` (#109) |
| `feat/042-043-kvalifikasjon-kontrakt` | `7bfde05` (#115) |
| `fix/anbud-login-mobil-touch` | `9c8f624` (#122) |
| `fix/anbud-kommentar-vurder-konvolutt` | `dad2a8f` (#116) — samme feil, annen fiks |

Avgjort på **innhold**, ikke tittel: hver fil grenene legger til er **byte-identisk** med
`origin/main` (blob-SHA-sammenligning). Restene i endrede filer var mains versjon som har gått
videre, altså superset. Adversarisk-fiksene (`a7360d7`, `63b8b43`) fulgte også med.
Orchestrators emnetabell var feil på alle seks, fordi squash-merge gir nye titler.

**Ingen er landbar. Ingen har noe å berge.** Grenene og de seks worktreene under
`~/code/Veldora/.claude/worktrees/agent-*` kan slettes når du sier fra.

## 2. ADR-0018 — frister har flere kilder, terskeltabellen er en hurtigbuffer

`decisions/ADR/ADR-0018-frister-har-flere-kilder-terskel-er-hurtigbuffer.md`,
commit **`bddff83`** på `admin-1/adr-terskel-frist` (worktree `~/code/Veldora-frist`, ahead 1).
`node scripts/validate.mjs`: 60 filer mot 16 skjemaer, alt gyldig. **Ikke pushet.**

Dokumenterer det som alt er bestemt og landet: ingen enkeltkilde autoritativ for tilbudsfristen
(modellkandidaten er den ene uavhengige kilden som gjør kryssjekken mulig), terskeltabellen som
datert hurtigbuffer med FACT-krav og aldri rettskilde, skillet regelberegnet mot kildelest, og at
forbeholdet aldri peker ut en vinnerkilde. Begge de trukne forslagene fra 13.10 ligger i
«Alternatives considered», så ingen bygger dem på nytt. Indeksen manglet også 0017 — lagt inn.

## 3. Heygen — kartlagt, angrepet av paal-1, lukket

Eier/motpart-runden orchestrator ba om. Full utveksling i `00-firm-bus/inbox/paal-1.md`
(12:10Z forslag → 10:08Z angrep → 12:25Z svar → 10:16Z replikk → 12:38Z → lukket 10:23Z).

**Hva de tre skillene er:** `heygen-translate` dubber eksisterende video til 175+ språk (klonet
stemme, lip-sync). `heygen-video` genererer ny video via Video Agent. `heygen-avatar` lager og
lagrer avatar-identiteter for gjenbruk. Bare translate er installert (v3.2.0); de to andre leste vi
med `gh skill preview`, uten installasjon.

**Hva som blokkerer alt, bekreftet i to paner:** `HEYGEN_API_KEY` MISSING, ingen `mcp__heygen__*`
i verktøylista, `heygen` CLI ikke installert. **Begge transportene er fraværende.** Vi har en skill
installert som ikke kan utføre noe.

**Tre regler vi ble enige om, og som trenger å stå nedskrevet fra deg:**
1. `HEYGEN_API_KEY` skal stå MISSING i hver pane — transporten velges av **miljøet**, stille, i både
   translate (`SKILL.md:61`, `:70-74`) og video (`:73`, `:92-93`). Fallback er aldri å sette nøkkelen.
2. Anslag før render i skillens egen enhet: kildeminutter × antall språk for translate (skillen
   **forbyr** kronebeløp, `:379`), sekunder × publisert sats for video/avatar. Kr/min hører hos deg.
3. Samtykke, fem punkter: formål, lagringstid, sletting, hvem som får utløse en render med
   identiteten, og datert gyldighet for ÉN kampanje.

**Den ene testen som avgjør resten:** etter at OAuth er koblet, ett kall til
`list_video_translation_languages()` fra ÉN headless pane. Null kostnad, ingen video, ingen render.
Vi vet ikke om en OAuth-koblet MCP-server i det hele tatt blir synlig i en systemd-pane uten
nettleser — svaret avgjør om CLI-installasjon (gatet) må på bordet.

**Funn som sparer noen en runde:** `website/public/solarconsulting/hero.mp4` (11 s, ligger i 18
worktrees) har **ingen lydstrøm** — translate er en no-op på den. Eneste fil vi har med noen som
snakker er din egen video-CV (`Søking fulltid/profil/video cv.mp4`, 208 s, h264+aac). Altså: vi har
ikke råstoffet for kundevendt dubbing på Solar Consulting-materiell.

## 4. Dom over de 13 briefløse besluttede anbudene

**`decision = UNDECIDED` i `queueWhere` er bevisst** — inn med PR #54 (`822f66b`, 4. okt), samme
commit som beslutninger ble innført; køen *er* definisjonsmessig det ubesluttede, og fem konsumenter
avhenger av betydningen. **Feilen ligger i `brief-coverage`**, som gjenbruker køens predikat som
definisjon på «hvem fortjener grunnlagsdata».

**Fristspørsmålet kan ikke separeres i dag, og det er selve funnet:** `tenders.deadline` kommer rett
fra Doffins eget felt (`doffin.ts:180,196`), mens dokumenttekst og TED-tvilling bare leses av
`deadlineCandidates()`/`compareDeadlines()` — som kjører **inne i `tender-brief`**
(`tender-brief.ts:146`). De seks STRONG_BID uten frist mangler altså kryssjekken av samme årsak som
de mangler brief. **Diagnosen og fiksen er samme handling.**

Forslag (ikke bygget): ett nytt utvalg i `brief-coverage` — besluttet (ikke `NO_BID`) og uten
brief-rad, uten `TRIAGE_STATUSES` og uten frist-leddet. Rører ikke `queueWhere`. 13 briefer koster
under én krone, men **queuer LLM-jobber som skriver til prod**, så det er en kjøring og dermed gatet.

## Sidefunn (fem, alle utenfor oppdraget)

1. **`legal/terskel.ts` har ingen konsumenter.** `vurderPart` kalles bare fra sin egen test;
   `partOf(tender.aboveEeaThreshold)` mater fortsatt `feilsjekk/store.ts:233` og `klage/store.ts:96`.
   Terskel-utledningen er bygget riktig og koblet til ingenting. Skrevet inn i ADR-en så den ikke kan
   leses som at den er i drift.
2. **`klage/deadlines.ts:111` hardkoder «30 dager»** for søksmålsfristen, i strid med modulens egen
   regel om at hvert dagtall leses fra korpusteksten. Ikke en fristfeil (`date` er null), men et
   hardkodet juridisk tall. Egen liten skive.
3. **`gh skill preview` bryter lange linjer**, så linjenumre lest av et preview er ikke filnumre.
   Bruk `gh api … | base64 -d` når et nummer skal siteres.
4. **Jeg korrigerte paal-1 feil og trakk det der jeg skrev det.** Hans linjenumre var riktige for den
   installerte translate-skillen; mine for `heygen-video`s råfil. Feilklassen: en korreksjon som er
   sann i sitt eget tilfelle, påført et tilfelle den ikke dekker.
5. **Ingen prod-lesetilgang i panen min.** Begge `.env`-filene i worktreene peker på lokale baser
   (5439, 55432) og ingen Postgres lytter. Jeg leste variabelnavn, aldri verdier, og kjørte alt
   gjennom en skriptfil.

## Gater som venter på deg

1. **«OK kjør» for ADR-pushen** (`bddff83`). NB: CI er nede på hele repoet siden ~09:50Z av
   fakturering (meldt av infra-1 og learning-1) — en push nå gir røde kryss av den grunnen, ikke av
   innhold.
2. **Sletting** av de seks grenene + worktreene (grensletting er gatet).
3. **Heygen:** bruksvalget, OAuth-koblingen, og de tre reglene nedskrevet.
4. **De 13 briefene** — kjøring mot prod, under én krone.
5. **Prod-lesetilgang** (eller de 13 id-ene fra tools-1) hvis du vil ha fristsvaret per rad før
   briefene kjøres.

— admin-1
