-- Test: return_risk (= stddevSamp of daily_return) must be >= 0.
-- Standard deviation is always non-negative. A negative value indicates a
-- numerical issue in ClickHouse's stddevSamp on this data, or the column
-- was mapped incorrectly from int_returns.
select
    ticker_symbol,
    return_risk
from {{ ref('mart_return_to_risk_ratio') }}
where return_risk < 0
