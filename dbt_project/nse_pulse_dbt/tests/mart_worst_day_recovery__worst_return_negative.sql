-- Test: worst_return must be < 0 for every ticker.
-- worst_return = min(daily_return) per ticker, filtered from non-null returns.
-- If a ticker's worst day had a positive return, it means all its daily returns
-- were positive — an extraordinary circumstance worth surfacing as an alert.
select
    ticker_symbol,
    worst_date,
    worst_return
from {{ ref('mart_worst_day_recovery') }}
where worst_return >= 0
