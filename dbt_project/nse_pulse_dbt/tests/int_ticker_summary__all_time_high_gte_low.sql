-- Test: all_time_high must be >= all_time_low for every ticker.
-- all_time_high = max(high_price), all_time_low = min(low_price).
-- The staging test already guarantees high >= low on each row, so the
-- aggregate max(high) can never be less than min(low). Violation here
-- would indicate the aggregation columns were swapped.
select
    ticker_symbol,
    all_time_high,
    all_time_low
from {{ ref('int_ticker_summary') }}
where all_time_high < all_time_low
