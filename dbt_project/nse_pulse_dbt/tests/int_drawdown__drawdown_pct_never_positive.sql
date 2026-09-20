-- Test: drawdown_pct must always be <= 0.
-- drawdown_pct = (close - running_peak) / running_peak.
-- running_peak is the cumulative maximum, so close_price <= running_peak always.
-- A positive drawdown_pct means running_peak is somehow less than close_price,
-- which would indicate the window function is not working correctly
-- (wrong ORDER BY, wrong frame, or a partitioning bug).
select
    ticker_symbol,
    trade_date,
    close_price,
    running_peak,
    drawdown_pct
from {{ ref('int_drawdown') }}
where drawdown_pct is not null
  and drawdown_pct > 0
