-- Test: ticker_symbol must be unique in int_ticker_summary.
-- This model is a GROUP BY ticker_symbol — one summary row per ticker.
-- A duplicate ticker here would corrupt mart_latest_close, mart_ticker_date_summary,
-- and mart_equal_weight_portfolio (which divides by count of tickers).
select
    ticker_symbol,
    count(*) as row_count
from {{ ref('int_ticker_summary') }}
group by ticker_symbol
having count(*) > 1
