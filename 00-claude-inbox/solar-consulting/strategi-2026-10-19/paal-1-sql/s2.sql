SET TRANSACTION READ ONLY;
-- DPS: åpne nå = søknadsfrist i framtiden
select 'DPS_OPEN_SPLIT', count(*) filter (where deadline > now()), count(*) filter (where deadline is null), count(*) filter (where deadline <= now()) from tenders where procedure='dps' and notice_type='COMPETITION' and related_tender_id is null;
select 'DPS_OPEN_IT', t.id, left(t.title,70), t.buyer_name, to_char(t.deadline,'YYYY-MM-DD'), jsonb_array_length(coalesce(t.qualification_criteria,'[]'::jsonb)), t.source_url
from tenders t where t.procedure='dps' and t.notice_type='COMPETITION' and t.related_tender_id is null and t.deadline > now()
and exists (select 1 from tenders_texts x where x.parent_id=t.id and x.path='cpvCodes' and (x.text like '72%' or x.text like '48%' or x.text like '79%' or x.text like '71%'))
order by t.deadline limit 40;
select 'DPS_OPEN_DIV', left(x.text,2), count(distinct t.id) from tenders t join tenders_texts x on x.parent_id=t.id and x.path='cpvCodes' where t.procedure='dps' and t.notice_type='COMPETITION' and t.related_tender_id is null and t.deadline > now() group by 2 order by 3 desc limit 10;
select 'CAPCOLS', column_name from information_schema.columns where table_name='capability_facts' order by ordinal_position;
ROLLBACK;
