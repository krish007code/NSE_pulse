with r as (
    select *
    from {{ ref('int_returns') }}
    where trade_date >= dateadd(day, -90, current_date)
),
vol as (
    select
        asset_class,
        stddev(daily_return) as volatility_90d
    from r
    group by asset_class
),
dd as (
    select
        asset_class,
        min(drawdown_pct) as max_drawdown_90d
    from {{ ref('int_drawdown') }}
    where trade_date >= dateadd(day, -90, current_date)
    group by asset_class
)
select
    v.asset_class,
    v.volatility_90d,
    d.max_drawdown_90d
from vol v
join dd d on d.asset_class = v.asset_class
order by v.volatility_90d desc, d.max_drawdown_90d asc
