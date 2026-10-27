-- trading-1 2026-10-27: egne kravtekster (ikke ESPD-overskrifter) for kortlista over IT-DPS-er. READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH ids(eid) AS (VALUES ('2022-962877'),('2025-118721'),('2025-111353'),('2026-105761'),('2026-102316'),('2025-104594'),('2024-112944'),
  ('2025-106184'),('2026-112986'),('2025-116151'),('2022-374835'),('2026-106810'),('2026-111966'),('2025-101755'),('2024-106681'),('2024-112550'),('2026-108122')),
t AS (SELECT t.* FROM tenders t JOIN ids ON ids.eid = t.external_id WHERE t.related_tender_id IS NULL)
SELECT 'KRAV', t.external_id, coalesce(e->>'name',''), regexp_replace(left(coalesce(e->>'description',''), 700), '\s+', ' ', 'g')
FROM t, jsonb_array_elements(CASE WHEN jsonb_typeof(t.qualification_criteria::jsonb)='array' THEN t.qualification_criteria::jsonb ELSE '[]'::jsonb END) e
WHERE e->>'kind' = 'selection' AND length(coalesce(e->>'description','')) > 0
  AND (e->>'description') !~* '^(Følgende utdanning|Leverandørens \("totale"\)|Leverandørens gjennomsnittlige|Er leverandørens|Hvis opplysningene om omsetning|Bare for tjenester|Leverandør kan anvende følgende|Er leverandøren i stand til å fremlegge|Attester utstedt)'
UNION ALL
SELECT 'BESKR', t.external_id, '', regexp_replace(left(coalesce(t.description,''), 500), '\s+', ' ', 'g') FROM t
ORDER BY 2, 1;
ROLLBACK;
