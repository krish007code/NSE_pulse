with source as (
    select * from {{ source('raw_nse', 'bluesky_sentiment') }}
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