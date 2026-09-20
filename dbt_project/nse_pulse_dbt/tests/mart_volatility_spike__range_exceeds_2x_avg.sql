-- Test: every row in mart_volatility_spike must satisfy range_pct > 2 * avg_range_pct_30d.
-- Self-consistency check on the model's own WHERE clause. If this fails, the
-- filter was changed or the join between int_returns and int_moving_avgs on
-- (ticker_symbol, trade_date) produced mismatched rows.
select
    ticker_symbol,
    trade_date,
    range_pct,
    avg_range_pct_30d
from {{ ref('mart_volatility_spike') }}
where range_pct <= 2 * avg_range_pct_30d
