-- Test: avg_close_7d and avg_close_30d must both be strictly positive.
-- They are averages of close_price, which the staging test guarantees > 0.
-- A non-positive moving average means either the window included a corrupt row
-- that bypassed the staging check, or a NULL was coerced to 0 in the average.
select
    ticker_symbol,
    trade_date,
    avg_close_7d,
    avg_close_30d
from {{ ref('mart_moving_averages') }}
where avg_close_7d <= 0
   or avg_close_30d <= 0
