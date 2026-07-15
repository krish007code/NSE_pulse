with v as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        daily_return,
        trade_volume,
        lag(trade_volume) over (partition by ticker_symbol order by trade_date) as prev_volume
    from {{ ref('int_returns') }}
)
select
    ticker_symbol,
    asset_class,
    trade_date,
    daily_return,
    trade_volume,
    prev_volume
from v
where daily_return > 0
and trade_volume < prev_volume
