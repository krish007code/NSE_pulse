-- Test: every row in mart_inverse_pairs must have correlation < 0.
-- This mart is ORDER BY correlation ASC LIMIT 10 — the "most negatively
-- correlated" pairs. A positive correlation here means the entire universe
-- has no negatively correlated pairs, which should be flagged explicitly
-- rather than silently surfacing positive correlations in an "inverse pairs" mart.
select
    ticker_a,
    ticker_b,
    correlation
from {{ ref('mart_inverse_pairs') }}
where correlation >= 0
