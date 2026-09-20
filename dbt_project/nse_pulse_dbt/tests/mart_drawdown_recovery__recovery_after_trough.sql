-- Test: recovery_date, when not null, must be strictly after trough_date.
-- The recovery query filters WHERE trade_date > trough_date, so a recovery_date
-- <= trough_date means minIf() evaluated incorrectly or the date comparison
-- in the WHERE clause was changed from > to >=.
select
    ticker_symbol,
    trough_date,
    recovery_date,
    days_to_recover
from {{ ref('mart_drawdown_recovery') }}
where recovery_date is not null
  and recovery_date <= trough_date
