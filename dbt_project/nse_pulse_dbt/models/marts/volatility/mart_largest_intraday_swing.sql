select
    ticker_symbol,
    asset_class,
    trade_date,
    range_pct
from {{ ref('int_returns') }}
order by range_pct desc
limit 1
