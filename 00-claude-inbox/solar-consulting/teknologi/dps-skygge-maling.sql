-- trading-1 2026-10-27: første skyggekjøring av dps-assess (jobb 32030). READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
SELECT 'JOBB', id::text, coalesce(completed_at::text,'-'), coalesce(has_error::text,'-'), coalesce(processing::text,'-'), '', '' FROM payload_jobs WHERE id = 32030
UNION ALL
SELECT 'RUN', ar.id::text, ar.status::text, left(coalesce(ar.message,''), 400), coalesce(ar.items_in::text,'-'), coalesce(ar.items_out::text,'-'), coalesce(ar.duration_ms::text,'-')
FROM agent_runs ar WHERE ar.agent = 'dps-assess' AND ar.started_at > now() - interval '3 hours'
UNION ALL
SELECT 'TOPIC', topic, count(*)::text, '', '', '', '' FROM signals WHERE topic LIKE 'dps.%' GROUP BY topic
UNION ALL
SELECT 'IT17', t.external_id, s.data->>'verdict', coalesce((SELECT string_agg(DISTINCT m->>'key', ',') FROM jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m), '-'), left(t.title,70), '', ''
FROM signals s JOIN tenders t ON t.id = s.tender_id
WHERE s.topic = 'dps.qualifiable.shadow' AND t.external_id IN ('2022-962877','2026-106810','2025-103853','2022-318980','2022-343586','2022-353024','2025-118721','2024-106681','2025-101755','2024-105583','2025-112751','2025-111353','2026-105761','2026-112986','2025-116151','2022-374835','2025-104594')
UNION ALL
SELECT 'VERDICT', s.data->>'verdict', count(*)::text, '', '', '', '' FROM signals s WHERE s.topic = 'dps.qualifiable.shadow' GROUP BY 2
UNION ALL
SELECT 'GAPS', to_char(created_at,'HH24:MI'), left((data->'gaps')::text, 1800), '', '', '', '' FROM (SELECT * FROM signals WHERE topic = 'dps.gaps.shadow' ORDER BY id DESC LIMIT 1) g;
ROLLBACK;
