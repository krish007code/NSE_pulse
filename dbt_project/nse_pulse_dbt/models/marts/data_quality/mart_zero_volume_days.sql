with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
market_days as (
    select distinct trade_date
    from p
    where trade_volume > 0
)
select
    p.ticker_symbol,
    p.asset_class,
    p.trade_date,
    p.trade_volume
from p
join market_days m on m.trade_date = p.trade_date
where p.trade_volume = 0
