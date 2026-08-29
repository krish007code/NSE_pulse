select
    ticker_symbol,
    asset_class,
    avg(daily_return) as avg_return,
    stddevSamp(daily_return) as return_risk,
    -- nullIf converts 0 to NULL, safely avoiding divide-by-zero errors
    avg(daily_return) / nullIf(stddevSamp(daily_return), 0) as return_to_risk_ratio
from {{ ref('int_returns') }}
group by ticker_symbol, asset_class
order by return_to_risk_ratio desc