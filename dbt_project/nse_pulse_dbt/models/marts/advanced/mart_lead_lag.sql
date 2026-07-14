with r as (
    select * from {{ ref('int_returns') }}
),
shifted as (
    select
        ticker_symbol,
        trade_date,
        daily_return,
        lead(daily_return) over (partition by ticker_symbol order by trade_date) as next_day_return
    from r
)
select
    a.ticker_symbol as leader,
    b.ticker_symbol as follower,
    corr(a.daily_return, b.next_day_return) as lead_lag_correlation
from r a
join shifted b
    on b.trade_date = a.trade_date
    and b.ticker_symbol != a.ticker_symbol
group by a.ticker_symbol, b.ticker_symbol
order by lead_lag_correlation desc
