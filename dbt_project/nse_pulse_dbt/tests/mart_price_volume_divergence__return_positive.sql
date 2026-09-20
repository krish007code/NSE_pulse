-- Test: every row in mart_price_volume_divergence must have daily_return > 0.
-- The model's WHERE clause is daily_return > 0 AND trade_volume < prev_volume.
-- A non-positive return here means the filter was inadvertently broadened.
select
    ticker_symbol,
    trade_date,
    daily_return
from {{ ref('mart_price_volume_divergence') }}
where daily_return <= 0
