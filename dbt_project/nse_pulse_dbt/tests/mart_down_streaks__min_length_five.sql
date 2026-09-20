-- Test: mart_down_streaks pulls from int_streaks WHERE direction = -1 AND streak_length >= 5.
-- Verifying the length filter wasn't accidentally removed.
select
    ticker_symbol,
    streak_start,
    streak_end,
    streak_length
from {{ ref('mart_down_streaks') }}
where streak_length < 5
