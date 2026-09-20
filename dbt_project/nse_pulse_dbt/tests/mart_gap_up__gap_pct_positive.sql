-- Test: every row in mart_gap_up must have gap_pct > 0.02 (the model's filter).
-- This is a self-consistency test: if gap_pct <= 0.02 appears here, the WHERE
-- clause in the model was changed or the column expression for gap_pct changed
-- sign, silently inverting the gap direction.
select
    ticker_symbol,
    trade_date,
    gap_pct
from {{ ref('mart_gap_up') }}
where gap_pct <= 0.02
