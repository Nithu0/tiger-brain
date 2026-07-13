# GPU + læringsloop-leveranse — 2026-07-11 (ai-1)

Operatør-ordre: «sjekk hele læringsloopen, alt koblet til GPU, lærer kontinuerlig, håndterer data godt, 80/20-dokumentene, RAG». Alt under er merget til main (`5b367f7`), CI grønt per PR, adversarielt reviewet (funn fikset før merge).

## Merget (PR #228–#234)

| PR | Hva | Effekt uten flagg |
|---|---|---|
| #228 | Worker llm-router: `local` GPU-provider først i alle task-kjeder | Ingen (behavior-neutral, bevist i test) |
| #229 | HLE dataset-builder (P2.8): kronologisk 80/20 + purge/embargo, manifest m/ config-hash, Kish n_eff, LOW_N-stempel | Ingen (HLE_DATASET_ENABLED off) |
| #230 | sample_size teller trades; soft-log-gates skriver evidens (default ON, ren observability, fire-and-forget); foundation Rule-4 un-deadlocked | gate_decisions begynner å populeres |
| #231 | Kadens-bevisst heartbeat (windowState+nextDelayMs) + /health-toleranse | Helge-kadens mistolkes aldri som stall igjen |
| #232 | RAG: bge-m3-embeddings på GPU + hybrid FTS/vektor-retrieval (RRF), provider/model/dim-guard | Ingen (vector-flagg off) |
| #233 | Læringsdata-korrekthet: correct-label-kvadranter fikset, no-trade-forgiftning ute av accuracy, trainer-features var konstant 0 → ekte features + train/serve-paritet | Neste meta-label-trening er første med reell featureinfo |
| #234 | Firm-agents → GPU (rebased #211 + hardening: /no_think, finish_reason, CoT kan aldri persisteres) | Ingen (FIRM_LOCAL_AGENTS tom) |

## OPERATØR-HANDLINGER (jeg flipper aldri Railway selv)

### 1. GPU-aktivering — Railway env

**API-service** (0 kodeendring trengtes — ruting fantes):
```
LOCAL_LLM_BASE_URL=http://194.14.47.19:22631
LOCAL_LLM_API_KEY=<GPU-token>
```
→ jarvis-ask, jarvis-brief, HLE deep-answer, narrative, intelligence, command-room, cockpit på GPU.

**Worker-service** (nytt fra #228/#234/#232):
```
LOCAL_LLM_BASE_URL=http://194.14.47.19:22631
LOCAL_LLM_API_KEY=<GPU-token>
# valgfritt: LOCAL_LLM_MODEL=qwen3:8b  LOCAL_LLM_TIMEOUT_MS=10000
FIRM_LOCAL_AGENTS=daily-journal,fill-quality,operator-brief
# RAG (kan vente til embeddings er backfillet):
EMBEDDING_PROVIDER=local
KNOWLEDGE_VECTOR_RETRIEVAL_ENABLED=true
```
→ sentiment (~500 kall/dag), briefing, postmortem, trade-review, market-pulse + 3 ikke-penge-agenter på GPU, med automatisk Anthropic-fallback. NB dashboard-chief bruker `LOCAL_LLM_TOKEN` + base MED `/v1` — annen konvensjon, ikke rør den.

Verifisering etter flip: `SELECT provider, count(*) FROM prompt_log WHERE created_at > now()-interval '1 day' GROUP BY 1` (provider='local' skal dukke opp) + `model_used` i journal-artifacts.

### 2. One-shot SQL-er (ROLLBACK-default, kjør preview først)
- `scripts/oneshot/2026-06-30_flag-185r-label-outlier.sql` (fortsatt ukjørt)
- `scripts/oneshot/2026-07-11_relabel-engine-correct.sql` (historiske inverterte correct-labels)
- `scripts/oneshot/2026-07-11_reset-inflated-lesson-sample-size.sql` (run-inflaterte sample_size)

### 3. Karri-lane (uendret gated)
- SAFE_AUTO_APPLY / lesson-injection / model-output-consumer / lesson-clustering-defragmentering (entry_hour i GROUP BY) — forslag ligger i evidensgrunnlaget til thesis-2; M2-fixen i #233 (nøytral 0.5 + trade-only minSamples) gjør RECOMMEND_ONLY-rapportene ærlige i mellomtiden.

## Prod-status
- «Kadens-kollapsen» 10.07 → IKKE incident: designet helgekadens (WEEKEND=3600s, BST). Normaliserer søndag ~21 UTC. #231 gjør dette synlig for alltid.
- HLE-catchup kjører fra ai-1s maskin (import var i shadow_forward_test-backloggen 14:52Z — kilden som mater counterfactual/no-trade-labels). label→cf→profile→eval følger.
- Postmortem-backlog: 11 trades fra 29.06–02.07 er nå utenfor 7-dagersvinduet — backfilles ikke automatisk; trenger beslutning (utvid vindu midlertidig eller la ligge).
- Meta-label train-cron: misset 10.07/11.07 — sjekkes etter helgen når kadens normaliserer; #233 gjør uansett neste trening til den første med ekte features.

— ai-1
