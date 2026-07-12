with r as (
    select * from {{ ref('int_returns') }}
)
select
    trade_date,
    count(*) as tickers_count,
    sum(case when daily_return > 0 then 1 else 0 end) as up_count,
    sum(case when daily_return < 0 then 1 else 0 end) as down_count,
    sum(trade_volume) as total_volume,
    avg(daily_return) as avg_return
from r
group by trade_date
