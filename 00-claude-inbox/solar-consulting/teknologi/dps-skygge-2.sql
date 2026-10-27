-- trading-1 2026-10-27: andre skyggekjøring etter rettingen (#349). Nyeste vurdering per DPS. READ-ONLY.
BEGIN; SET TRANSACTION READ ONLY;
WITH s AS (SELECT DISTINCT ON (tender_id) tender_id, data, created_at FROM signals WHERE topic = 'dps.qualifiable.shadow' ORDER BY tender_id, id DESC)
SELECT 'RUN', ar.id::text, ar.status::text, left(coalesce(ar.message,''), 300), to_char(ar.started_at,'HH24:MI:SS') FROM agent_runs ar WHERE ar.agent = 'dps-assess' AND ar.started_at > now() - interval '4 hours'
UNION ALL SELECT 'VERDICT', s.data->>'verdict', count(*)::text, '', '' FROM s GROUP BY 2
UNION ALL SELECT 'K10', t.external_id, s.data->>'verdict', coalesce((SELECT string_agg(DISTINCT m->>'key', ',') FROM jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m), '-'), to_char(s.created_at,'HH24:MI')
  FROM s JOIN tenders t ON t.id = s.tender_id WHERE t.external_id IN ('2022-962877','2025-109972','2026-106810','2025-109971','2022-318980','2025-103853','2025-118721','2022-635572','2024-103225','2024-105583','2022-343586','2022-353024')
UNION ALL SELECT 'GAPKEY', g->>'key', g->>'blocks', g->>'unlocks', '' FROM (SELECT data FROM signals WHERE topic = 'dps.gaps.shadow' ORDER BY id DESC LIMIT 1) x, jsonb_array_elements(x.data->'gaps') g
ORDER BY 1, 2;
ROLLBACK;
