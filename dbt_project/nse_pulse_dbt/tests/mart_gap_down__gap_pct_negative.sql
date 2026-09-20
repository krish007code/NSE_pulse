-- Test: every row in mart_gap_down must have gap_pct < -0.02 (the model's filter).
-- Symmetric check to mart_gap_up. A positive or zero gap_pct here would mean
-- the gap_down filter is broken or the gap_pct sign convention was reversed.
select
    ticker_symbol,
    trade_date,
    gap_pct
from {{ ref('mart_gap_down') }}
where gap_pct >= -0.02
