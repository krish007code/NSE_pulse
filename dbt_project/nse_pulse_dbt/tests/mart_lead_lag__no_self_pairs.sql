-- Test: leader and follower must never be the same ticker.
-- The model uses WHERE b.ticker_symbol != a.ticker_symbol, which should
-- exclude all self-pairs. A self-pair would produce a lead_lag_correlation
-- that equals the autocorrelation at lag-1 for that ticker, contaminating
-- any downstream analysis of cross-ticker relationships.
select
    leader,
    follower,
    lead_lag_correlation
from {{ ref('mart_lead_lag') }}
where leader = follower
