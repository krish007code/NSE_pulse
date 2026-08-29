with ytd as (
    select
        ticker_symbol,
        asset_class,
        avg(daily_return) as ticker_avg_return
    from {{ ref('int_returns') }}
    where trade_date >= dateTrunc('year', (select max(trade_date) from {{ ref('int_returns') }}))
    group by ticker_symbol, asset_class
),
ranked as (
    select
        ticker_symbol,
        asset_class,
        ticker_avg_return,
        avg(ticker_avg_return) over (partition by asset_class) as class_avg_return
    from ytd
)
select
    ticker_symbol,
    asset_class,
    ticker_avg_return,
    class_avg_return
from ranked
where ticker_avg_return > class_avg_return