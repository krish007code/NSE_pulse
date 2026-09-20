-- Test: mart_best_day is filtered from ORDER BY daily_return DESC LIMIT 1,
-- so the single returned row must have a non-negative daily_return.
-- A negative value would mean every single day in the dataset was a down day
-- for every ticker, which is extremely unlikely and worth alerting on.
select
    ticker_symbol,
    trade_date,
    daily_return
from {{ ref('mart_best_day') }}
where daily_return < 0
