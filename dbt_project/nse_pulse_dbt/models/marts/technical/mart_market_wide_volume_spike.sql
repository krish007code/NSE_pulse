select
    trade_date,
    total_volume
from {{ ref('int_market_daily') }}
order by total_volume desc
limit 10
