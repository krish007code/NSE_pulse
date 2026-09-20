-- Test: first_date must be <= last_date for every ticker.
-- first_date = min(trade_date), last_date = max(trade_date). If a ticker only
-- has one row both will be equal (acceptable). An inversion means the min/max
-- aggregation is broken, which would also corrupt days_tracked counts.
select
    ticker_symbol,
    first_date,
    last_date,
    days_tracked
from {{ ref('int_ticker_summary') }}
where first_date > last_date
