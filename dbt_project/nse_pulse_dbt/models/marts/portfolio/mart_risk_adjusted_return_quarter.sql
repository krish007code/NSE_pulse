with r as (
    select *
    from {{ ref('int_returns') }}
    where trade_date >= subtractMonths((select max(trade_date) from {{ ref('int_returns') }}), 3)
)
select
    asset_class,
    avg(daily_return) as avg_return,
    stddevSamp(daily_return) as return_risk,
    avg(daily_return) / nullIf(stddevSamp(daily_return), 0) as risk_adjusted_return
from r
group by asset_class
order by risk_adjusted_return desc