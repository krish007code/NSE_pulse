select
    ticker_symbol,
    asset_class,
    streak_start,
    streak_end,
    streak_length
from {{ ref('int_streaks') }}
where direction = 1
and streak_length >= 5
order by streak_length desc
