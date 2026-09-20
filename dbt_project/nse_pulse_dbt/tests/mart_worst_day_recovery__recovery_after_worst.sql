-- Test: recovery_date, when not null, must be strictly after worst_date.
-- The recovery query uses minIf(trade_date, trade_date > worst_date AND ...).
-- A recovery_date <= worst_date means the date comparison in the join is broken.
select
    ticker_symbol,
    worst_date,
    recovery_date,
    days_to_recover
from {{ ref('mart_worst_day_recovery') }}
where recovery_date is not null
  and recovery_date <= worst_date
