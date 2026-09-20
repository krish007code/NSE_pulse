-- Test: trade_date must be unique in int_market_daily.
-- This model aggregates all tickers per day — one row per trading date.
-- A duplicate trade_date means the GROUP BY in the model is broken, and
-- mart_market_breadth would produce incorrect pct_up / pct_down values
-- (denominator would be counted twice per day).
select
    trade_date,
    count(*) as row_count
from {{ ref('int_market_daily') }}
group by trade_date
having count(*) > 1
