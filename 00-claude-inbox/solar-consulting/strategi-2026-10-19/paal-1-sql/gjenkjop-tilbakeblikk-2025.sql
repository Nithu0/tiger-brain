BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '280s';
with n as (
  select distinct t.buyer_id, left(x.text,5) c5, date_trunc('day', t.published_at) d
  from tenders t join tenders_texts x on x.parent_id=t.id and x.path='cpvCodes'
  where t.notice_type='COMPETITION' and t.buyer_id is not null and (x.text like '72%' or x.text like '48%')
    and t.published_at >= '2021-01-01' and t.published_at < '2026-01-01'
)
select 'YEARS', extract(year from d)::int, count(*) from n group by 2 order by 2;
ROLLBACK;
BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '280s';
with n as (
  select distinct t.buyer_id, left(x.text,5) c5, date_trunc('day', t.published_at) d
  from tenders t join tenders_texts x on x.parent_id=t.id and x.path='cpvCodes'
  where t.notice_type='COMPETITION' and t.buyer_id is not null and (x.text like '72%' or x.text like '48%')
    and t.published_at >= '2021-01-01' and t.published_at < '2026-01-01'
), runs as (select * from (values ('2024'::text, '2024-01-01'::timestamp, '2025-01-01'::timestamp), ('2025', '2025-01-01', '2026-01-01')) v(label, ts, te)),
pairs as (
  select r.label, r.ts, r.te, n.buyer_id, n.c5, array_agg(n.d order by n.d) ds, count(*) k, max(n.d) last
  from runs r join n on n.d < r.ts group by 1,2,3,4,5
), iv as (
  select *, (select percentile_cont(0.5) within group (order by extract(epoch from b - a)/2629800)
       from (select ds[i] a, ds[i+1] b from generate_subscripts(ds,1) i where i < cardinality(ds)) z where extract(epoch from b-a)/2629800 >= 2) med from pairs
), win as (
  select label, ts, te, buyer_id, c5, k, last, med,
    case when med is not null and k >= 3 then 'medium' when med is not null then 'low-pair' else 'low-global' end tier,
    last + (coalesce(med,16.6) || ' months')::interval p,
    last + ((coalesce(med,16.6)*0.5) || ' months')::interval lo, last + ((coalesce(med,16.6)*1.5) || ' months')::interval hi from iv
)
select 'BT', label, tier, count(*), count(*) filter (where exists (select 1 from n where n.buyer_id=w.buyer_id and n.c5=w.c5 and n.d between w.lo and w.hi and n.d >= w.ts and n.d < w.te)),
  round(100.0*count(*) filter (where exists (select 1 from n where n.buyer_id=w.buyer_id and n.c5=w.c5 and n.d between w.lo and w.hi and n.d >= w.ts and n.d < w.te))/nullif(count(*),0),1)
from win w where w.p >= w.ts and w.p < w.te group by 2,3 order by 2,3;
ROLLBACK;
