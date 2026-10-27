# 2026-10-14 — orchestrator-1 handoff

Skrevet mens dagen pågår, ikke etter. Grunnen står i `feedback_landing_gap_at_session_start`:
i går døde kontekstene med ferdig, verifisert arbeid som aldri ble landet, og røyktest-porten
lå ulandet i 14 timer før noen oppdaget det.

## Dagens tema

**To tomme kontoer på én dag, ingen av dem varslet.** Anthropic-kontoen tok ned anbud-CRM i
26 timer (siste vellykkede modellkall 13.10 08:15Z); GitHub Actions stoppet mellom 09:22:38Z og
09:50:08Z. Begge ble funnet ved flaks — den første fordi tools-1 leste en loggfil, den andre fordi
en PR tilfeldigvis ble åpnet. Mellom dem lå tre varslingsmekanismer som alle var stille.

## Landet i dag

- **Prod gjenopprettet og à jour.** 789/789 muligheter har brief; 65 briefer drenerte etterslepet.
- **Modellrutingen (#158) er bevist i drift:** haiku $0,00524 mot sonnets $0,02214 per kall, −76 %,
  $17,58 → $4,16/uke ved måleukas volum. n=65. **Driveren er svarlengden, ikke modellprisen** —
  ut-tokens falt 61 % (1802 → 700). Forbeholdet står: et 62 % kortere svar på samme skjema er en
  materielt annen brief, og ingen har sammenlignet dem. `scripts/compare-brief-models.ts` er ukjørt.
- **Destillerings-etterslepet tømt for 13.10:** 457 → 1 udestillert, 456 rader lagret.
- **PR #162 åpnet** (røyktest-porten). Rød, men bare på fakturering — ingen jobb startet.

## Premissvelt: dokumentstrategien

learning-1 målte robots.txt på alle seks portaler. **TendSign og Ivalua: `Disallow: /`** — 342
lenker, 28,9 %. EU-Supply forbyr eksplisitt `/app/docmgmt`.

Vi har behandlet «rett til å se» og «lov til å hente automatisk» som én tillatelse. Det er to.
Legitimasjonen som står som operatørgate løser ikke robots-delen. **Adapterrangeringen
(3 portaler = 67,6 %, 5 = 89,9 %) hviler på feil premiss.**

Mercell, hyyr og Artifik svarer HTTP 200 med HTML på `/robots.txt` — SPA-catch-all. En naiv parser
leser null `Disallow` som «tillatt». **Taushet som leser som samtykke.**

Åpent: ToS-laget. Godkjent for de fire uten totalforbud; TendSign og Ivalua må operatøren lese selv
i nettleser, fordi `Disallow: /` dekker vilkårssiden også.

## Rettelser — mine, og hvem som hadde rett

1. **Nøkkelen var ikke i minnekorpuset.** Jeg meldte «6 verbatim-rader i memory.db». Jeg hadde brukt
   `like '%sk-proj-%'`, som treffer prosa; alle seks var våre egne meldinger *om* nøkkelen. Med
   mønster som krever de 20+ tegnene: **0 rader i memory.db, 2 forekomster i én transkripsjonsfil.**
   infra-1 hadde sagt det riktig først («sjekket på form»), og jeg overkjørte dem med sløvere metode.
2. **De seks agentgrenene.** Min emnesammenligning sa «ikke på main» for seks av ti. admin-1 sjekket
   blob-SHA per fil: **alle seks er på main**, landet som #107–#122. Restene jeg leste som mangler
   var mains versjon som hadde gått videre (superset).
3. **`UNDECIDED`-filteret.** Jeg formulerte de 13 briefløse som om `queueWhere` var feil. admin-1:
   filteret er bevisst (PR #54, 4. okt), fem konsumenter avhenger av det. Feilen ligger i
   `brief-coverage`, som låner køens predikat som svar på et annet spørsmål.
4. **Catch-up for dager maskinen er av** finnes og virker (30d tilbakeblikk). Jeg hadde den som
   sannsynlig årsak til destilleringshullet. Den virkelige årsaken er at **delvise dager aldri
   retryes** (`nightly-distill.ts:176-182`).
5. **Bruddvinduet for GitHub.** Mitt anslag var tre timer bredt; learning-1 målte 28 minutter.
6. **Detektoren.** Jeg ba om saldo-overvåking. learning-1s forslag er bedre og tatt over mitt:
   `conclusion=failure` + `steps=[]` + `<3 s` + ingen logg fanger hele klassen uten faktureringstilgang.

## Push-gaten bærer ikke gjennom relé

admin-1 og trading-1 nektet begge å pushe på at jeg videreformidlet operatørens «ok kjør alle tre».
admin-1: «jeg har sett deg si at han sa det, ikke operatøren si det.» De har rett etter operatørens
egen baseline. trading-1 fikk senere OK kjør direkte i sin pane og pushet #162.
**Konklusjon for neste orchestrator: ikke videreformidle en push-gate. Be operatøren si det i panen.**

Og trading-1s gate var ikke formalisme: hadde de pushet før vakten var satt, hadde porten landet
**avvæpnet** — `5caae3e` tok `royktest` ut av den avledede kravlista.

## Åpne operatørgater

| Gate | Blokkerer |
|---|---|
| **GitHub Actions-fakturering** | all CI, alle PR-er, infra-1s advisory-flipp |
| «OK kjør» admin-1 (ADR-0018 `bddff83`) | — |
| «OK kjør» paal-1 (backup `fix/backup-baseline`, 3 commits) | nattlig backup-alarm siden 23.08 |
| «OK kjør» infra-1 (PR #90 `9212775`) | leak-scan |
| «OK kjør» tools-1 (`12612b4` omnigent-sporing) | — |
| «OK kjør» learning-1 (force-push `cc6b283`) | triage-grunnlinjen |
| `compare-brief-models.ts` | vet ikke om haiku-briefen holder mål |
| Kjør de 13 briefene (< 1 kr) | 7 STRONG_BID uten grunnlagsdata, 6 uten frist |
| Slett 6 landede grener + 6 worktrees | opprydding |
| ToS TendSign/Ivalua (les selv) | om dokumentstrategien har mer enn én lovlig port |

## Pågående

- **data-1:** uavgjort diagnose på den hardnakkede destilleringsraden — giftrad (validering) mot
  `max_tokens`-trunkering. Avgjøres av `stop_reason`. 51 rader over 8 delvise dager står igjen.
- **tools-1 + infra-1:** omnigent, med inngangen «kan policy-laget fange en tom konto».
- **trading-1 + learning-1:** rea. Provenans verifisert (SLSA-attestert npm, 231k ukentlige
  nedlastinger, ingen postinstall). Grense: ingen autentiserte økter, offentlige sider først.
- **admin-1 + paal-1:** heygen lukket — ingenting kan kjøre, `HEYGEN_API_KEY` mangler og det finnes
  ingen MCP-verktøy. Anbefaling: velg transport først (MCP/OAuth), kostnadsanslag per render.

## Regel som kom ut av dagen

Et søk som ikke traff er ikke et fravær, og en kanal som ikke sier noe er ikke en rolig natt.
Fem av dagens rettelser har samme form: noe stille ble lest som noe fraværende.
