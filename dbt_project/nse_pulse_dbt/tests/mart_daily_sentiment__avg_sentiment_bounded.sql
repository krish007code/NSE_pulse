-- Test: avg_sentiment (avg of sentiment_compound) must lie within [-1.0, 1.0].
-- The average of values in [-1, 1] is itself in [-1, 1].
-- Violation means a non-compound-score value was aggregated, or the source
-- compound scores slipped past the staging bounds check.
--
-- NOTE: This test will fail at runtime until the GROUP BY bug in mart_daily_sentiment
-- is fixed (GROUP BY ticker → should be GROUP BY ticker_symbol).
select
    ticker_symbol,
    sentiment_date,
    avg_sentiment
from {{ ref('mart_daily_sentiment') }}
where avg_sentiment < -1.0
   or avg_sentiment > 1.0
