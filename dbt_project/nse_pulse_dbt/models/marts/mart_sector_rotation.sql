-- mart_sector_rotation.sql
WITH weekly_averages AS (
    SELECT
        toStartOfWeek(trade_date) AS trade_week,
        asset_class,
        AVG(close_price) AS avg_close_price
    FROM {{ ref('stg_raw_nse__daily_prices') }}
    GROUP BY 
        trade_week, 
        asset_class
),
weekly_lag AS (
    SELECT
        trade_week,
        asset_class,
        avg_close_price,
        lagInFrame(avg_close_price) OVER (
            PARTITION BY asset_class 
            ORDER BY trade_week
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS prev_week_avg_close
    FROM weekly_averages
)
SELECT
    trade_week,
    asset_class,
    avg_close_price,
    ((avg_close_price - prev_week_avg_close) / prev_week_avg_close) * 100 AS wow_pct_change
FROM weekly_lag
WHERE prev_week_avg_close IS NOT NULL