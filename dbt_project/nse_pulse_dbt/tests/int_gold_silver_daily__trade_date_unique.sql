-- Test: trade_date must be unique in int_gold_silver_daily.
-- This model is an INNER JOIN of GOLD and SILVER rows on trade_date.
-- If either ticker had duplicate rows in staging (caught by stg unique test),
-- the join would produce a cross-product. A duplicate date here is an early
-- warning that staging duplicate protection has been bypassed.
select
    trade_date,
    count(*) as row_count
from {{ ref('int_gold_silver_daily') }}
group by trade_date
having count(*) > 1
