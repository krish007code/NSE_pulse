-- Test: avg_close_7d must lie within [min(close), max(close)] for its ticker.
-- An average over a rolling window of actual close prices cannot exceed the
-- all-time high or fall below the all-time low for that ticker.
-- Violation almost certainly means the partition or window frame is wrong.
select
    m.ticker_symbol,
    m.trade_date,
    m.avg_close_7d,
    t.min_close,
    t.max_close
from {{ ref('int_moving_avgs') }} m
join (
    select
        ticker_symbol,
        min(close_price) as min_close,
        max(close_price) as max_close
    from {{ ref('stg_raw_nse__daily_prices') }}
    group by ticker_symbol
) t on t.ticker_symbol = m.ticker_symbol
where m.avg_close_7d < t.min_close
   or m.avg_close_7d > t.max_close
