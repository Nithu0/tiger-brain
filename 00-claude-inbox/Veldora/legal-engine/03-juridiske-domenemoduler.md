# Juridiske domenemoduler — klage/qualification/tilbud (kodekartlegging)

Repo `Veldora-frist`, `projects/anbud/crm/src/lib/{klage,qualification,tilbud}`. Les-only, bevis = fil:linje.
`I DRIFT` her betyr "importert av en registrert endpoint/collection" (kode-wiring), IKKE prod-kjøring —
ingen DB-tilkobling er brukt (bindende regel). `KODE` = finnes, ikke sporet til et endpoint i denne runden.

## Tabell — juridiske funksjoner

| Funksjon | fil:linje | Hva den avgjør | Det./LLM | Hjemmel | Status |
|---|---|---|---|---|---|
| `karensVurdering` | klage/karens.ts:86 | Karensfrist + handlinger, avrop-unntak | Deterministisk | FOA (ingen § — ASSUMPTION, KOFA-praksis) | I DRIFT (klage/view.ts→endpoints/klage.ts) |
| `klageDeadlines`/`karens/forfoyning/kofa/sanksjon` | klage/deadlines.ts:118,46,73,93,103 | Beregner karens/forføyning/KOFA/sanksjon-datoer fra korpus | Deterministisk | FOA/LOA/Klagenemndforskriften via `pickLaw` | I DRIFT |
| `pickLaw`/`lawRefOf`/`loadKlageLaw` | klage/law.ts:97,155,172 | Finner/siterer rettskildechunks pr. behov (tittel/tekst-match, ikke §-hardkoding) | Deterministisk | FOA/LOA/OFFL/Klagenemndforskriften (DB-korpus) | I DRIFT |
| `innsynDraft` | klage/innsyn.ts:35 | Setter opp innsynsbegjæring m/hjemmel | Deterministisk | OFFL §3 + unntak, FOA | I DRIFT (endpoints/klage.ts) |
| `buildInnsynDocx`/`innsynFileName` | klage/innsynDocx.ts:114,118 | .docx av innsynsutkast | Deterministisk | — | I DRIFT (`GET .../klage/innsyn.docx`) |
| `salamieffekt` | klage/salami.ts:54 | Status ingen/under-grensen/ukjent/mulig/klagekandidat | Deterministisk (sum/%/terskel) | FOA §28-1 (ASSUMPTION) | I DRIFT |
| `registerRader`/`erKontraktsendring` | klage/salami.ts:198,179 | Doffin-varsel → salami-rad (verdi alltid null) | Deterministisk | — | I DRIFT |
| `avvisningspaastandStyrke` | klage/avvisning.ts:150 | Styrke på «skulle vært avvist»-påstand (bare `svak` ved fleksibelt krav) | Deterministisk | FOA §9-6/§24-8 (ASSUMPTION) | I DRIFT (endpoints/klage.ts:43) |
| `extractEvaluation` | klage/evaluation.ts:117 | Leser tildelingsbrev → poeng/vinner/pris | **LLM** (`extract.award`) | — | I DRIFT |
| `validateEvaluation` | klage/evaluation.ts:66 | Godkjenner LLM-tall bare når sitat finnes verbatim i dok | Deterministisk verifisering | — | I DRIFT |
| `klageRules`/`finalizeKlage` | klage/compare.ts:113,269 | Genererer/styrkesetter klagefunn (ukjente kriterier, regnefeil, mangelfull begrunnelse, unormalt lavt) | Deterministisk (mønster + regnestykke) | Pr. finn, via `pickLaw` | I DRIFT |
| `klageDraft`/`kofaNote` | klage/draft.ts:22,54 | Setter sammen klagebrev fra valgte funn | Deterministisk | Sitert fra funnenes `law[]` | I DRIFT |
| `buildKlageView`/`findCase` | klage/view.ts:141, klage/store.ts:49 | Samler data→visning (ingen ny regel) | Deterministisk (orkestrering) | — | I DRIFT |
| `clarificationDrafts`/`causeOf` | qualification/clarify.ts:114,73 | Avklaringsspørsmål-tekst fra REVIEW/UNKNOWN-årsak | Deterministisk (maler) | — | I DRIFT |
| `BRIEF_FACT_QUESTIONS` | qualification/clarify.ts:100 | 3 faste spørsmål (vedståelsesfrist/kontraktstype/-start) når brief mangler fakta | Deterministisk mal | — | I DRIFT |
| `guardClarification` | qualification/clarify.ts:243 | Skrivevakt: agent kan aldri godkjenne/sende | Deterministisk | — | I DRIFT |
| `sjekkUnderleverandorer`/`sjekkRad` | qualification/underleverandor.ts:185,157 | ok/warn/fail pr. underlev.-rad mot bevismal | Deterministisk (regex+regler) | FOA §16-10/§19-3/§24-2 (ASSUMPTION) | I DRIFT (endpoints/tilbud.ts, endpoints/qualification.ts, BidDrafts.ts) |
| `financialThresholds` | qualification/financial.ts:105 | Omsetning/egenkapital/resultat-krav → evidence-rad | Deterministisk (regex) | — (kobles mot Brreg-regnskap) | I DRIFT |
| `llmClassifier` | qualification/llmClassifier.ts:45 | Kategoriserer krav når ingen keyword-regel traff | **LLM** (Jev/TypeSafe `judge.classify` → Claude-fallback) | — | I DRIFT |
| `classifyByRules`/`classifyRequirement` | qualification/classify.ts:44,108 | Presedens: human > regel > lagret LLM > LLM > OTHER_UNCLASSIFIED | Hybrid (regel først, LLM-port kun om ingen treff) | — | I DRIFT |
| `requalifyFingerprint`/`planRequalify` | qualification/requalify.ts:62,122 | sha256 av alt som kan endre utfall → kø ny vurdering | Deterministisk | — | I DRIFT |
| `expiryAlertItems`/`expiryAlertChanged` | qualification/requalify.ts:145,150 | Varsel når bevis utløper før frist, in-play | Deterministisk | — | I DRIFT |
| `readiness` | qualification/readiness.ts:82 | PASS/REVIEW/UNKNOWN/FAIL → %, grupper, risiko | Deterministisk (aggregering, **ikke** juridisk kvalifikasjonsvedtak jf. fil-header) | — | I DRIFT |
| `runChecks` | qualification/checks.ts:198 | Observert vs. forventet bevis → PASS/FAIL/REVIEW pr. krav | Deterministisk | — | I DRIFT (engine.ts) |
| `guardJudgement` (semanticJudge) | qualification/semanticJudge.ts:29 | Lar LLM-dom telle bare for sitater faktisk vist til modellen | Deterministisk vakt rundt LLM | — | I DRIFT |
| `judge.semantic`/`extract.threshold` | qualification/semanticJudge.ts:90,98 | Skjønnskrav og tall-tolkning fra kravtekst | **LLM** | — | I DRIFT |
| `llmFailJudge` | qualification/failJudge.ts:26 | Andre-kontroll: bekrefter/avkrefter regelmotorens FAIL | **LLM** (`judge.fail-check`) | — | I DRIFT |
| `detectLimits`/`sectionLimitStatus` | tilbud/grenser.ts:107,178 | Ord/sidegrense funnet i dok + overskridelse | Deterministisk (regex/estimat) | KOFA 2020/410 m.fl. (ASSUMPTION) | I DRIFT (checklist.ts) |
| `parsePriceSheet`/`checkPriceSheet` | tilbud/prisskjema.ts:178,249 | Summeringsfeil i prisskjema | Deterministisk (aritmetikk) | FOA §23-5 (ASSUMPTION) | I DRIFT (checklist.ts) |
| `sectionMiljoStatus` | tilbud/miljo.ts:140 | Uforpliktende/ikke-tallfestet/sertifikat-uten-bevis | Deterministisk (ordlister) | FOA §15-3(2)b/§18-1 (ASSUMPTION) | I DRIFT (checklist.ts) |
| `checkKeyPersons` (avklaring) | tilbud/avklaring.ts:127 | Dobbel nektelse/åpner for endring/nytt innhold i avklaringssvar | Deterministisk (ordlister) | FOA §23-3(2)/§23-5/§24-8 (ASSUMPTION) | I DRIFT (checklist.ts) |
| `analyseEndringsklausuler`/`deMinimis` | tilbud/endringer.ts:126,65 | Klar/uklar endringsklausul, salami-ordlyd, de-minimis-grense | Deterministisk (regex+%) | FOA §28-1/§28-2/§11-2 (ASSUMPTION) | I DRIFT (klage/salami.ts bruker `DE_MINIMIS_PCT`; endpoints) |
| `buildChecklist` | tilbud/checklist.ts:110 | «Klar til innlevering» — fail/warn/ok samlet fra alle moduler over | Deterministisk (orkestrering) | — | I DRIFT |
| `detectContractBasis`/`fallbackFlags`/`verifyFlags` | tilbud/contract.ts:60,282,317 | Kontraktstype (SSA/NS84xx), nøkkelord-flagg uten LLM, sitatkontroll av LLM-flagg | Deterministisk (regex + verifisering) | — | I DRIFT; **LLM-delen** (selve flagg-genereringen, `contractSchema`/`CONTRACT_SYSTEM`) ligger i `jobs/tasks/contract-review.ts` — utenfor lib-scopet |
| `guardSection` | tilbud/status.ts:179 | Statusmaskin seksjon (draft→legal-review→legal-ok→approved), nullstiller felt agent ikke kan sette | Deterministisk | — | I DRIFT |
| `isAuthorisedSignatory`/`mergeSignatories` | tilbud/signatories.ts:28,39 | Hvem kan signere/binde selskapet | Deterministisk (admin-styrt liste) | — | I DRIFT |
| `buildBidDocument`/`buildBidDocx` | tilbud/docx.ts:63,134 | .docx av tilbudsutkast m/status, flagg, forbehold | Deterministisk | — | I DRIFT |
| `vurderPart` (nevnt i brief, **utenfor scope**) | `lib/legal/terskel.ts:99` | Del II/III-vurdering | Deterministisk | — | **UWIRET** — kun `legal/terskel.test.ts` importerer den (`grep -rn "vurderPart" --include=*.ts .` → 1 treff i prod-kode = funksjonsdefinisjonen selv) |

## 1. Regnestykke vs. modell — grensen per modul

- **klage**: alt er regnestykke/mønstergjenkjenning (`klageRules`, `salamieffekt`, `karensVurdering`, `deadlines.ts`). Eneste modell: `extractEvaluation` (klage/evaluation.ts:117, `extract.award`) leser tildelingsbrevet; resultatet må siteres verbatim i dokumentet (`validateEvaluation`, linje 66) før det brukes i noen regel.
- **qualification**: `classifyRequirement` (classify.ts:108) er regel først; LLM (`llmClassifier.ts:45`, `judge.classify`) kjører **bare** når ingen keyword-regel traff. `checks.ts`/`engine.ts`/`readiness.ts` er 100 % regnestykke. To ekstra LLM-porter: `judge.semantic`/`extract.threshold` (semanticJudge.ts) for skjønnskrav, `judge.fail-check` (failJudge.ts) som andre-kontroll av et regelmotor-FAIL — begge er porter inn i en ellers deterministisk motor, ikke motoren selv.
- **tilbud**: alt i `lib/tilbud/*` er regnestykke/ordlister (grenser, prisskjema, miljø, avklaring, endringer, avvik, checklist, status, signatories, docx). Unntaket er kontraktsgjennomgang: `jobs/tasks/contract-review.ts` (utenfor scope) kjører selve LLM-kallet (`contractSchema`, `CONTRACT_SYSTEM`); `lib/tilbud/contract.ts` leverer bare deterministisk kontraktstype-gjetting, fallback-flagg uten LLM og etterverifisering av LLM-sitater.

## 2. Hjemmelsreferanser i utdata

Feltene `law: LawRef[]` og `lawMissing: string[]` finnes på `KlageDeadline` (deadlines.ts:20-21), `KlageFinding` (compare.ts:79-80), `InnsynDraft` (innsyn.ts:20) og brukes av `klageDraft`/`kofaNote`. Når hjemmelen ikke finnes i korpuset, settes `lawMissing` til `NEED_LABEL[...]` (law.ts:44-57) og teksten viser en synlig plassholder: `MISSING_BASIS = '[Hjemmel mangler i rettskildekorpuset — juristen fyller inn]'` (innsyn.ts:17, gjenbrukt draft.ts:28). Ingen hjemmel blir aldri diktet — `pickLaw` returnerer tom liste, aldri en gjetning (law.ts:97-144).

## 3. Uwiret

Alle eksporterte moduler i `klage/`, `qualification/`, `tilbud/` har minst én importør utenfor sin egen testfil (verifisert med grep pr. fil — ingen traff 0). Det kjente eksempelet fra brief, **`lib/legal/terskel.ts` → `vurderPart`** (linje 99), ligger derimot **utenfor** scopet mitt og er uwiret: `grep -rn "vurderPart" --include=*.ts .` gir bare treff i `legal/terskel.test.ts` og definisjonen selv — ingen endpoint, hook eller annen modul kaller den.

## 4. Navngitte antakelser (ANTAKELSE/UKJENT/ASSUMPTION) — juristen bekrefter

- klage/karens.ts:5,36,47,49,77,81,96,98 — hele karensregelen inkl. avrop-unntak
- klage/deadlines.ts:25,49,96 — fridag-forskyvning (peker til `legal/helligdager.ts:107 FRIST_REGEL`, `:127`), avvisnings-karens, KOFA-frist ukjent
- klage/salami.ts:3,85,90,91 — FOA §28-1, KOFA-saker, reduksjon≠direktekjøp
- klage/avvisning.ts:4,28,38,45 — avvisningsklasse→styrke
- qualification/underleverandor.ts:4,95,108,119,221 — hele underlev.-regelen + 4 ordlister
- qualification/classify.ts:24 — Russland-sanksjon som nasjonal avvisningsgrunn (2026-10-06, issue 013)
- tilbud/grenser.ts:4 — ord/sidegrense-praksis
- tilbud/avklaring.ts:4 — avklaringssvar-regelen
- tilbud/miljo.ts:4 — miljøbesvarelse-regelen
- tilbud/prisskjema.ts:4 — prisskjema-regelen
- tilbud/avvik.ts:4,137,148 — avvisningsklasse-vesentlighet
- tilbud/endringer.ts:4,51,72,77,94,100,103,108,180 — hele endringsklausul/salami/de-minimis-regelen
- tilbud/checklist.ts:317, tilbud/sections.ts:283, tilbud/contract.ts (header) — avledede ASSUMPTION-merknader
- `legal/terskel.ts:52,59` (`LIK_TERSKEL_ER_OVER`, `PERIODE_AVGJORES_AV`) og `legal/helligdager.ts:107` (`FRIST_REGEL`) — utenfor scope, men konsumert av `klage/deadlines.ts`
