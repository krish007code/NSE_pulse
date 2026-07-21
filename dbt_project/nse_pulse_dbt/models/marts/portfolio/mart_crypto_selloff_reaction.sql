with crypto as (
    select
        trade_date,
        avg(daily_return) as crypto_return
    from {{ ref('int_returns') }}
    where asset_class = 'crypto'
    group by trade_date
    having avg(daily_return) < -0.05
),
others as (
    select
        asset_class,
        trade_date,
        avg(daily_return) as avg_return
    from {{ ref('int_returns') }}
    where asset_class != 'crypto'
    group by asset_class, trade_date
)
select
    c.trade_date,
    c.crypto_return,
    o.asset_class,
    o.avg_return
from crypto c
join others o on o.trade_date = c.trade_date
order by c.trade_date
