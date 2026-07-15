select
    ticker_symbol,
    asset_class,
    avg(daily_return) as avg_return,
    stddev(daily_return) as volatility
from {{ ref('int_returns') }}
group by ticker_symbol, asset_class
having avg(daily_return) > 0
order by volatility asc, avg_return desc
limit 5
