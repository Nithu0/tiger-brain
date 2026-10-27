BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '240s';
with dur as (
  select distinct on (r.external_id) r.external_id,
    coalesce(
      (jsonb_path_query_first(r.body, 'lax $.** ? (@.label == "Varighet, Måned").value') #>> '{}')::text,
      (jsonb_path_query_first(r.body, 'lax $.** ? (@.label == "Duration").value') #>> '{}')::text) as m,
    (jsonb_path_query_first(r.body, 'lax $.** ? (@.label == "Varighet, År").value') #>> '{}')::text as y
  from raw_notices r where r.source='doffin' and r.kind='doffin-notice'
  order by r.external_id, r.retrieved_at desc
), res as (
  select t.id, t.buyer_id, t.published_at,
    case when d.m ~ '^\d+$' then d.m::int when d.m ~ '^\d+ MONTH$' then split_part(d.m,' ',1)::int when d.y ~ '^\d+$' then d.y::int*12 end as months
  from tenders t join dur d on d.external_id = t.external_id
  where t.source='doffin' and t.notice_type='RESULT' and t.buyer_id is not null and t.published_at >= '2021-01-01' and t.published_at < '2023-01-01'
), r2 as (
  select id, buyer_id, published_at, published_at + (months || ' months')::interval pend from res where months between 6 and 60
), w as (select * from r2 where pend between '2022-07-01' and '2024-06-30'),
hits as (
  select w.id,
   exists (select 1 from tenders c where c.notice_type='COMPETITION' and c.buyer_id=w.buyer_id and c.published_at > w.published_at
      and c.published_at between w.pend - interval '12 months' and w.pend + interval '6 months'
      and exists (select 1 from tenders_texts a join tenders_texts b on left(a.text,5)=left(b.text,5) where a.parent_id=w.id and a.path='cpvCodes' and b.parent_id=c.id and b.path='cpvCodes')) hit,
   exists (select 1 from tenders c where c.notice_type='COMPETITION' and c.buyer_id=w.buyer_id and c.published_at > w.published_at
      and exists (select 1 from tenders_texts a join tenders_texts b on left(a.text,5)=left(b.text,5) where a.parent_id=w.id and a.path='cpvCodes' and b.parent_id=c.id and b.path='cpvCodes')) any_later,
   exists (select 1 from tenders_texts x where x.parent_id=w.id and x.path='cpvCodes' and (x.text like '72%' or x.text like '48%')) it
  from w)
select 'BACKTEST', (select count(*) from res), (select count(*) from r2), count(*), count(*) filter (where hit), count(*) filter (where any_later), count(*) filter (where it), count(*) filter (where it and hit), count(*) filter (where it and any_later) from hits;
ROLLBACK;
