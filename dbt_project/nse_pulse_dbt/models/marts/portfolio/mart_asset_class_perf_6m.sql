with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
recent as (
    select *
    from p
    where trade_date >= dateadd(month, -6, current_date)
),
bounds as (
    select
        asset_class,
        ticker_symbol,
        min(trade_date) as start_date,
        max(trade_date) as end_date
    from recent
    group by asset_class, ticker_symbol
),
prices as (
    select
        b.asset_class,
        b.ticker_symbol,
        s.close_price as start_price,
        e.close_price as end_price
    from bounds b
    join recent s on s.ticker_symbol = b.ticker_symbol and s.trade_date = b.start_date
    join recent e on e.ticker_symbol = b.ticker_symbol and e.trade_date = b.end_date
)
select
    asset_class,
    avg((end_price - start_price) / start_price) as avg_return_6m
from prices
group by asset_class
order by avg_return_6m desc
