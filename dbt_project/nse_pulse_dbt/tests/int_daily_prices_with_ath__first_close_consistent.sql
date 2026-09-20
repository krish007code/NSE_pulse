-- Test: first_close_price must be the same value for every row of the same ticker.
-- first_close_price uses FIRST_VALUE with UNBOUNDED PRECEDING, so it should be
-- a constant per ticker partition. If different rows for the same ticker show
-- different first_close_price values, the window ordering is non-deterministic
-- (likely a missing or incorrect ORDER BY), which would corrupt mart_cumulative_return.
select
    ticker_symbol,
    count(distinct first_close_price) as distinct_first_closes
from {{ ref('int_daily_prices_with_ath') }}
group by ticker_symbol
having count(distinct first_close_price) > 1
