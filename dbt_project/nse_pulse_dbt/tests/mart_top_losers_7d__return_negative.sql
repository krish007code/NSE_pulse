-- Test: every row in mart_top_losers_7d must have return_7d < 0.
-- The model is ORDER BY return_7d ASC LIMIT 10. If any of the bottom 10
-- 7-day returns is non-negative, every ticker had a positive week — which is
-- notable enough to surface rather than silently showing winners as "losers".
select
    ticker_symbol,
    return_7d
from {{ ref('mart_top_losers_7d') }}
where return_7d >= 0
