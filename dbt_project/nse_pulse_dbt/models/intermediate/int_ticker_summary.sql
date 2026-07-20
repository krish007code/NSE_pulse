select
    ticker_symbol,
    asset_class,
    min(trade_date) as first_date,
    max(trade_date) as last_date,
    count(*) as days_tracked,
    max(high_price) as all_time_high,
    min(low_price) as all_time_low,
    argMax(close_price, trade_date) as last_close
from {{ ref("stg_raw_nse__daily_prices") }}
group by ticker_symbol, asset_class
