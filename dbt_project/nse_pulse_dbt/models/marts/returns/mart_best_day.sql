select
    ticker_symbol,
    asset_class,
    trade_date,
    daily_return
from {{ ref('int_returns') }}
where daily_return is not null
order by daily_return desc
limit 1