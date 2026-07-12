with r as (
    select * from {{ ref('int_returns') }}
)
select
    a.ticker_symbol as ticker_a,
    b.ticker_symbol as ticker_b,
    corr(a.daily_return, b.daily_return) as correlation,
    count(*) as days_overlap
from r a
join r b
    on a.trade_date = b.trade_date
    and a.ticker_symbol < b.ticker_symbol
group by a.ticker_symbol, b.ticker_symbol
