BEGIN;
SET TRANSACTION READ ONLY;
select 'NOW', now();
select 'TYPES', notice_type, count(*) from tenders group by 2 order by 3 desc;
select 'PROC', procedure, count(*) from tenders group by 2 order by 3 desc;
select 'YEARS', extract(year from published_at)::int, notice_type, count(*) from tenders group by 2,3 order by 2,3;
-- DPS
select 'DPS_TOTAL', count(*), count(distinct coalesce(related_tender_id,id)) from tenders where procedure='dps';
select 'DPS_BY_TYPE', notice_type, count(*) from tenders where procedure='dps' group by 2 order by 3 desc;
select 'DPS_OPEN', count(*) from tenders where procedure='dps' and notice_type='COMPETITION' and (deadline is null or deadline > now()) and related_tender_id is null;
select 'DPS_DIV', left(x.text,2), count(distinct t.id) from tenders t join tenders_texts x on x.parent_id=t.id and x.path='cpvCodes' where t.procedure='dps' and t.related_tender_id is null group by 2 order by 3 desc limit 12;
select 'DPS_IT_ROOTS', count(distinct t.id) from tenders t where t.procedure='dps' and t.related_tender_id is null and exists (select 1 from tenders_texts x where x.parent_id=t.id and x.path='cpvCodes' and (x.text like '72%' or x.text like '48%'));
select 'DPS_BUYERS', t.buyer_name, count(*) from tenders t where t.procedure='dps' and t.related_tender_id is null group by 2 order by 3 desc limit 12;
-- capability bank
select 'CAP', count(*) from capability_facts;
ROLLBACK;
