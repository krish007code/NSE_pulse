-- Test: days_tracked must be >= 1 for every ticker.
-- A ticker with zero tracked days cannot exist (it would have no rows in staging).
-- A negative count would mean count(*) malfunctioned, which is worth surfacing.
select
    ticker_symbol,
    days_tracked
from {{ ref('mart_ticker_date_summary') }}
where days_tracked < 1
