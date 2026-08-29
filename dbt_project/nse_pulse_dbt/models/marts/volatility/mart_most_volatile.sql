select
    ticker_symbol,
    asset_class,
    stddevSamp(daily_return) as return_volatility
from {{ ref('int_returns') }}
group by ticker_symbol, asset_class
order by return_volatility desc
limit 10