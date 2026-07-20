-- models/staging/stg_raw_nse__daily_prices.sql
with
    source as (select * from {{ source("raw_nse", "ohlcv") }}),
    renamed as (
        select
            ticker as ticker_symbol,
            asset_class,
            Date as trade_date,
            Open as open_price,
            High as high_price,
            Low as low_price,
            Close as close_price,
            Volume as trade_volume
        from source
    )
select *
from renamed
