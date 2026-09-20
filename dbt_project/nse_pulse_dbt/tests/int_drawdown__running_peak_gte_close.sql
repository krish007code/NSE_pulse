-- Test: running_peak must be >= close_price on every row.
-- running_peak is a cumulative MAX window. By definition it can never be less
-- than the current row's close. Violation means the window frame is wrong.
select
    ticker_symbol,
    trade_date,
    close_price,
    running_peak
from {{ ref('int_drawdown') }}
where running_peak < close_price
