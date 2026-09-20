-- Test: engagement_score must be >= 0.
-- Engagement (likes, reposts, replies) is a count-based metric that cannot be
-- negative. A negative value means something went wrong in the scoring or
-- aggregation step in the ingestion pipeline.
select
    post_uri,
    ticker_symbol,
    posted_at,
    engagement_score
from {{ ref('stg_bluesky_sentiment') }}
where engagement_score < 0
