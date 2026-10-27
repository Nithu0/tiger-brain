# tools-1 — overlevering 2026-10-14

Alt levert i denne sesjonen, med etterprøvbar kilde per punkt. Dispatch: `inbox/tools-1.md`
2026-10-14T06:30Z, punkt 1-3, pluss operatørens påfølgende ordre (fyll konto → hold monitor).

## Levert

### 1. Sporing av omnigent + ralph — PR #91, pushet på «OK kjør»
Commit `12612b4`, 29 filer, gren `tools-1/spor-omnigent-ralph` → https://github.com/Nithu0/command-center/pull/91

Dom per sti: `omnigent/firm/` (25 filer) **spores** — `omnigent`-CLI er faktisk installert
(`~/.local/bin/omnigent`), `_bin/omni-firm.sh` er dokumentert inngang. `_bin/ralph-{once,afk}.sh`
+ `ralph-prompt.md` **spores** — skillen `prd-to-issues` refererer `ralph-once.sh` i sin egen
avslutningsinstruks, og runbooken finnes. `body.txt` **dødt** — Doffin-HTML fra 07.09, hører til
Veldora; sletting er operatør-gated og den ligger urørt.

Kjent begrensning skrevet inn i både commit og PR: `agents/*/config.yaml` er generert av
`sync-agents.py` og har absolutte `/home/nithu`-stier, så de er ikke portable — men spores likevel,
fordi kilden (`~/.claude/agents/*.md`) ligger utenfor repoet. Legitimasjonsskannet, ingen treff.

### 2. Gjennomgang av PR #90 (leak-scan) — 15 funn, 2 blokkerende
Rapport: `00-claude-inbox/command-center/2026-10-14_tools-1_gjennomgang-pr90-leak-scan.md`
Overlevert forfatteren i `inbox/infra-1.md`. Grenen ikke rørt, ingen GitHub-kommentar.

Hovedspørsmålet besvart med måling: **skanneren lekker ikke** det den finner (3930 filer, 2:01,
exit 1 med ekte treff, null verdier skrevet). Push-porten er reelt sterkere enn `871a291` — 15
push-stavemåter probet, alle blokkert.

Blokkerende: (1) `credential.helper=` + `GIT_ASKPASS=/bin/false` i `firm-remote-executor.sh:63,72`
brekker `git fetch` i **alle fire** repoene (jeg målte origin-skjema: alle `https://`), ikke bare
«private repos» som kommentaren antyder. (2) `leak-scan.py` kan ikke se OpenAI-nøkler i det hele
tatt — `SPOR`-filteret `:68-70` mangler `sk-`-markør og regexen `:59` kan ikke matche `sk-proj-`;
bommer også på `github_pat_`, `glpat-` og Telegram bot-token. For en skanner der exit 0 leses som
«rent» er falsk negativ den verste feilmodusen.

To små i samme runde: `:51` er ubegrenset `+` mens kommentaren `:41-46` hevder 256-grense (målt
48,7 s mot 0,053 s), og `push-gate.sh:17-22` består 17 nekt-assertions med alle fire shimene
slettet. Jeg etterprøvde alle fire selv i koden før jeg videreformidlet dem.

### 3. Modellrutingen fra #158 — bevist i drift, og prisen målt
Rapport: `00-claude-inbox/command-center/2026-10-14_tools-1_ruting-i-drift-og-prod-stans.md`

Bevist i `llm_usage`, ikke resonnert: `generate.brief` gikk fra `claude-sonnet-5-5` (95 kall døgnet
før) til `claude-haiku-4-5` første rad **19:20:03Z, 19 min etter merge 19:01:32Z**.

Underveis fant jeg at anbud-CRM hadde stått i 26 timer på `credit balance is too low` — samme
årsak som brain-worker, men i prod. Etter operatørens påfylling (første ok-kall 10:41:30Z) er
sluttmålingen, n=65:

| model | ok-kall | ut-tokens | USD/kall | latens |
|---|---|---|---|---|
| sonnet-5-5 | 794 | 1802 | 0,02214 | 11 347 ms |
| haiku-4-5 | 65 | 700 | 0,00524 | 5 771 ms |

−76 % per kall, $17,58 → $4,16/uke ved måleukas volum. **Bedre enn mitt eget anslag ($8,79), og
jeg tok feil av en grunn som er verdt å kjenne:** anslaget antok konstante ut-tokens. De falt 61 %.
Driveren er svarlengden, ikke modellprisen.

Etterslepet fra stansen er tømt: eksakt `queueWhere`-måling gir **789 muligheter i køen, 0 uten
brief**. Prod-stillhet er nå riktig tilstand, ikke en stans.

## Åpne gater — bare operatøren

1. **`body.txt`** — dømt dødt, ikke slettet. Sletting er gated.
2. **`scripts/compare-brief-models.ts`** bør kjøres mens det er kreditt. Et 61 % kortere svar på
   samme tvungne skjema er en materielt **annen** brief, ikke samme brief billigere. `models.ts:137-139`
   krever denne sammenligningen før haiku kalles trygt. Koster API-penger.
3. **Kostnadsledger** — det finnes ingen (`feedback_headless_dispatch_costs_api.md`). Kontoen gikk
   tom uten at noen så det, og prod stod 26 timer. Jeg mener den er på tide; bygger ingenting selv.
4. **PR #90** trenger infra-1, ikke operatøren — men den har stått et døgn uten gjennomgang i et
   repo uten auto-merge.

## Funn meldt, ikke bygget

- `extract.requirements` + `-check` er mekaniske uttrekk (`dataClass: 'public'`) men står ikke i
  `TASK_MODEL_DEFAULTS` — 51 sonnet-kall siden merge. Samme klasse som de fem som ER i tabellen.
- **13 muligheter mangler brief helt, og alle 13 er besluttede: 7 STRONG_BID, 4 BID, 2 INVESTIGATE.**
  `queueWhere` krever `decision = UNDECIDED`, så `brief-coverage` dekker dem aldri. De anbudene
  firmaet skal levere på, er de eneste uten grunnlagsdata i triage-kortet. Seks av de sju STRONG_BID
  mangler også frist i basen.

## To ganger jeg tok feil i dag, og hva som fikset det

1. Jeg leste et burst-gap i prod som en stans, og meldte at «prod gjør ingen forsøk». Feil: briefene
   kommer i byrs av 15 hvert 20. minutt, og to målinger kan treffe samme stille gap. Hjerteslaget
   viste bare absolutte tall. **Fikset:** monitoren viser nå delta siden forrige hjerteslag, antall
   siste 30 min, og basens egen klokke.
2. Jeg brukte en ekspanderende heredoc, så backticks i meldingsteksten ble kjørt som kommandoer og
   hang på en `railway ssh`. Ingenting ble skrevet. **Fikset:** quotet heredoc med placeholder, og
   jeg verifiserer nå `grep -c` at hver bus-skriving faktisk landet.

## Metode

Prod-tilgang var read-only hele veien: `SET default_transaction_read_only = on;` i hver SQL-fil,
SQL over stdin (`railway ssh` ødelegger flerlinjede argumenter), `railway unlink` etterpå.
Spørringene `q1`-`q13` ligger i sesjonens scratchpad. Ingen skriving mot prod.

Monitoren poller fortsatt read-only som regresjonsvakt: nye 400-feil, ny rute i drift, måleutfall.
Den dør når denne panen dør — den er ikke en systemd-unit, og bør ikke forveksles med en.
