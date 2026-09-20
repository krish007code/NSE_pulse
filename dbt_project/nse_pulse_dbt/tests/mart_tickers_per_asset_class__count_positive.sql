-- Test: tickers_in_class must be >= 1 for every asset class row.
-- uniqExact() returns 0 only for an empty group, which can't appear after a
-- GROUP BY on non-null rows. A zero here means data was silently dropped
-- upstream, causing an asset class to show as having no tickers.
select
    asset_class,
    tickers_in_class
from {{ ref('mart_tickers_per_asset_class') }}
where tickers_in_class < 1
