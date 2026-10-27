-- trading-1 2026-10-27: tildelte IT-konsulentkontrakter som ligner det vi vil levere (kandidater for innsyn i prisskjema). READ-ONLY.
BEGIN;
SET TRANSACTION READ ONLY;
SELECT 'K', t.external_id, to_char(a.awarded_at,'YYYY-MM-DD'), b.name || ' (' || coalesce(b.org_number,'-') || ', ' || b.type::text || ')',
  left(t.title, 100), s.name || ' (' || coalesce(s.org_number,'-') || ')', coalesce(round(a.value_amount)::text,'-'), coalesce(a.bidder_count::text,'-')
FROM awards a
JOIN tenders t ON t.id = a.tender_id
JOIN buyers b ON b.id = a.buyer_id
JOIN suppliers s ON s.id = a.supplier_id
WHERE a.awarded_at >= '2024-01-01'
  AND b.type IN ('kommune','fylkeskommune','stat')
  AND a.value_amount BETWEEN 300000 AND 5000000
  AND t.title ~* '(konsulent|bistand|systemutvikl|utviklingsressurs|utvikler|fullstack|programvareutvikl|smidig|team)'
  AND t.title !~* '(bygg|vei|veg|arkitekt[^u]|landskap|rør|elektro|brann|regnskap|revisjon|jus|advokat|helse|lege|sykepleie|barnevern)'
  AND EXISTS (SELECT 1 FROM tenders_texts c WHERE c.parent_id = t.id AND c.path = 'cpvCodes' AND c.text LIKE '72%')
ORDER BY a.awarded_at DESC
LIMIT 40;
ROLLBACK;
