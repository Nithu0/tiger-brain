-- trading-1 2026-10-27: har TED-vinnere i prod org.nr som stemmer med regelen etter #187 (tedWinners)?
-- Org.nr regnes på nytt fra rå-arkivet: navnet skal treffe én gang i de parede tilbyderlistene. READ-ONLY, bare CTE-er.
BEGIN;
SET TRANSACTION READ ONLY;
WITH raw AS (
  SELECT DISTINCT ON (external_id) external_id, body FROM raw_notices WHERE source = 'ted' ORDER BY external_id, retrieved_at DESC
),
pl AS (  -- pickLang: nor, nob, nno, eng, ellers første språk
  SELECT r.external_id,
    (SELECT v FROM (VALUES (1, r.body->'organisation-name-tenderer'->'nor'),(2, r.body->'organisation-name-tenderer'->'nob'),(3, r.body->'organisation-name-tenderer'->'nno'),(4, r.body->'organisation-name-tenderer'->'eng')) x(o,v) WHERE v IS NOT NULL ORDER BY o LIMIT 1) tn,
    (SELECT value FROM jsonb_each(CASE WHEN jsonb_typeof(r.body->'organisation-name-tenderer')='object' THEN r.body->'organisation-name-tenderer' ELSE '{}'::jsonb END) LIMIT 1) tn_any,
    r.body->'organisation-identifier-tenderer' ti,
    r.body->'winner-identifier' wi
  FROM raw r
),
lst AS (
  SELECT external_id,
    CASE jsonb_typeof(coalesce(tn, tn_any)) WHEN 'array' THEN coalesce(tn, tn_any) WHEN 'string' THEN jsonb_build_array(coalesce(tn, tn_any)) ELSE '[]'::jsonb END tnames,
    CASE jsonb_typeof(ti) WHEN 'array' THEN ti WHEN 'string' THEN jsonb_build_array(ti) ELSE '[]'::jsonb END tids,
    CASE jsonb_typeof(wi) WHEN 'array' THEN wi WHEN 'string' THEN jsonb_build_array(wi) ELSE '[]'::jsonb END wids
  FROM pl
),
w AS (
  SELECT t.external_id, t.updated_at, t.created_at, lw.name, lw.org_number stored
  FROM tenders t JOIN tenders_lots l ON l._parent_id = t.id JOIN tenders_lots_winners lw ON lw._parent_id = l.id
  WHERE t.source = 'ted' AND lw.name IS NOT NULL
),
calc AS (
  SELECT w.*, l.tnames IS NOT NULL has_raw,
    jsonb_array_length(coalesce(l.tnames,'[]')) n_t, jsonb_array_length(coalesce(l.tids,'[]')) n_i,
    (SELECT count(*) FROM jsonb_array_elements_text(coalesce(l.tnames,'[]')) x WHERE lower(regexp_replace(trim(x),'\s+',' ','g')) = lower(regexp_replace(trim(w.name),'\s+',' ','g'))) hits,
    (SELECT regexp_replace(regexp_replace(regexp_replace(l.tids->>(o.ord-1)::int, '[\s.]','','g'),'^NO','','i'),'MVA$','','i')
       FROM jsonb_array_elements_text(coalesce(l.tnames,'[]')) WITH ORDINALITY o(x, ord)
       WHERE lower(regexp_replace(trim(o.x),'\s+',' ','g')) = lower(regexp_replace(trim(w.name),'\s+',' ','g')) LIMIT 1) cand,
    (SELECT count(DISTINCT regexp_replace(x,'\s','','g')) FROM jsonb_array_elements_text(coalesce(l.wids,'[]')) x) n_wid
  FROM w LEFT JOIN lst l ON l.external_id = w.external_id
),
dom AS (
  SELECT *, CASE WHEN n_t > 0 AND n_t = n_i AND hits = 1 AND cand ~ '^\d{9}$' THEN cand END ny FROM calc
),
klass AS (
  SELECT *, CASE
    WHEN NOT has_raw THEN 'uten_raw'
    WHEN stored IS NULL AND ny IS NULL THEN 'begge_null'
    WHEN stored = ny THEN 'lik'
    WHEN stored IS NOT NULL AND ny IS NULL AND n_t = 0 THEN 'lagret_uten_tilbyderliste'
    WHEN stored IS NOT NULL AND ny IS NULL THEN 'lagret_men_ny_null'
    WHEN stored IS NULL THEN 'ny_men_lagret_null'
    ELSE 'ULIK' END k,
    CASE WHEN updated_at < '2026-10-17' THEN 'før 17.10' ELSE 'fra 17.10' END periode
  FROM dom
)
SELECT 'KLASSE', periode, k, count(*)::text FROM klass GROUP BY periode, k
UNION ALL SELECT 'ULIK_EKS', external_id, name, coalesce(stored,'-') || ' -> ' || coalesce(ny,'-') FROM (SELECT * FROM klass WHERE k IN ('ULIK','lagret_men_ny_null') ORDER BY random() LIMIT 15) e
ORDER BY 1, 2, 3;
ROLLBACK;
