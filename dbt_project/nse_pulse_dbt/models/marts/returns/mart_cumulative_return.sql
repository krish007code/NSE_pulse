select
    ticker_symbol,
    asset_class,
    argMin(close_price, trade_date) as first_close,
    argMax(close_price, trade_date) as last_close,
    (last_close - first_close) / first_close as cumulative_return
from {{ ref('stg_raw_nse__daily_prices') }}
group by ticker_symbol, asset_class
