-- Test: pct_from_high = (last_close - all_time_high) / all_time_high must be <= 0.
-- last_close can at most equal all_time_high (i.e. today IS the all-time high),
-- giving pct_from_high = 0. It can never exceed the all-time high, so a positive
-- pct_from_high means all_time_high < last_close, which contradicts the definition
-- of all_time_high = max(high_price) across the full history.
select
    ticker_symbol,
    last_close,
    all_time_high,
    pct_from_high
from {{ ref('mart_near_all_time_high_low') }}
where pct_from_high > 0
