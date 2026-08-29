with t as (
    select
        ticker_symbol,
        asset_class,
        stddevSamp(daily_return) as stddev_return
    from {{ ref('int_returns') }}
    group by ticker_symbol, asset_class
)
select
    asset_class,
    avg(stddev_return) as avg_volatility
from t
group by asset_class
order by avg_volatility desc