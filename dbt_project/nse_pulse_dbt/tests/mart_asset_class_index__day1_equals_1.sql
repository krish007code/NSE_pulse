-- Test: for every asset_class, the row with the earliest trade_date must have
-- index_value exactly equal to 1.0.
-- Day 1 has no prior day to compound from (daily_return is NULL for all tickers
-- on their first row). The COALESCE in the model sets this to 1.0 as the base
-- value of the index. Any other value on day 1 means either:
--   (a) the COALESCE was removed, or
--   (b) some tickers had a non-NULL daily_return on their very first date,
--       which would mean a prev_close existed before the dataset starts (a gap
--       in the source data where history was loaded mid-series).
select
    asset_class,
    trade_date as first_date,
    index_value
from {{ ref('mart_asset_class_index') }}
where trade_date = (
    select min(trade_date)
    from {{ ref('mart_asset_class_index') }} inner_t
    where inner_t.asset_class = mart_asset_class_index.asset_class
)
and index_value != 1.0
