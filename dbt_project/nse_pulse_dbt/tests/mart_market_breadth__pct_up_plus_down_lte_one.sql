-- Test: pct_up + pct_down must be <= 1.0 on every day.
-- pct_up = up_count / tickers_count, pct_down = down_count / tickers_count.
-- Tickers with flat returns (daily_return = 0) are in tickers_count but not
-- in up_count or down_count, so the sum can be < 1. It can never exceed 1
-- (that would require up_count + down_count > tickers_count, which is impossible).
-- A small tolerance (1e-9) accounts for floating-point division.
select
    trade_date,
    pct_up,
    pct_down,
    pct_up + pct_down as total_pct
from {{ ref('mart_market_breadth') }}
where (pct_up + pct_down) > 1.000000001
