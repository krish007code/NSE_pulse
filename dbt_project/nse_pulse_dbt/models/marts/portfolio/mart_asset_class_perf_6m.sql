with max_date_cte as (
    select max(trade_date) as max_date from {{ ref('stg_raw_nse__daily_prices') }}
),
recent as (
    select *
    from {{ ref('stg_raw_nse__daily_prices') }}
    where trade_date >= (select max_date from max_date_cte) - interval 6 month
),
prices as (
    select
        asset_class,
        ticker_symbol,
        argMin(close_price, trade_date) as start_price,
        argMax(close_price, trade_date) as end_price
    from recent
    group by asset_class, ticker_symbol
)
select
    asset_class,
    avg((end_price - start_price) / start_price) as avg_return_6m
from prices
group by asset_class
order by avg_return_6m desc