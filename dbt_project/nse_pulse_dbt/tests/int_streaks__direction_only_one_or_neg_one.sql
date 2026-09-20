-- Test: every row in int_streaks must have direction IN (-1, 1).
-- The model explicitly filters WHERE direction != 0, so direction = 0 rows
-- (flat days) must never appear. Any other value would indicate the CASE
-- expression in the upstream CTE produced an unexpected result.
select
    ticker_symbol,
    direction,
    streak_start,
    streak_end
from {{ ref('int_streaks') }}
where direction not in (-1, 1)
