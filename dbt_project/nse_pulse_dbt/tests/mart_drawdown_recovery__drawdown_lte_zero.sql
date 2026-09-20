-- Test: drawdown_pct at the trough must be <= 0.
-- This is the minimum drawdown_pct per ticker from int_drawdown, which is
-- guaranteed <= 0 by the intermediate test. A positive value here means the
-- trough selection logic selected a non-trough row.
select
    ticker_symbol,
    trough_date,
    drawdown_pct
from {{ ref('mart_drawdown_recovery') }}
where drawdown_pct > 0
