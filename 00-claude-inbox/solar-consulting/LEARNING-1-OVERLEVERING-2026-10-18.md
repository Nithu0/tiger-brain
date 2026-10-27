# learning-1: samlet status og overlevering, 2026-10-18

Alt som er levert, alt som er åpent, og hva som venter på hvem. Kilder er PR-numre, commits og filer.

## Levert og merget eller klart

| Sak | Hva | Status |
| --- | --- | --- |
| SC-06 dokumentarkiv | KOFA-PDF-er med sha256/kilde/hentedato, OCR, Zotero-kode (bare litteratur), kø «dokumenter mangler» | Merget (#175). 39 KOFA-PDF-er hentet første natt, 40/natt videre. Zotero og hyyr droppet av operatør 17.10 (hyyr.json: ingen henvendelse, fremtidig konkurrent, hentes manuelt med operatørens innlogging). |
| Agentstandard | docs/agenter.md, prompts/_mal.md, REDTEAM_SYSTEM_V2 | Merget (#193). |
| 1.3 triage-vurderer | Parkert. Porten holdt ikke: spor A 8/30 vs 25/30, triage-3 15/31 vs 25/31, nei 74 % (krav 76 %) | Eval og lærdom i #250 (bare eval-filer). Koden ligger i draft #200 og skal ikke merges. |
| 2.2 red team-agent | Sitat fra kriterium og utkast, «ikke besvart» uten ordrett sitat, priskriterier utenfor, dashbord-merke «Ikke kalibrert mot nemnd» | Draft #254, flagg REDTEAM_AGENT_ENABLED av, ingen migrering. Venter på eval nivå A. |
| 1.5 gullsett | Godkjenningsark for 84 Sauda-krav | GULLSETT-1-5-GODKJENNING.md, klart for operatøren (data-1 har rettet ligaturer og 3 rader). |
| 2.5 pris og vinnsjanse | «Anbefalt tilbudspris (anslag)», spenn p20–p80 i kode, ukalibrert vinnsjanse, signal bid.price, panelet Konkurranse og kjøper | #266 markert klar, merges med PRISAGENT_ENABLED av, ingen migrering. |

## Venter på operatøren

1. **GODKJENNING.md** (crm/eval/redteam/nivaa-a/): 20 syntetiske originalsvar må godkjennes før red team-eval nivå A kan kjøres. Kostnad ≈ 2,4 USD per split med Opus 5.5 (≈ 1,2 med Sonnet), ikke 17 USD som FORHANDSREGISTRERING antok. Dev først, test én gang.
2. **GULLSETT-1-5-GODKJENNING.md**: 84 rader, ~20 min. To tolkningsrader: sauda-030 og -080. Avhenger av at data-1s ligatur-PR er merget før fasiten brukes i eval.

## Venter på signal

- **Eval 2.5 (pris):** kjøres når paal-1 melder første natts historikk (~00:30Z), og igjen etter 7 netter. Ren kode, gratis:
  `./scripts/baseline/run-triage-baseline.sh --sql prisagent-eval-export.sql --out eval/prisagent/awards-<dato>.jsonl.txt`
  `node --import tsx scripts/eval-pris-spenn.ts <fil>`
  Port: ≥ 15 beregnbare, treff ≥ forventet − 0,05 (forventet = 0,6·(n−1)/(n+1)), median bredde ≤ 1,0. Vinnsjansen er ikke målbar (0 egne utfall).
- **#254:** markeres klar etter at nivå A er kjørt (da blir det bare én CI-kjøring).

## Åpne risikoer og funn verdt å vite

- **Datagrunnlag for pris:** før historikk-sperren var det 45 pålitelige vinnerpriser og 0 egne utfall. Første versjon vil vise mye «ukjent» til historikken er inne.
- **Haiku 4.5 → 5.5** (10× billigere) og effort er infra-1s bølge 0. Funnene er sendt dit.
- **Scope-listen er feil målestokk for triage** (1.3): teamets ja er bredere enn sporene. Det bør påvirke beslutningen om de tre scopene.
- **Mitt avvik 18.10:** én `npx tsc` før node_modules var installert, som hentet npm-pakken «tsc». Den endret ingenting, og den er meldt.

## Worktrees jeg har brukt (kan ryddes når PR-ene er merget)

~/code/Veldora-sc06 (SC-06, merget), Veldora-hyyr, Veldora-agentstd, Veldora-triagevurd (#200, skal ikke merges), Veldora-triage-eval (#250), Veldora-redteam (#254), Veldora-prisagent (#266). Lokal Postgres: sc13-pg18 (127.0.0.1:55448, engangs).
