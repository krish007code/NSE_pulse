-- Test: pct_from_low = (last_close - all_time_low) / all_time_low must be >= 0.
-- all_time_low = min(low_price), so last_close >= all_time_low always (any
-- recent close is at least as high as the lowest price ever recorded).
-- A negative pct_from_low means all_time_low > last_close, which is impossible
-- unless the min/max columns in int_ticker_summary were swapped.
select
    ticker_symbol,
    last_close,
    all_time_low,
    pct_from_low
from {{ ref('mart_near_all_time_high_low') }}
where pct_from_low < 0
