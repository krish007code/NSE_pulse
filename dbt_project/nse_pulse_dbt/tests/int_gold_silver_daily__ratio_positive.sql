-- Test: gold_silver_ratio must be strictly positive.
-- ratio = gold_close / silver_close. Both prices are positive (guaranteed by
-- the staging test), so the ratio must always be > 0. A zero or negative ratio
-- means either silver_close slipped through as zero (division producing Inf/NaN
-- in ClickHouse) or the join produced a NULL that evaluated unexpectedly.
select
    trade_date,
    gold_close,
    silver_close,
    gold_silver_ratio
from {{ ref('int_gold_silver_daily') }}
where gold_silver_ratio is null
   or gold_silver_ratio <= 0
