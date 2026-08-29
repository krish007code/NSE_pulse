select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price,
    avg_close_30d
from {{ ref('int_moving_avgs') }}
where close_price > avg_close_30d
order by trade_date desc
limit 1 by ticker_symbol