-- Test: rolling_max_365d must be >= close_price for every row.
-- rolling_max_365d is a MAX() window over the current row and up to 364 prior rows.
-- By definition, the window maximum can never be less than the current row value.
-- Violation means the window function or its ROWS frame is misconfigured.
select
    ticker_symbol,
    trade_date,
    close_price,
    rolling_max_365d
from {{ ref('int_daily_prices_with_ath') }}
where rolling_max_365d < close_price
