-- trading-1 2026-10-27: hvem vi bør intervjue (IN oppstart 1, kundefunn). IT-leverandører (CPV 72) som vinner offentlige
-- kontrakter ofte, men i små beløp (proxy for SMB som byr mye). Bare offentlig foretaksinformasjon (navn, org.nr.). READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH it AS (
  SELECT a.supplier_id, a.buyer_id, a.value_amount, a.awarded_at
  FROM awards a JOIN tenders t ON t.id = a.tender_id
  WHERE a.awarded_at >= '2023-01-01'
    AND EXISTS (SELECT 1 FROM tenders_texts tt WHERE tt.parent_id = t.id AND tt.path = 'cpvCodes' AND tt.text LIKE '72%')
),
agg AS (
  SELECT supplier_id, count(*) n, count(DISTINCT buyer_id) kjopere,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY value_amount) FILTER (WHERE value_amount > 0) median_verdi,
    max(awarded_at) siste
  FROM it GROUP BY supplier_id
)
SELECT 'IT_TOTAL', (SELECT count(*) FROM it)::text, (SELECT count(DISTINCT supplier_id) FROM it)::text, '', '', ''
UNION ALL
SELECT 'KANDIDAT', s.name, coalesce(s.org_number,'-'), agg.n::text, agg.kjopere::text, coalesce(round(agg.median_verdi)::text,'-') || ' | ' || to_char(agg.siste,'YYYY-MM-DD')
FROM agg JOIN suppliers s ON s.id = agg.supplier_id
WHERE agg.n BETWEEN 3 AND 25 AND agg.kjopere >= 3 AND (agg.median_verdi IS NULL OR agg.median_verdi < 4000000)
ORDER BY 1, 5 DESC
LIMIT 40;
ROLLBACK;
