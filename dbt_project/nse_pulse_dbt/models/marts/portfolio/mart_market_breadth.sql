select
    trade_date,
    up_count,
    down_count,
    tickers_count,
    up_count / tickers_count as pct_up,
    down_count / tickers_count as pct_down
from {{ ref('int_market_daily') }}
order by trade_date
