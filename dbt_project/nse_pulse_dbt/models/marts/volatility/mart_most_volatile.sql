select
    ticker_symbol,
    asset_class,
    stddev(daily_return) as return_volatility
from {{ ref('int_returns') }}
group by ticker_symbol, asset_class
order by return_volatility desc
limit 10
