with r as (
    select * from {{ ref('int_returns') }}
),
worst as (
    select
        ticker_symbol,
        asset_class,
        trade_date as worst_date,
        prev_close as price_before_drop,
        daily_return as worst_return
    from r
    qualify row_number() over (partition by ticker_symbol order by daily_return asc) = 1
),
recovery as (
    select
        w.ticker_symbol,
        min(p.trade_date) as recovery_date
    from worst w
    join {{ ref('stg_raw_nse__daily_prices') }} p
        on p.ticker_symbol = w.ticker_symbol
        and p.trade_date > w.worst_date
        and p.close_price >= w.price_before_drop
    group by w.ticker_symbol
)
select
    w.ticker_symbol,
    w.asset_class,
    w.worst_date,
    w.worst_return,
    r.recovery_date,
    datediff(day, w.worst_date, r.recovery_date) as days_to_recover
from worst w
left join recovery r on r.ticker_symbol = w.ticker_symbol
order by w.worst_return asc
