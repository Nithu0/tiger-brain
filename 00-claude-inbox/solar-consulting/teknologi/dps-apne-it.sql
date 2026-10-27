-- trading-1 2026-10-27: åpne DPS-er innen IT (CPV 72 eller IT-ord i tittelen), med kravord fra eForm-kriteriene. READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH d AS (
  SELECT t.id, t.external_id, t.title, t.deadline, coalesce(b.name, t.buyer_name) kjoper, b.org_number, t.documents_url,
    CASE WHEN jsonb_typeof(t.qualification_criteria::jsonb)='array' THEN t.qualification_criteria::jsonb ELSE '[]'::jsonb END qc
  FROM tenders t LEFT JOIN buyers b ON b.id = t.buyer_id
  WHERE t.deadline > now() AND t.related_tender_id IS NULL
    AND (t.procedure = 'dps' OR t.title ~* '(dynamisk innkjøpsordning|\mDPS\M|kvalifiseringsordning)')
    AND (EXISTS (SELECT 1 FROM tenders_texts c WHERE c.parent_id = t.id AND c.path = 'cpvCodes' AND c.text LIKE '72%')
         OR t.title ~* '(\mIT\M|IKT|system|utvikl|digital|programvare|data|analytics|test|arkitekt|sikkerhet|konsulent)')
),
k AS (
  SELECT d.id, string_agg(DISTINCT w, ',') ord, count(*) FILTER (WHERE e->>'kind' = 'selection') sel
  FROM d LEFT JOIN LATERAL jsonb_array_elements(d.qc) e ON true
  LEFT JOIN LATERAL (SELECT lower(m[1]) w FROM regexp_matches(coalesce(e->>'description',''), '(forsikring|skatteattest|firmaattest|referanse|omsetning|kredittverd|ISO ?9001|ISO ?27001|miljø|egenerklæring|russisk|presentasjon|CV)', 'gi') m) z ON true
  GROUP BY d.id
)
SELECT 'DPS', d.external_id, to_char(d.deadline,'YYYY-MM-DD'), d.kjoper || ' (' || coalesce(d.org_number,'-') || ')', left(d.title, 95),
  jsonb_array_length(d.qc)::text || '/' || k.sel::text, coalesce(k.ord,'-'), coalesce(d.documents_url,'-')
FROM d JOIN k ON k.id = d.id
ORDER BY 3, 4;
ROLLBACK;
