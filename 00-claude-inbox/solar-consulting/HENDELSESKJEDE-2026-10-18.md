# Hendelseskjeden: trigger → jobb, finnes/mangler (2026-10-18)

data-1, oppdrag fra orchestrator-1. Kode: origin/main (krav-worktree). Prod: read-only, siste 7 dager
(`crm/scripts/baseline/hendelseskjede-7d.sql`, agent_runs-telling). Bare antall.

## Tabell

| # | Trigger | Jobb | I koden | Gating i dag | Prod 7 d |
|---|---|---|---|---|---|
| A1 | Ny/endret kunngjøring (ingest) | classify | FINNES `lib/tenders/ingest.ts:66` | ny eller endret hash | classify ok 967, ingest-doffin 287, ingest-ted 168 |
| A2 | classify | mulighet opprettes (fit, scope) | FINNES `classify.ts:145-157` | fit < 20 → vertical none | 463 nye muligheter, 59 scope-treff |
| B | classify, «relevant» | extract-requirements (kravagenten) | FINNES `classify.ts:59` | **bare fit ≥ 40, scope brukes ikke** | 54 utenfor scope med fit ≥ 40 fikk uttrekk (veiarbeid). 22 scope-treff med fit < 40 fikk ikke |
| C | assess-requirements | tender-brief | FINNES `assess-requirements.ts:130` + cron brief-coverage | fit ≥ 40 eller i spill | 59/59 scope-treff har brief |
| D0 | Beslutning I/B/SB (menneske) | hooks på opportunities | DELVIS `Opportunities.ts:54` | — | 20 muligheter |
| D1 | Beslutning | hent konkurransegrunnlag | **MANGLER** (finnes ingen hentejobb. dokumentarkiv henter bare KOFA, dokumentlos melder bare «last opp») | — | 0/20 har tender-dokument. 19/20 har dokumentløs-signal. De 77 dokumentene er KOFA |
| D2 | Beslutning | extract-requirements / kravagent hvis ikke kjørt | **MANGLER** | — | 11/20 har kravrader, 2/20 kravagent-rader |
| D3 | Beslutning | kjøperresearch | FINNES som timesjobb `registry.ts:196`, ingen kobling nødvendig | KJOPERRESEARCH_ENABLED (av) | 0/20, kjoperresearch skipped 6 |
| D4 | Beslutning | assess → qualify | **MANGLER på beslutning** (finnes på status → screening/analysing/bidding, `assessOnPlay.ts:17`) | status, ikke beslutning | 5/20 har kvalifikasjonsvurdering |
| D5 | Beslutning | konkurranse-grunnlag | FINNES `competitionOnDecision.ts:20` | COMPETITION_AGENT_ENABLED, bare ved inngang | 19/20 |
| E | Dokument lastet opp | extract-requirements (kravagenten leser alle dokumentene) | FINNES `Documents.ts:37-76` | ikke evidence/kofa/literature. **ingen relevans- eller duplikatsjekk** | ingen tender-opplasting i perioden |
| F | extract → assess → score/brief/qualify | FINNES `extract-requirements.ts:104`, `assess-requirements.ts:126-133` | | assess ok 229 / failed 45 (14.10), qualify ok 336 |

Duplikater: extract-requirements, assess-requirements, score og tender-brief køes med `payload.jobs.queue` uten sjekk av
ventende jobb (bare qualify, requalify, brief-coverage og dokumentlos sjekker `pendingJobWhere`).

Utenfor oppdraget, men synlig i agent_runs: sync-workspace failed 480/523 og email-digest failed 32 siste 7 d.
