select
    asset_class,
    avg(daily_return) as avg_daily_return,
    stddevSampStable(daily_return) as return_stddev
from {{ ref('int_returns') }}
group by asset_class
