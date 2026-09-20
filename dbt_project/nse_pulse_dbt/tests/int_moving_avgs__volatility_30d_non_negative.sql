-- Test: volatility_30d (stddevSamp of daily_return over 30 rows) must be >= 0.
-- Standard deviation is always non-negative by definition.
-- A negative value would indicate a numerical/overflow issue in ClickHouse's
-- stddevSamp function on this dataset, which is worth surfacing immediately.
select
    ticker_symbol,
    trade_date,
    volatility_30d
from {{ ref('int_moving_avgs') }}
where volatility_30d is not null
  and volatility_30d < 0
