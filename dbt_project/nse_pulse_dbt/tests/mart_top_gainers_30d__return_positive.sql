-- Test: every row in mart_top_gainers_30d must have return_30d > 0.
-- The model is ORDER BY return_30d DESC LIMIT 10 — if any of the top 10
-- 30-day returns is negative or zero it means the entire universe of tickers
-- had negative 30-day returns, which is a significant market event worth flagging
-- explicitly rather than silently surfacing losers in a "gainers" mart.
select
    ticker_symbol,
    return_30d
from {{ ref('mart_top_gainers_30d') }}
where return_30d <= 0
