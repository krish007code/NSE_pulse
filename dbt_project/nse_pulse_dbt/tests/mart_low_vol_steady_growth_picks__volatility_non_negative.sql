-- Test: volatility (stddevPop of daily_return) must be >= 0.
-- Standard deviation is non-negative by definition.
select
    ticker_symbol,
    volatility
from {{ ref('mart_low_vol_steady_growth_picks') }}
where volatility < 0
