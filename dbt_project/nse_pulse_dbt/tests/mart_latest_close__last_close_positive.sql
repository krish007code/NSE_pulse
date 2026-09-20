-- Test: last_close must be strictly positive.
-- last_close = argMax(close_price, trade_date) from int_ticker_summary.
-- Close prices are guaranteed > 0 by the staging test, so a non-positive
-- value here means the argMax selected a corrupt or zero-priced row.
select
    ticker_symbol,
    last_close,
    last_date
from {{ ref('mart_latest_close') }}
where last_close <= 0
