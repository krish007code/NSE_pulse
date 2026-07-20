with max_date_cte as (
    select max(trade_date) as max_date from {{ ref('int_returns') }}
),
r as (
    select *
    from {{ ref('int_returns') }}
    where trade_date >= (select max_date from max_date_cte) - interval 90 day
),
vol as (
    select
        asset_class,
        stddevPop(daily_return) as volatility_90d
    from r
    group by asset_class
),
dd as (
    select
        asset_class,
        min(drawdown_pct) as max_drawdown_90d
    from {{ ref('int_drawdown') }}
    where trade_date >= (select max_date from max_date_cte) - interval 90 day
    group by asset_class
)
select
    v.asset_class,
    v.volatility_90d,
    d.max_drawdown_90d
from vol v
join dd d on d.asset_class = v.asset_class
order by v.volatility_90d desc, d.max_drawdown_90d asc