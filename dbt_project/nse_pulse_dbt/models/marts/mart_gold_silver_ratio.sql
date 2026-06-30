-- mart_gold_silver_ratio.sql
SELECT
    trade_date,
    gold_close,
    silver_close,
    gold_silver_ratio,
    -- 365-day rolling mean of the ratio
    AVG(gold_silver_ratio) OVER (
        ORDER BY trade_date 
        ROWS BETWEEN 364 PRECEDING AND CURRENT ROW
    ) AS rolling_mean_365d,
    -- 365-day rolling standard deviation of the ratio
    stddevSamp(gold_silver_ratio) OVER (
        ORDER BY trade_date 
        ROWS BETWEEN 364 PRECEDING AND CURRENT ROW
    ) AS rolling_stddev_365d
FROM {{ ref('int_gold_silver_daily') }}