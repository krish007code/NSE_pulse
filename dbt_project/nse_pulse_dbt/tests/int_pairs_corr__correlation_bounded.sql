-- Test: Pearson correlation must lie within [-1.0, 1.0].
-- Mathematically this is guaranteed, but floating-point precision in ClickHouse's
-- corr() function can occasionally produce values like 1.0000000001 or -1.0000001.
-- We use a small tolerance (1e-6) to allow for float rounding without masking
-- true numerical errors.
select
    ticker_a,
    ticker_b,
    correlation,
    days_overlap
from {{ ref('int_pairs_corr') }}
where correlation < -1.000001
   or correlation >  1.000001
