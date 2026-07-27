with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
recent as (
    select
        ticker_symbol,
        trade_date,
        close_price
    from p
    where trade_date >= (select max(trade_date) from p) - interval 7 day
),
aggregated as (
    select
        ticker_symbol,
        argMin(close_price, trade_date) as start_price,
        argMax(close_price, trade_date) as end_price
    from recent
    group by ticker_symbol
)

select
    ticker_symbol,
    start_price,
    end_price,
    (end_price - start_price) / start_price as return_7d
from aggregated
order by return_7d asc
limit 10
