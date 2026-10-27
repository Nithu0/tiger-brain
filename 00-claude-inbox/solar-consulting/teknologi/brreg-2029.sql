BEGIN; SET TRANSACTION READ ONLY;
WITH t AS (SELECT * FROM tenders WHERE external_id IN ('2025-109967','2025-109968','2025-109969','2025-109970','2025-109972','2025-109973','2025-109974','2025-109976') AND related_tender_id IS NULL)
SELECT 'T', external_id, left(title,90), coalesce(documents_url,'-'), to_char(deadline,'YYYY-MM-DD HH24:MI') FROM t
UNION ALL
SELECT 'K', t.external_id, coalesce(e->>'kind',''), coalesce(e->>'name',''), left(regexp_replace(coalesce(e->>'description',''),'\s+',' ','g'),400)
FROM t, jsonb_array_elements(CASE WHEN jsonb_typeof(t.qualification_criteria::jsonb)='array' THEN t.qualification_criteria::jsonb ELSE '[]'::jsonb END) e
WHERE t.external_id = '2025-109972' AND (e->>'kind' = 'selection' OR (e->>'description') ~* '(skatt|register)')
ORDER BY 1, 2;
ROLLBACK;
