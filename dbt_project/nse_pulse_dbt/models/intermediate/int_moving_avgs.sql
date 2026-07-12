with r as (
    select * from {{ ref('int_returns') }}
)
select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price,
    trade_volume,
    daily_return,
    avg(close_price) over (partition by ticker_symbol order by trade_date rows between 6 preceding and current row) as avg_close_7d,
    avg(close_price) over (partition by ticker_symbol order by trade_date rows between 29 preceding and current row) as avg_close_30d,
    avg(trade_volume) over (partition by ticker_symbol order by trade_date rows between 9 preceding and current row) as avg_volume_10d,
    avg(trade_volume) over (partition by ticker_symbol order by trade_date rows between 59 preceding and current row) as avg_volume_60d,
    stddev(daily_return) over (partition by ticker_symbol order by trade_date rows between 29 preceding and current row) as volatility_30d,
    avg(range_pct) over (partition by ticker_symbol order by trade_date rows between 29 preceding and current row) as avg_range_pct_30d
from r
