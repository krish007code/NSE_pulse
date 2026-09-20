-- Test: start_price and end_price must be strictly positive.
-- Both are argMin/argMax of close_price within the YTD window.
-- Non-positive prices would make ytd_return mathematically incorrect.
select
    ticker_symbol,
    start_price,
    end_price
from {{ ref('mart_ytd_return') }}
where start_price <= 0
   or end_price <= 0
