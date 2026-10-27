BEGIN;
SET TRANSACTION READ ONLY;
select 'CAP', polarity, source, left(statement,160), valid_until from capability_facts order by polarity, id;
-- Tilbakeblikk: resultat 2021-2022 med oppgitt varighet; forventet slutt = publisert + varighet.
-- Treff = ny COMPETITION fra samme kjøper med felles CPV-5 publisert i [slutt-12 mnd, slutt+6 mnd], senere enn resultatet.
with r as (
  select t.id, t.buyer_id, t.published_at, t.published_at + (t.contract_months || ' months')::interval as pend
  from tenders t
  where t.notice_type='RESULT' and t.contract_months between 6 and 60 and t.buyer_id is not null
    and t.published_at >= '2021-01-01' and t.published_at < '2023-01-01'
), r2 as (
  select * from r where pend between '2022-07-01' and '2024-06-30'
), hits as (
  select r2.id, exists (
    select 1 from tenders c
    where c.notice_type='COMPETITION' and c.buyer_id = r2.buyer_id and c.published_at > r2.published_at
      and c.published_at between r2.pend - interval '12 months' and r2.pend + interval '6 months'
      and exists (select 1 from tenders_texts a join tenders_texts b on left(a.text,5)=left(b.text,5)
                  where a.parent_id=r2.id and a.path='cpvCodes' and b.parent_id=c.id and b.path='cpvCodes')
  ) hit,
  exists (select 1 from tenders_texts x where x.parent_id=r2.id and x.path='cpvCodes' and (x.text like '72%' or x.text like '48%')) it
  from r2
)
select 'BACKTEST', count(*), count(*) filter (where hit), count(*) filter (where it), count(*) filter (where it and hit) from hits;
ROLLBACK;
