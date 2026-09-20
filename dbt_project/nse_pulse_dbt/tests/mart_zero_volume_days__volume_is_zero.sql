-- Test: every row in mart_zero_volume_days must actually have trade_volume = 0.
-- The model's WHERE clause filters on trade_volume = 0, so any non-zero volume
-- row here means the filter logic was changed or inverted accidentally.
-- This is a logic self-consistency test: the data quality mart itself must be correct.
select
    ticker_symbol,
    trade_date,
    trade_volume
from {{ ref('mart_zero_volume_days') }}
where trade_volume != 0
