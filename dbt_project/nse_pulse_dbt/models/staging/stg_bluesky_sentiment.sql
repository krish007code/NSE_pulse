with source as (
    -- FINAL forces ClickHouse's ReplacingMergeTree to deduplicate on read.
    -- The bluesky_sentiment table is keyed on (ticker, created_at); since all
    -- duplicate URIs share identical (ticker, created_at) values, FINAL eliminates
    -- them without needing a separate dedup step.
    select * from {{ source('raw_nse', 'bluesky_sentiment') }} FINAL
),

renamed as (
    select
        uri as post_uri,
        ticker as ticker_symbol,
        created_at as posted_at,
        sentiment_compound,
        sentiment_label,
        engagement_score,
        source as data_source
    from source
    where is_finance_relevant = true
)

select * from renamed