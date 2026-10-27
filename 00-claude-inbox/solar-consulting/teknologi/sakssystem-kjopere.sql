-- trading-1 2026-10-27: kommuner og fylker som har lyst ut sakssystem eller saksbehandling de siste 24 mnd (kandidater for kundesamtaler om Nova).
-- Samme tekstfilter som sakssystem-krav.ts, uten arkivkjerne og dokumenthåndtering alene. Bare virksomhet og org.nr. READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
WITH k AS (
  SELECT t.id, t.buyer_id, t.title, t.published_at, t.notice_type
  FROM tenders t
  WHERE t.published_at >= now() - interval '24 months'
    AND t.related_tender_id IS NULL
    AND (t.title ~* '(saksbehandl|sakssystem|sak.{0,4}arkiv|fagsystem|fagløsning)' OR t.description ~* '(saksbehandlingssystem|sakssystem|fagsystem for)')
),
b AS (
  SELECT b.id, b.name, b.org_number, b.type::text type, b.relationship::text rel
  FROM buyers b WHERE b.type IN ('kommune','fylkeskommune','interkommunalt') OR b.name ~* '(kommune|fylkeskommune|interkommunal|IKS)'
)
SELECT 'TOTAL', (SELECT count(*) FROM k)::text, (SELECT count(*) FROM k JOIN b ON b.id = k.buyer_id)::text, (SELECT count(DISTINCT k.buyer_id) FROM k JOIN b ON b.id = k.buyer_id)::text, '', '', ''
UNION ALL
SELECT 'KJOPER', b.name, coalesce(b.org_number,'-'), b.type || '/' || coalesce(b.rel,'-'), count(*)::text, to_char(max(k.published_at),'YYYY-MM-DD'),
  left((array_agg(k.title ORDER BY k.published_at DESC))[1], 110)
FROM k JOIN b ON b.id = k.buyer_id
GROUP BY b.name, b.org_number, b.type, b.rel
ORDER BY 1, 6 DESC
LIMIT 80;
ROLLBACK;
