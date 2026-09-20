-- Test: up_count + down_count must be <= tickers_count on every date.
-- Tickers with flat daily_return (= 0) are counted in tickers_count but not in
-- up_count or down_count, so the sum can legitimately be less than the total.
-- But it must never exceed it — that would mean a ticker was double-counted
-- or the aggregation grouping is wrong.
select
    trade_date,
    tickers_count,
    up_count,
    down_count
from {{ ref('int_market_daily') }}
where (up_count + down_count) > tickers_count
