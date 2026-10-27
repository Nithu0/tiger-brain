# Handoff 2026-10-13 — admin-1: fristene, terskelen og en ubesvart AS-frist

Rolle i dag: Legal & Regulatory Analyst i Veldora-strategirådet, deretter bølge 1.
Ingenting pushet. Ingen prod-endringer. Ingen modellkall i det jeg bygget.

## Gren `admin-1/terskel-frist` (worktree `~/code/Veldora-frist`), i rekkefølge

1. `dc88a2f` — terskelverditabell som data + `vurderPart` + norsk helligdagskalender.
2. `9318c83` — `deadline.mismatch` sendes faktisk ut, og nedtellingen innrømmer tvil.
3. `d243acf` — helgeadvarselen på karensfristen navngir dagen og vises bare når den gjelder.

Venter «OK kjør». Rekkefølgen er bare kronologisk; commitene er uavhengige.

## Siste bevis før landing (gjort, ikke antatt)

- `vitest run` i `projects/anbud/crm`: **2615/2615**, exit 0, kjørt åtte ganger.
- `npx tsc --noEmit`: rent.
- `node scripts/validate.mjs`: 60 filer / 16 schemas, alt gyldig.
- Én kjøring viste `1 failed | 2614 passed` som ikke reproduserte i åtte påfølgende. Testen ble
  aldri identifisert. `ANTAKELSE`: last på maskinen. **Suiten har minst én test som kan feile under
  last** — melder CI én rød test uten at noe er endret, er det antakelig denne, og
  `--reporter=junit` til fil er raskeste vei til navnet.

## Det viktigste funnet i dag

`compareDeadlines` har flagget at kunngjøring, TED-tvilling og konkurransegrunnlag oppgir ulik
tilbudsfrist hele tiden. Signalet ble emittert som `ALERT` (`tender-brief.ts:200`) og vist i
innboksen (`inbox.ts:26`) med severity `high` — og **sendt til ingen**, fordi `deadline.mismatch`
manglet i `IMMEDIATE_TOPICS` (`notify-email.ts:22`). Samtidig e-postes og Slack-es `deadline.soon`,
som teller ned fra `tenders.deadline` alene.

Fellen: topicen alene var ikke nok. `immediateItem` har `default: return null`, så signalet ble
hentet og deretter droppet. Begge halvdelene måtte på plass, og testen dekker begge — den feiler på
hver av dem alene.

Dette er samme mønster som gikk igjen hos alle i dag: bygget riktig, koblet til ingenting.

## Operatør-gater (ingen av dem kan jeg lukke)

1. **AS, tidskritisk.** Syv MVA-terminer pluss skattemelding næring 2025 står som *uverifisert
   levert* — ikke som ikke levert. Termin 4/2026 hadde frist **12.10.2026**, i går, uten spor av
   forberedelse etter 19.08. `AS/docs/kapitalprioritering.md:29` behandlet 5/2025 + 6/2025 + 1/2026
   som **forfalt** alt 01.06.2026, med renter og mulkt, som steg 1 i kapitalvannfallet. Spørsmålet
   er smalt: ble juni-opprydningen gjennomført, og er termin 3 og 4 levert? Én innlogging på
   skatteetaten.no → «Mva-melding» → innsendte meldinger svarer på alt. Beløp ligger lokalt i
   `AS/docs/fiken-avstemming.md`, ikke her.
2. **Brain-synk.** `00-firm-bus/feed.md` er sporet, men `agents/**` og `inbox/**` er usporet OG
   ikke gitignorert. Det eneste som holder rollefiler ute av det delte repoet er at ingen har kjørt
   `git add -A`. Forslag: legg begge i `.gitignore`. Og ta et bevisst valg på `06-AS`, som synker
   mens `07-personlig` er ignorert.
3. **To juristgater i koden**, begge som navngitte konstanter slik at svaret endrer ett sted:
   `LIK_TERSKEL_ER_OVER` (er verdi lik terskelen over eller under?) og `FRIST_REGEL.hjemmel`
   (forlenges en frist som faller på helg eller helligdag?). Terskeltabellen er tom til juristen
   fyller den — `financial-capacity.md:915` forbyr å kopiere verdiene inn i en mal, og §9 i samme
   dokument dokumenterer et hentelag som diktet opp FOA §§ 16-1 til 16-10.

## Åpne tråder som har eier

- **Dashboard-nedtellingen** har ingen eier. Fiksen min er halv uten den: spriket går på e-post og
  sveipet sier «kildene spriker om datoen», men en bruker som leser en frist i grensesnittet ser
  fortsatt et tall uten forbehold. Jeg tilbød meg å ta den 16:45, ubesvart.
- **De tre ADR-ene** er mine og venter på operatør-grillingen. Den for terskel/frist henger ikke på
  noe valg og kan skrives når som helst. Den for datapolicy fail-closed dokumenterer en beslutning
  infra-1 alt har levert i bølge 0, og må ta motargumentet: PERMISSIVE var operatørvalg 08.10, og
  fail-closed kan stoppe 52 tasks og 34 cron ved DB-trøbbel i en produksjon som brukes live.
- **`mva-skatt-action.md:21`** har 30 708 for termin 2/2026. Det er et anslag fra 01.06; Fiken-
  avstemmingen 19.08 har det riktige tallet med komponenter. Bør merkes foreldet.
- **Kollisjonsmønsteret**: tre av åtte roller mistet arbeid i dag fordi dispatchen navngir én
  rapportsti uten eier. Orchestrator-1 satte regelen `..._<rolle>-pane.md` for synlige paner kl.
  10:40. Den kom etter at admin-1, infra-1 og learning-1 alt hadde kollidert.

## Rettelser jeg gjorde i eget arbeid, så de ikke må finnes på nytt

- Trakk mitt eget råd om å ta `tilbudsfrist` ut av briefen. tools-1 hadde rett: det ville slettet
  den ene kryssjekken som fanger at konkurransegrunnlaget oppgir en annen frist enn kunngjøringen.
- Koblingen orchestrator-1 laget mellom tools-1 og meg bygde på to ulike filer med samme navn:
  `klage/deadlines.ts` (klagefrister, min) og `lib/deadlines.ts` (tilbudsfrist, tools-1 sin).
- To av mine tre «største svakheter» i runde 1 var superseded av den headless executoren:
  kildeklasse-separasjonen ER strukturell (`SeOgsaa.tsx` demper og `noPrint`-er, skjemaet sperrer
  `ref.url` til robertmyhre.no), og Lovdata-korpuset er åpne NLOD-data — det er kilderaden
  `data/sources/lovdata.json` som er utdatert.
- Jeg tok feil om `kvalitetssystem` i learning-1s nøkkelord: 5 treff, 4 i tittel, altså godt belagt.
  Jeg hadde rett om `saksbehandling`, `internkontroll` og `befaring`, og om at `RFI` matcher inne i
  `RFID` fordi mønstrene mangler ordgrenser.
