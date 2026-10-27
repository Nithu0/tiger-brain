-- trading-1 2026-10-27: hva DPS-ene med credit_rating/payment_defaults faktisk krever (sitat). READ-ONLY.
BEGIN; SET TRANSACTION READ ONLY;
WITH s AS (SELECT DISTINCT ON (tender_id) tender_id, data FROM signals WHERE topic = 'dps.qualifiable.shadow' ORDER BY tender_id, id DESC)
SELECT DISTINCT 'KREDITT', t.external_id, coalesce(s.data->'dps'->>'buyerName','-'), left(t.title,70), m->>'key', left(regexp_replace(coalesce(m->>'quote',''),'\s+',' ','g'),600)
FROM s JOIN tenders t ON t.id = s.tender_id, jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m
WHERE m->>'key' IN ('credit_rating','payment_defaults')
ORDER BY 2, 5;
ROLLBACK;
