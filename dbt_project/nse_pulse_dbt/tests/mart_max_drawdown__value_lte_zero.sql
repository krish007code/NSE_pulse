-- Test: max_drawdown must be <= 0 for every ticker.
-- max_drawdown = min(drawdown_pct) over all history. drawdown_pct is guaranteed
-- <= 0 by the intermediate test. The minimum of non-positive numbers is
-- non-positive. A positive value means the intermediate invariant was violated
-- or the GROUP BY aggregation is wrong.
select
    ticker_symbol,
    max_drawdown
from {{ ref('mart_max_drawdown') }}
where max_drawdown > 0
