-- int_gold_silver_daily.sql
WITH gold_prices AS (
    SELECT trade_date, close_price AS gold_close
    FROM {{ ref('stg_raw_nse__daily_prices') }}
    WHERE ticker_symbol = 'GOLD'
),
silver_prices AS (
    SELECT trade_date, close_price AS silver_close
    FROM {{ ref('stg_raw_nse__daily_prices') }}
    WHERE ticker_symbol = 'SILVER'
)
SELECT
    g.trade_date,
    g.gold_close,
    s.silver_close,
    (g.gold_close / s.silver_close) AS gold_silver_ratio
FROM gold_prices g
INNER JOIN silver_prices s ON g.trade_date = s.trade_date