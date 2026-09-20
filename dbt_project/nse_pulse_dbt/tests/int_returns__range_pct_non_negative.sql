-- Test: range_pct (= (high - low) / open) must be >= 0 whenever open_price != 0.
-- high >= low is guaranteed by the staging test, so the numerator is always
-- non-negative. A negative range_pct means either the staging invariant was
-- violated or the formula in int_returns was changed incorrectly.
select
    ticker_symbol,
    trade_date,
    open_price,
    high_price,
    low_price,
    range_pct
from {{ ref('int_returns') }}
where range_pct is not null
  and range_pct < 0
