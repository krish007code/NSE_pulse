select
    ticker_symbol,
    asset_class,
    trade_date,
    volatility_30d
from {{ ref('int_moving_avgs') }}
