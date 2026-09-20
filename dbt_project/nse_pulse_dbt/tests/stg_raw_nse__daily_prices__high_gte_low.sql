-- Test: high_price must be >= low_price on every row.
-- A crossed OHLC bar (high < low) means the raw data is corrupt or columns were
-- swapped during ingestion. range_pct in int_returns would become negative,
-- poisoning volatility and choppiness calculations.
select
    ticker_symbol,
    trade_date,
    high_price,
    low_price
from {{ ref('stg_raw_nse__daily_prices') }}
where high_price < low_price
