-- Test: (ticker_symbol, trade_date) must be unique in int_returns.
-- int_returns is a pass-through of stg_raw_nse__daily_prices with derived columns.
-- A duplicate grain here would cause all window functions (moving averages,
-- streaks, cumulative returns) to double-count rows silently.
select
    ticker_symbol,
    trade_date,
    count(*) as row_count
from {{ ref('int_returns') }}
group by ticker_symbol, trade_date
having count(*) > 1
