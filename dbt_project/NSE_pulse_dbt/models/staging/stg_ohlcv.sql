select
    Date as date,
    Open as open_price,
    High as high_price,
    Low as low_price,
    Close as close_price,
    Volume as volume,
    ticker,
    asset_class
from {{ source('bronze', 'ohlcv') }}