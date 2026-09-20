-- Test: every row must have ticker_avg_return > class_avg_return.
-- The model's WHERE clause is exactly this condition. Failure means the filter
-- was removed or the window function computing class_avg_return is using a
-- broader partition than just asset_class (e.g. a missing PARTITION BY).
select
    ticker_symbol,
    asset_class,
    ticker_avg_return,
    class_avg_return
from {{ ref('mart_ticker_beats_asset_class') }}
where ticker_avg_return <= class_avg_return
