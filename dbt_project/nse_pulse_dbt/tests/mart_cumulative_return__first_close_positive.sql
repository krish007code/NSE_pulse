-- Test: first_close and last_close must both be strictly positive.
-- They come from argMin/argMax on close_price, which the staging test guarantees > 0.
-- A non-positive value here means a zero or negative close slipped through,
-- which would also make the cumulative_return formula meaningless (div-by-zero
-- or inverted sign).
select
    ticker_symbol,
    first_close,
    last_close,
    cumulative_return
from {{ ref('mart_cumulative_return') }}
where first_close <= 0
   or last_close <= 0
