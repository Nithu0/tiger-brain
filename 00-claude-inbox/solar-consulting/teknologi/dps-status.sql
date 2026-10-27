-- trading-1 2026-10-27: siste dps.qualifiable per DPS (DPS-motoren) og siste dps.gaps. READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH s AS (
  SELECT DISTINCT ON (tender_id) tender_id, data, created_at FROM signals WHERE topic = 'dps.qualifiable' ORDER BY tender_id, id DESC
)
SELECT 'DPS', t.external_id, coalesce(s.data->'dps'->>'deadline','-'), s.data->>'verdict', coalesce(s.data->'dps'->>'buyerName','-'), left(t.title, 90),
  coalesce((SELECT string_agg(DISTINCT m->>'key', ',') FROM jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m), '-'),
  coalesce((SELECT string_agg(DISTINCT c->>'name', ' / ') FROM jsonb_array_elements(s.data->'categories') c), '-'),
  to_char(s.created_at,'YYYY-MM-DD')
FROM s JOIN tenders t ON t.id = s.tender_id
WHERE coalesce(s.data->'dps'->>'deadline','9999') >= to_char(now(),'YYYY-MM-DD')
UNION ALL
SELECT 'GAPS', to_char(created_at,'YYYY-MM-DD'), left((data->'gaps')::text, 1500), '', '', '', '', '', '' FROM (SELECT * FROM signals WHERE topic = 'dps.gaps' ORDER BY id DESC LIMIT 1) g
ORDER BY 1, 3;
ROLLBACK;
