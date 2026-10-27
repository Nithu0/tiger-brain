BEGIN; SET TRANSACTION READ ONLY;
WITH t AS (SELECT * FROM tenders WHERE external_id = '2025-109755' AND related_tender_id IS NULL)
SELECT 'T', to_char(deadline,'YYYY-MM-DD HH24:MI'), coalesce(documents_url,'-'), left(regexp_replace(coalesce(description,''),'\s+',' ','g'), 900) FROM t
UNION ALL SELECT 'K', coalesce(e->>'name',''), '', left(regexp_replace(coalesce(e->>'description',''),'\s+',' ','g'),500)
FROM t, jsonb_array_elements(CASE WHEN jsonb_typeof(t.qualification_criteria::jsonb)='array' THEN t.qualification_criteria::jsonb ELSE '[]'::jsonb END) e
WHERE e->>'kind' = 'selection' AND length(coalesce(e->>'description','')) > 0
  AND (e->>'description') !~* '^(Følgende utdanning|Leverandørens \("totale"\)|Leverandørens gjennomsnittlige|Er leverandørens|Hvis opplysningene|Bare for tjenester|Leverandør kan anvende|Er leverandøren i stand|Attester utstedt)'
UNION ALL SELECT 'S', s.data->>'verdict', '', coalesce((SELECT string_agg(DISTINCT m->>'key', ',') FROM jsonb_array_elements(s.data->'categories') c, jsonb_array_elements(c->'missing') m),'-')
FROM (SELECT data FROM signals s JOIN t ON t.id = s.tender_id WHERE s.topic = 'dps.qualifiable.shadow' ORDER BY s.id DESC LIMIT 1) s;
ROLLBACK;
