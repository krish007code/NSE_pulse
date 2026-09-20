-- Test: mart_worst_day is ORDER BY daily_return ASC LIMIT 1,
-- so the returned row must have a non-positive daily_return.
-- A positive value would mean every single day was an up day, which would be
-- a sign the daily_return calculation is inverted or the filter is broken.
select
    ticker_symbol,
    trade_date,
    daily_return
from {{ ref('mart_worst_day') }}
where daily_return > 0
