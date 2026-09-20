-- Test: close_price must be > avg_close_30d on every row in mart_above_30d_avg.
-- The model's WHERE clause is exactly this condition. If a row appears with
-- close <= avg_close_30d, the filter was silently broken or removed.
select
    ticker_symbol,
    trade_date,
    close_price,
    avg_close_30d
from {{ ref('mart_above_30d_avg') }}
where close_price <= avg_close_30d
