-- Test: pct_up and pct_down must each lie within [0.0, 1.0].
-- Both are count / total_count ratios and cannot be negative or exceed 1.
-- A value outside [0, 1] would mean either a count went negative (impossible
-- from a SUM of CASE 1 else 0) or tickers_count was zero (division by zero
-- producing Inf/NaN, which ClickHouse may propagate silently).
select
    trade_date,
    pct_up,
    pct_down
from {{ ref('mart_market_breadth') }}
where pct_up < 0 or pct_up > 1
   or pct_down < 0 or pct_down > 1
