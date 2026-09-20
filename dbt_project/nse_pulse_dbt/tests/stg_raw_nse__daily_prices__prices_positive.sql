-- Test: open, high, low, close prices must all be strictly positive.
-- A zero or negative price is physically impossible for listed securities and
-- would silently corrupt every return, drawdown, and ratio calculation downstream.
select
    ticker_symbol,
    trade_date,
    open_price,
    high_price,
    low_price,
    close_price
from {{ ref('stg_raw_nse__daily_prices') }}
where
    open_price  <= 0
    or high_price  <= 0
    or low_price   <= 0
    or close_price <= 0
