with source as (

    -- FINAL forces ClickHouse's ReplacingMergeTree to deduplicate parts on read,
    -- ensuring no duplicate (ticker, Date) rows reach dbt even if the background
    -- merge hasn't compacted all parts yet after a load.
    select * from {{ source('raw_nse', 'ohlcv') }} FINAL

),
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
    -- Exclude forward-filled placeholder rows where the loader wrote all-zero
    -- OHLCV values for tickers with no trade data yet. A close_price of 0 is
    -- physically impossible for a listed security and would corrupt returns,
    -- drawdowns, and any ratio that divides by price.
    where Close > 0
)
select * from renamed
