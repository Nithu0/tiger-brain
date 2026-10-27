-- trading-1 2026-10-27: hva «narrative» og andre mangler i skyggevurderingene gjelder (kravtekst og sitat), og kandidater for 10 menneskelige kontroller. READ-ONLY.
BEGIN; SET TRANSACTION READ ONLY;
WITH s AS (SELECT s.id, s.tender_id, s.data FROM signals s WHERE s.topic = 'dps.qualifiable.shadow')
SELECT 'MISS', t.external_id, m->>'key', left(regexp_replace(coalesce(m->>'what',''),'\s+',' ','g'),160), left(regexp_replace(coalesce(m->>'quote', m->>'requirement', m->>'text',''),'\s+',' ','g'),320), (SELECT string_agg(k,',') FROM jsonb_object_keys(m) k)
FROM s JOIN tenders t ON t.id = s.tender_id, jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m
WHERE s.data->>'verdict' = 'mangler'
UNION ALL
SELECT 'ALL', t.external_id, s.data->>'verdict', coalesce(s.data->'dps'->>'buyerName','-'), left(t.title,90), coalesce(s.data->'dps'->>'deadline','-')
FROM s JOIN tenders t ON t.id = s.tender_id
ORDER BY 1, 2;
ROLLBACK;
