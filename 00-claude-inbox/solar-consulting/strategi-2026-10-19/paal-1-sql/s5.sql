BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '240s';
with r as (
  select t.id, t.buyer_id, t.published_at from tenders t
  where t.notice_type='RESULT' and t.buyer_id is not null and t.published_at >= '2021-01-01' and t.published_at < '2022-01-01'
    and exists (select 1 from tenders_texts x where x.parent_id=t.id and x.path='cpvCodes' and (x.text like '72%' or x.text like '48%'))
), nxt as (
  select r.id, (select min(c.published_at) from tenders c where c.notice_type='COMPETITION' and c.buyer_id=r.buyer_id and c.published_at > r.published_at + interval '3 months'
      and exists (select 1 from tenders_texts a join tenders_texts b on left(a.text,5)=left(b.text,5) where a.parent_id=r.id and a.path='cpvCodes' and b.parent_id=c.id and b.path='cpvCodes')) as next_at, r.published_at
  from r)
select 'RETENDER_IT_2021', count(*),
  count(*) filter (where next_at < published_at + interval '24 months'),
  count(*) filter (where next_at < published_at + interval '36 months'),
  count(*) filter (where next_at < published_at + interval '48 months'),
  count(*) filter (where next_at is not null),
  percentile_cont(0.5) within group (order by extract(epoch from next_at - published_at)/2629800) filter (where next_at is not null)
from nxt;
ROLLBACK;
