-- Test: post_volume (count(*)) must be >= 1 on every row.
-- A GROUP BY can only produce a row if at least one input row contributed.
-- A zero or negative post_volume would mean COUNT(*) malfunctioned.
--
-- NOTE: This test will also fail at runtime until the GROUP BY bug is fixed.
select
    ticker_symbol,
    sentiment_date,
    post_volume
from {{ ref('mart_daily_sentiment') }}
where post_volume < 1
