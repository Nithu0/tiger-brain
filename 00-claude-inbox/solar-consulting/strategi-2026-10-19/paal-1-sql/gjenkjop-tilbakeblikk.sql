BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '280s';
with n as (
  select distinct t.buyer_id, left(x.text,5) c5, date_trunc('day', t.published_at) d
  from tenders t join tenders_texts x on x.parent_id=t.id and x.path='cpvCodes'
  where t.notice_type='COMPETITION' and t.buyer_id is not null and (x.text like '72%' or x.text like '48%')
    and t.published_at >= '2021-01-01' and t.published_at < '2025-01-01'
), train as (select * from n where d < '2024-01-01'),
 test as (select * from n where d >= '2024-01-01'),
 pairs as (
  select buyer_id, c5, array_agg(d order by d) ds, count(*) k, max(d) last from train group by 1,2
), iv as (
  select buyer_id, c5, k, last,
    (select percentile_cont(0.5) within group (order by extract(epoch from b - a)/2629800)
       from (select ds[i] a, ds[i+1] b from generate_subscripts(ds,1) i where i < cardinality(ds)) z where extract(epoch from b-a)/2629800 >= 2) med
  from pairs
), pred as (
  select buyer_id, c5, k, last,
    case when med is not null and k >= 3 then 'medium' when med is not null then 'low-pair' else 'low-global' end tier,
    coalesce(med, 16.6) m
  from iv
), win as (
  select *, last + (m || ' months')::interval p,
    last + ((m*0.5) || ' months')::interval lo, last + ((m*1.5) || ' months')::interval hi from pred
), obs as ( -- predictions whose centre falls in 2024 (observable)
  select w.*, exists (select 1 from test t where t.buyer_id=w.buyer_id and t.c5=w.c5 and t.d between w.lo and w.hi) hit,
    exists (select 1 from test t where t.buyer_id=w.buyer_id and t.c5=w.c5) any2024
  from win w where w.p >= '2024-01-01' and w.p < '2025-01-01'
)
select 'BT', tier, count(*), count(*) filter (where hit), round(100.0*count(*) filter (where hit)/nullif(count(*),0),1), count(*) filter (where any2024) from obs group by 2 order by 2;
ROLLBACK;
