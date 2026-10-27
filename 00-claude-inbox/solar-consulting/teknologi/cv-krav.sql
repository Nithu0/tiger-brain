-- trading-1 2026-10-27 (#42): hva ber offentlige IT-konkurranser om i CV-er? Kravtekster med «CV» (kravagenten og eForm-kriterier). READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH q AS (
  SELECT t.external_id, regexp_replace(q.text, '\s+', ' ', 'g') txt FROM requirements q JOIN opportunities o ON o.id = q.opportunity_id JOIN tenders t ON t.id = o.tender_id
  WHERE q.text ~* '\mCV' 
  UNION ALL
  SELECT t.external_id, regexp_replace(e->>'description', '\s+', ' ', 'g')
  FROM tenders t, jsonb_array_elements(CASE WHEN jsonb_typeof(t.qualification_criteria::jsonb)='array' THEN t.qualification_criteria::jsonb ELSE '[]'::jsonb END) e
  WHERE t.published_at >= '2024-01-01' AND (e->>'description') ~* '\mCV'
    AND EXISTS (SELECT 1 FROM tenders_texts c WHERE c.parent_id = t.id AND c.path = 'cpvCodes' AND c.text LIKE '72%')
)
SELECT 'N', count(*)::text, count(DISTINCT external_id)::text, '' FROM q
UNION ALL
SELECT 'ORD', w, count(*)::text, '' FROM q, regexp_matches(lower(txt), '(utdanning|sertifiser\w*|referanse\w*|erfaring|år(?:s)? erfaring|språk|norsk|sikkerhetsklarer\w*|tilgjengelig\w*|rolle|prosjekt\w*|kompetanse|kurs|engelsk|nøkkelperson\w*|maks(?:imalt)? \d+ sider|cv-mal|mal for cv)', 'g') m(w0), LATERAL (SELECT m.w0[1] w) z GROUP BY w
UNION ALL
SELECT 'EKS', external_id, left(txt, 300), '' FROM (SELECT DISTINCT ON (external_id) * FROM q ORDER BY external_id, length(txt) DESC) d
ORDER BY 1, 3 DESC
LIMIT 70;
ROLLBACK;
