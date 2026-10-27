BEGIN; SET TRANSACTION READ ONLY;
SELECT 'KAN', t.external_id, coalesce(s.data->'dps'->>'buyerName','-'), left(t.title,80), coalesce(s.data->'dps'->>'deadline','-')
FROM signals s JOIN tenders t ON t.id = s.tender_id WHERE s.topic = 'dps.qualifiable.shadow' AND s.data->>'verdict' = 'kan-soke' ORDER BY 5;
SELECT 'GAPKEY', g->>'key', g->>'blocks', g->>'unlocks', left(g->>'what',90) FROM (SELECT data FROM signals WHERE topic = 'dps.gaps.shadow' ORDER BY id DESC LIMIT 1) x, jsonb_array_elements(x.data->'gaps') g;
ROLLBACK;
