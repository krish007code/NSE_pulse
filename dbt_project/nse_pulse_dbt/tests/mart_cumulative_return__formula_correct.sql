-- Test: cumulative_return must equal (last_close - first_close) / first_close.
-- We recompute the value and check for any discrepancy beyond floating-point
-- tolerance (1e-9). A mismatch means the formula in the model was changed or
-- the column references were swapped.
select
    ticker_symbol,
    cumulative_return,
    (last_close - first_close) / first_close as expected_return,
    abs(cumulative_return - (last_close - first_close) / first_close) as delta
from {{ ref('mart_cumulative_return') }}
where abs(cumulative_return - (last_close - first_close) / first_close) > 1e-9
