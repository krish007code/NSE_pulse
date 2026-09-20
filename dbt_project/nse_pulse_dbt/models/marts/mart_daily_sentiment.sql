select
    ticker_symbol,
    toDate(posted_at) as sentiment_date,
    avg(sentiment_compound) as avg_sentiment,
    stddevPop(sentiment_compound) as sentiment_volatility,
    countIf(sentiment_label = 'positive') as positive_count,
    countIf(sentiment_label = 'negative') as negative_count,
    count(*) as post_volume,
    sum(engagement_score) as total_engagement
from {{ref('stg_bluesky_sentiment')}}
group by ticker_symbol, sentiment_date
order by ticker_symbol, sentiment_date