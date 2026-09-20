-- Test: sentiment_compound must lie within [-1.0, 1.0].
-- Standard compound scores (VADER, FinBERT etc.) are always bounded in this range.
-- A value outside [-1, 1] means either the scoring model changed its output scale,
-- or a non-sentiment column was mapped here during ingestion.
select
    post_uri,
    ticker_symbol,
    posted_at,
    sentiment_compound
from {{ ref('stg_bluesky_sentiment') }}
where sentiment_compound < -1.0
   or sentiment_compound > 1.0
