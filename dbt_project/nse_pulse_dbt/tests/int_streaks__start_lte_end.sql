-- Test: streak_start must be <= streak_end for every streak.
-- streak_start = min(trade_date) and streak_end = max(trade_date) within the group.
-- A start date after the end date would mean either the grouping is broken
-- or dates in the underlying data are out-of-order in a way that corrupts the gap trick.
select
    ticker_symbol,
    direction,
    streak_start,
    streak_end,
    streak_length
from {{ ref('int_streaks') }}
where streak_start > streak_end
