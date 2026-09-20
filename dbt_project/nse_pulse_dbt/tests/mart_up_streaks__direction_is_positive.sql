-- Test: mart_up_streaks pulls from int_streaks WHERE direction = 1.
-- Every row here must only have streak_length >= 5 (the model's filter).
-- A shorter streak slipping through means the WHERE clause was loosened.
select
    ticker_symbol,
    streak_start,
    streak_end,
    streak_length
from {{ ref('mart_up_streaks') }}
where streak_length < 5
