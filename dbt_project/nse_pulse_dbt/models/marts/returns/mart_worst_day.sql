select
    ticker_symbol,
    asset_class,
    trade_date,
    daily_return
from {{ ref('int_returns') }}
prewhere daily_return is not null
order by daily_return asc
limit 1
