-- Test: first_date must be <= last_date for every ticker in the summary.
-- This is the mart-level complement of the intermediate test on int_ticker_summary.
-- If this fails here but the intermediate test passes it means the mart's SELECT
-- list somehow mapped columns incorrectly from int_ticker_summary.
select
    ticker_symbol,
    first_date,
    last_date
from {{ ref('mart_ticker_date_summary') }}
where first_date > last_date
