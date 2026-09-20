-- Test: every missing_date in mart_missing_days must fall within the last 30 days
-- from the most recent trade date in the price data.
-- The model's date universe is explicitly built from the last 30 days, so a
-- missing_date outside that window means the cross-join logic leaked rows from
-- an earlier period, or the max_date subquery returned an unexpected value.
select
    ticker_symbol,
    missing_date
from {{ ref('mart_missing_days') }}
where missing_date < (
    select max(trade_date) from {{ ref('stg_raw_nse__daily_prices') }}
) - interval 30 day
