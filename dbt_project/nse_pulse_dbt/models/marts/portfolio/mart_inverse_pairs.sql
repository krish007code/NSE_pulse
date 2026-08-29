with returns as (
    select
        ticker_symbol,
        trade_date,
        daily_return
    from {{ ref('int_returns') }}
    where daily_return is not null
)

select
    a.ticker_symbol as ticker_a,
    b.ticker_symbol as ticker_b,
    corr(a.daily_return, b.daily_return) as correlation
from returns a
inner join returns b 
    on a.trade_date = b.trade_date
where a.ticker_symbol < b.ticker_symbol
group by ticker_a, ticker_b
having isFinite(correlation)
order by correlation asc
limit 10