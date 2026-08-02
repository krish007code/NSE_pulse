select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price,
    avg_close_7d,
    avg_close_30d
from {{ ref('int_moving_avgs') }}
