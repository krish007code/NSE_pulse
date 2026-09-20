-- Test: trade_volume must be < prev_volume on every row in mart_price_volume_divergence.
-- The other half of the WHERE clause (trade_volume < prev_volume). If violated,
-- a refactor changed the filter to <= or removed it entirely.
select
    ticker_symbol,
    trade_date,
    trade_volume,
    prev_volume
from {{ ref('mart_price_volume_divergence') }}
where trade_volume >= prev_volume
