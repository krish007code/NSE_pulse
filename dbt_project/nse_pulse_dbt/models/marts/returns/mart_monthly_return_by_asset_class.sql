with r as (
    select * from {{ ref('int_returns') }}
),
m as (
    select
        asset_class,
        date_trunc('month', trade_date) as trade_month,
        avg(daily_return) as avg_return
    from r
    group by asset_class, date_trunc('month', trade_date)
)
select
    trade_month,
    asset_class,
    avg_return
from m
order by trade_month, asset_class
