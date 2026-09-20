-- Test: ticker_a must never equal ticker_b in int_pairs_corr.
-- The model uses ticker_a < ticker_b in the JOIN condition to produce unique pairs.
-- A self-pair (ticker_a = ticker_b) would produce a correlation of exactly 1.0
-- and would silently pollute mart_correlated_pairs and mart_inverse_pairs results.
select
    ticker_a,
    ticker_b,
    correlation
from {{ ref('int_pairs_corr') }}
where ticker_a = ticker_b
