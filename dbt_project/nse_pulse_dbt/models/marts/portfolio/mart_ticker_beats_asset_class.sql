with t as (
    select
        ticker_symbol,
        asset_class,
        avg(daily_return) as ticker_avg_return
    from {{ ref('int_returns') }}
    where trade_date >= date_trunc('year', current_date)
    group by ticker_symbol, asset_class
),
c as (
    select
        asset_class,
        avg(daily_return) as class_avg_return
    from {{ ref('int_returns') }}
    where trade_date >= date_trunc('year', current_date)
    group by asset_class
)
select
    t.ticker_symbol,
    t.asset_class,
    t.ticker_avg_return,
    c.class_avg_return
from t
join c on c.asset_class = t.asset_class
where t.ticker_avg_return > c.class_avg_return
