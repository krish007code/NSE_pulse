-- Test: positive_months must be <= total_months for every ticker.
-- positive_months = count of months with avg_return > 0.
-- It is a subset of total_months, so it can never exceed it.
-- Violation means the counting logic has an off-by-one or the GROUP BY
-- produced a different number of rows than expected.
select
    ticker_symbol,
    positive_months,
    total_months
from {{ ref('mart_consistent_growth') }}
where positive_months > total_months
