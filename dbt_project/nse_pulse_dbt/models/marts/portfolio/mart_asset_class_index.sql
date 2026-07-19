with r as (
    select * from {{ ref('int_returns') }}
),
daily as (
    select
        asset_class,
        trade_date,
        avg(daily_return) as avg_return
    from r
    group by asset_class, trade_date
)
select
    asset_class,
    trade_date,
    exp(sum(ln(1 + avg_return)) over (partition by asset_class order by trade_date rows between unbounded preceding and current row)) as index_value
from daily
