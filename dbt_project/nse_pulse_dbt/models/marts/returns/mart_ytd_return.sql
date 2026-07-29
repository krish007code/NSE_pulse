with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
ytd as (
    select *
    from p
    where trade_date >= date_trunc('year', (select max(trade_date) from p))
),
aggregated as (
    select
        ticker_symbol,
        argMin(close_price, trade_date) as start_price,
        argMax(close_price, trade_date) as end_price
    from ytd
    group by ticker_symbol
)
select
    ticker_symbol,
    start_price,
    end_price,
    (end_price - start_price) / start_price as ytd_return,
    rank() over (order by ytd_return desc) as ytd_rank
from aggregated
