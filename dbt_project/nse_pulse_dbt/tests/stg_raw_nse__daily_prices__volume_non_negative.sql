-- Test: trade_volume must be >= 0.
-- Negative volume is nonsensical and would corrupt avg_volume moving averages
-- and zero-volume-day detection in mart_zero_volume_days.
select
    ticker_symbol,
    trade_date,
    trade_volume
from {{ ref('stg_raw_nse__daily_prices') }}
where trade_volume < 0
