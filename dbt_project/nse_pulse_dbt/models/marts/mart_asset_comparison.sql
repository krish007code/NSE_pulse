-- mart_asset_comparison.sql
SELECT
    trade_date,
    ticker_symbol,
    asset_class,
    close_price,
    -- Normalized returns indexed to 100
    (close_price / first_close_price) * 100 AS indexed_return
FROM {{ ref('int_daily_prices_with_ath') }}