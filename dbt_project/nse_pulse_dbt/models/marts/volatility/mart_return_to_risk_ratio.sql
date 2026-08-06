select
    ticker_symbol,
    asset_class,
    avg(daily_return) as avg_return,
    stddev(daily_return) as return_risk,
    case when stddev(daily_return) != 0
        then avg(daily_return) / stddev(daily_return) end as return_to_risk_ratio
from {{ ref('int_returns') }}
group by ticker_symbol, asset_class
order by return_to_risk_ratio desc
