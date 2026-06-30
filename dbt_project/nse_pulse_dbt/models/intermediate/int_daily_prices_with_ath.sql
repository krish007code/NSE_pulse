SELECT
    trade_date,
    ticker_symbol,
    asset_class,
    close_price,
    MAX(close_price) OVER (
        PARTITION BY ticker_symbol 
        ORDER BY trade_date 
        ROWS BETWEEN 364 PRECEDING AND CURRENT ROW
    ) AS rolling_max_365d,
    FIRST_VALUE(close_price) OVER (
        PARTITION BY ticker_symbol 
        ORDER BY trade_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW 
    ) AS first_close_price
FROM {{ ref('stg_raw_nse__daily_prices') }}