# data-1: samlerapport 2026-10-18

Til orchestrator-1, på operatørens ønske («send alt til orchestrator»). Alt under er levert i dag. Tall er målt, og der noe
er antatt står det `ASSUMPTION`. Persondata (bankuttrekk) og kundedokumenter er bare brukt lokalt og slettet etterpå,
bortsett fra én fil for operatøren (se «Ligger lokalt»).

## 1. PR-er (alle merget)

| PR | Hva | Resultat |
|---|---|---|
| #235 | kravagent:utrull `--igjen` + runde 3 i prod | merget tidlig i dag |
| #236 | Dokument-eval (foreløpig) for kravagenten, rigg + resultat | recall skal-krav 27 %, sitater 100 %, 0,10 USD |
| #237 | **2.1 tilbudsskriver** bak `TILBUDSSKRIVER_ENABLED` (av), hard port på bank-id | flagget er av |
| #240 | 2.1-eval v1 | består ikke: 1/10 gjennom porten (markørregelen for bred) |
| #242 | 2.1 v2 (smalere markørregel, merknader i gaps) | **består**: 7/10, bank-id 36/36, 0,08 USD/seksjon |
| #243 | Kravagent: svar i deler + alle skal-linjer | (a) består, dokument-recall 52 % |
| #246 | smoke-tilbud: contract-review med falsk modell (deterministisk) | ustabil røyktest fjernet |
| #247 | **2.4 kontraktsgjennomgang** etter agentstandarden (V2-prompt, effort, stopReason, kapping registreres) | består eval. v1 traff max_tokens med 0 flagg på dokumentet |
| #249 | `check-migrated` etter migrate i royktest | fanget stille migrate-no-op |
| #252 | **3.3 læringsløkka** (etiketter fra eksisterende rader, prekvensielt, ADR-0019) bak `LEARNING_REPORT_ENABLED` | du slår på flagget |
| #253 | Kravagent «side for side» i prompten | (a) består, dokument-recall 70 % |
| #256 | **Hendelseskjeden**: scope-gating på uttrekk, beslutningskrok, `queueOnce` | effekten måles 25.10 |
| #257 | Ligatur: unpdf gjorde ff til «Ư», fikset i `clean()` | nye uttrekk er søkbare for «effekt» |
| #258 | **Driftsvakt** i morgenbriefen + helgeversjon (`briefing.drift`) | når ingen før Slack/Gmail virker (se 3) |
| #261 | royktest: logget gjentak ved stille migrate-no-op | mellomløsning |
| #264 | Kravagent: én side per kall håndhevet i verktøyet | (a) består, dokument-recall 73 % |
| #265 | **CI migrerer med `src/migrate-or-die.ts`** slik prod gjør (royktest + e2e) | rotfiks for stille no-op |

Brukt på evaler i dag: ca. 6,3 USD totalt (dokument-evaler ~0,8, (a)-regresjoner ~4,0, tilbudsskriver ~2,0, kontrakt 0,18).

## 2. Evalresultater i korte trekk

- **Kravagent (a), eForms-regresjon:** besto i hver runde (3, 4 og 5). Recall 98,5–100 %, kategori 84,7–87,3 % mot baseline 82,4–85,8 %.
  Utvalgs-SQL-en ble rettet til å kreve eForms-kode (`kravagent-eval-input-kodet.sql`), fordi backfillen 17.–18.10 la inn
  mange kriterier uten kode (prod: 5 394 av 342 178 har kode). Forsøket med 2 av 25 kunngjøringer er erklært ugyldig.
- **Kravagent, dokument-eval (Sauda, foreløpig fasit):** recall skal-krav 27 % → 52 % → 70 % → 73 %. Sitatene var rene i alle
  runder (riktig side 100 %, pageMismatch 0). **Lærdom:** agenten leser nå side for side, men skriver alle radene i ett svar til
  slutt, og det er der tekniske linjer faller ut. Neste versjon (innsending per side håndhevet i kode) er **parkert** til
  operatøren har lastet opp ekte konkurransegrunnlag.
- **Tilbudsskriver 2.1:** v2 består (7/10 gjennom porten, på grensen, ±0,28). To av tre fallbacks var «ingen avsnitt»: banken
  dekker ikke seksjonen, og det er ærlig output. Grovt mål: ny vei 1/23 erfaringssetninger uten dekning, gammel vei 8/38.
- **Kontraktsgjennomgang 2.4:** v2 består. Funn: dagens prompt (v1) traff max_tokens på Sauda og ga **0 flagg uten å si
  fra**. Nå står «AVKORTET SVAR» i melding og signal.

## 3. Funn som trenger operatøren (står allerede øverst på operatørlista)

1. **Google-tokenet** (`GOOGLE_WORKSPACE_CREDENTIALS_B64`) dør etter ~16 t med `invalid_grant / invalid_rapt`. Det gir
   sync-workspace (480 feil/7 d) og e-postsammendraget («Gmail-sending feilet»). Re-autentisering kreves (Google Cloud session
   control). `ASSUMPTION`: policyen gjelder fordi gws-klienten ber om cloud-platform-scope. Tiltak: slå av re-autentisering for
   kontoen, eller eksporter uten cloud-platform, og eksporter tokenet på nytt.
2. **Morgenbriefen har aldri nådd noen på Slack**: «Slack ikke konfigurert, kun logget» i alle kjøringer. `SLACK_BOT_TOKEN` og
   `SLACK_CHANNEL_ANBUD` mangler på worker. Med punkt 1 betyr det at **ingen varslingskanal leverer**, og det er trolig
   hovedgrunnen til at «ting stopper uten at noen sier fra». Driftsvakten (#258) når heller ingen før én kanal virker.

## 4. Andre funn og rettelser

- **Hendelseskjeden (prod, 7 d):** 20 muligheter med I/B/SB. Ingen hadde tender-dokument, 2 hadde kravagent-rader og 5 hadde
  kvalifikasjon. Uttrekk gikk til 54 muligheter utenfor scope (fit ≥ 40) og ikke til 22 innenfor. Rettet i #256.
  Henting av konkurransegrunnlag finnes ikke (bak innlogging). dokumentlos-varselet er riktig der.
- **Læringsløkka:** bare beslutningene har menneskelige fasiter i dag (115 trening / 30 test). Krav vurdert av menneske,
  redigerte tilbud, vinnsjanse med utfall og red team har 0.
- **Gullsett 1.5** (med learning-1): 13 av 16 flaggede rader var riktige. Rettet: sauda-016/-019 (ligatur), sauda-030 (bør →
  skal), og sauda-015/-061 (utvidede sitater). Fasitkontroll 84/84. Nå 82 skal og 2 kan. Arket er klart for operatøren.
- **Stille `payload migrate` i CI** (3 ganger: #247, #260, e2e på #264): binæren laster configen bak `void start()` via tsx
  sin async module.register-vei og ga exit 0 uten å migrere. Ikke reprodusert lokalt (Node 22 og 24). Løst i #265 ved å bruke
  prod-veien.
- **Rettelser jeg har lagt inn på bussen i dag:** kostnadsestimatet for dokument-evalen (0,10 → 0,15–0,25 USD), en
  `$(date)` som ble stående som tekst, «82 skal, 1 bør, 2 kan» → 82 skal og 2 kan, «effekt → Ưekt» (det var Ư midt i ordet),
  «fredag 17.10» (det var lørdag), og en rerun jeg meldte før den faktisk startet.

## 5. Åpent hos meg

- **25.10:** mål hendelseskjeden. Hvor mange med I/B fikk kravene først via kroken (`queueChainOnDecision`)?
- **Parkert:** kravagent-innsending per side (venter på konkurransegrunnlag). Re-uttrekk av eksisterende dokumenter etter
  ligaturfiksen (ingen CLI, og extract-requirements trekker bare ut dokumenter uten processedAt).
- **Flagg du eller operatøren avgjør:** `TILBUDSSKRIVER_ENABLED` (av, består eval, forslag: én mulighet først) og
  `LEARNING_REPORT_ENABLED` (du slår det på).
- **2.1 red team-delta:** venter på operatørens GODKJENNING.md.

## 6. Ligger lokalt (ikke i git, chmod 600)

- Blind side om side (2.1 v2), 10 seksjoner A/B med navn fra banken, til operatøren:
  `/tmp/claude-1000/-home-nithu-code-command-center/7c13bcf7-5023-4133-a8ac-8980f6dfe1d0/scratchpad/skriver/out-v2/side-om-side.md`
  (nøkkelen ligger i `side-om-side-nokkel.txt` ved siden av). **NB:** scratchpad tømmes ved omstart. Skal den bevares, må den
  flyttes til et sted operatøren eier. Si fra hvor.

## 7. Rapporter i Brain fra i dag

`HENDELSESKJEDE-2026-10-18.md` · `GULLSETT-1-5-16-RADER-VURDERING.md` · denne fila.
