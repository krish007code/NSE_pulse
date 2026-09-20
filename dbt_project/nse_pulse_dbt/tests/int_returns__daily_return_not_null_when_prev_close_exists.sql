-- Test: when prev_close is populated and non-zero, daily_return must not be null.
-- The formula is (close - prev_close) / prev_close. If both inputs are valid
-- the result must be a finite number. A null here means the CASE expression
-- has an unhandled branch and downstream cumulative return calculations will
-- silently drop rows.
select
    ticker_symbol,
    trade_date,
    prev_close,
    close_price,
    daily_return
from {{ ref('int_returns') }}
where prev_close is not null
  and prev_close != 0
  and daily_return is null
