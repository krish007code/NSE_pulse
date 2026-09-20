with r as (
    select * from {{ ref('int_returns') }}
)
select
    a.ticker_symbol as ticker_a,
    b.ticker_symbol as ticker_b,
    corr(a.daily_return, b.daily_return) as correlation,
    count(*) as days_overlap
from r a
join r b on a.trade_date = b.trade_date
-- ClickHouse 24.1 rejects non-equi conditions in ON clauses when either side
-- of the join is a CTE (ephemeral model inlined as a subquery).  Moving the
-- pair-deduplication filter to WHERE is semantically identical and compiles
-- cleanly against both ephemeral and view/table relations.
where a.ticker_symbol < b.ticker_symbol
group by a.ticker_symbol, b.ticker_symbol
