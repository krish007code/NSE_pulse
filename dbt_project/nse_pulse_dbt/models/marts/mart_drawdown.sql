SELECT
    trade_date,
    ticker_symbol,
    close_price,
    rolling_max_365d,
    ((close_price - rolling_max_365d) / rolling_max_365d) * 100 AS drawdown_pct
FROM {{ ref('int_daily_prices_with_ath') }}
WHERE rolling_max_365d IS NOT NULL