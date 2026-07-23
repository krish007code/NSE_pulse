with r as (
    select *
    from {{ ref('int_returns') }}
    where trade_date >= dateadd(month, -3, current_date)
)
select
    asset_class,
    avg(daily_return) as avg_return,
    stddev(daily_return) as return_risk,
    case when stddev(daily_return) != 0
        then avg(daily_return) / stddev(daily_return) end as risk_adjusted_return
from r
group by asset_class
order by risk_adjusted_return desc
