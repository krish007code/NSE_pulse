with recent as (
    select
        ticker_symbol,
        trade_date,
        close_price
    from {{ ref('stg_raw_nse__daily_prices') }}
    where trade_date >= (select max(trade_date) from {{ ref('stg_raw_nse__daily_prices') }}) - interval 30 day
)

select
    ticker_symbol,
    -- the close_price at the min / max date in the 30 days
    argMin(close_price, trade_date) as start_price,
    argMax(close_price, trade_date) as end_price,
    (end_price - start_price) / start_price as return_30d
from recent
group by ticker_symbol
order by return_30d desc
limit 10
