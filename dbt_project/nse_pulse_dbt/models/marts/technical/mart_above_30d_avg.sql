select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price,
    avg_close_30d
from {{ ref('int_moving_avgs') }}
where close_price > avg_close_30d
qualify row_number() over (partition by ticker_symbol order by trade_date desc) = 1
