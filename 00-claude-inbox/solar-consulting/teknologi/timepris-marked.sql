-- trading-1 2026-10-27 (#46): timepriser oppgitt i tekst i IT-kunngjøringer (CPV 72), som markedsgrunnlag. READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH t AS (
  SELECT t.id, t.external_id, t.notice_type::text nt, t.published_at, coalesce(t.title,'') || ' ' || coalesce(t.description,'') ||
    coalesce((SELECT string_agg(coalesce(l.title,''),' ') FROM tenders_lots l WHERE l._parent_id = t.id),'') txt
  FROM tenders t
  WHERE t.published_at >= '2023-01-01'
    AND EXISTS (SELECT 1 FROM tenders_texts c WHERE c.parent_id = t.id AND c.path = 'cpvCodes' AND c.text LIKE '72%')
),
m AS (
  SELECT t.external_id, t.nt, t.published_at, x[1] belop, substring(t.txt from greatest(1, position(x[1] in t.txt) - 90) for 220) sitat
  FROM t, regexp_matches(t.txt, '(?:kr\.?|NOK)\s?([0-9][0-9 .]{2,6})\s?(?:,-)?\s?(?:per|pr\.?|/)\s?(?:time|t\M)', 'gi') x
  UNION ALL
  SELECT t.external_id, t.nt, t.published_at, x[1], substring(t.txt from greatest(1, position(x[1] in t.txt) - 90) for 220)
  FROM t, regexp_matches(t.txt, '([0-9][0-9 .]{2,6})\s?(?:kr|NOK|,-)\s?(?:eks[^ ]* mva\.?\s?)?(?:per|pr\.?|/)\s?time', 'gi') x
)
SELECT 'N', count(*)::text, count(DISTINCT external_id)::text, '' FROM m
UNION ALL
SELECT 'TREFF', external_id || ' ' || nt || ' ' || to_char(published_at,'YYYY-MM-DD'), regexp_replace(belop,'[ .]','','g'), regexp_replace(sitat, '\s+', ' ', 'g') FROM m
LIMIT 80;
ROLLBACK;
