with r as (
    select * from {{ ref('int_returns') }}
),
shifted as (
    select
        ticker_symbol,
        trade_date,
        daily_return,
        leadInFrame(daily_return, 1) over (
            partition by ticker_symbol 
            order by trade_date
            rows between unbounded preceding and unbounded following
        ) as next_day_return
    from r
)
select
    a.ticker_symbol as leader,
    b.ticker_symbol as follower,
    corr(a.daily_return, b.next_day_return) as lead_lag_correlation
from r a
join shifted b
    on b.trade_date = a.trade_date
where b.ticker_symbol != a.ticker_symbol
group by a.ticker_symbol, b.ticker_symbol
order by lead_lag_correlation desc