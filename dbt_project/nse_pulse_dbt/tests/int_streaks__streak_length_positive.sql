-- Test: streak_length must be >= 1.
-- A streak is a group of consecutive days with the same direction. The minimum
-- possible streak is a single day (length = 1). Zero or negative lengths would
-- mean the grouping logic (row_number gap trick) produced an empty or inverted group.
select
    ticker_symbol,
    direction,
    streak_start,
    streak_end,
    streak_length
from {{ ref('int_streaks') }}
where streak_length < 1
