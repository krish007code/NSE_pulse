with worst as (
    select
        ticker_symbol,
        asset_class,
        argMin(trade_date, daily_return) as worst_date,
        argMin(prev_close, daily_return) as price_before_drop,
        min(daily_return) as worst_return
    from {{ ref('int_returns') }}
    group by ticker_symbol, asset_class
),
recovery as (
    select
        w.ticker_symbol,
        minIf(p.trade_date, p.trade_date > w.worst_date and p.close_price >= w.price_before_drop) as recovery_date
    from worst w
    join {{ ref('stg_raw_nse__daily_prices') }} p
        on p.ticker_symbol = w.ticker_symbol
    group by w.ticker_symbol
)
select
    w.ticker_symbol,
    w.asset_class,
    w.worst_date,
    w.worst_return,
    r.recovery_date,
    dateDiff('day', w.worst_date, r.recovery_date) as days_to_recover
from worst w
left join recovery r on r.ticker_symbol = w.ticker_symbol
order by w.worst_return asc