-- Test: every row in mart_correlated_pairs must have correlation > 0.
-- This mart is ORDER BY correlation DESC LIMIT 10 — the "most positively
-- correlated" pairs. A negative or zero correlation in the top-10 means
-- every pair in the dataset has non-positive correlation, which is highly
-- unusual and should surface as a data quality alert rather than silently
-- showing negative correlations in a "correlated pairs" mart.
select
    ticker_a,
    ticker_b,
    correlation
from {{ ref('mart_correlated_pairs') }}
where correlation <= 0
