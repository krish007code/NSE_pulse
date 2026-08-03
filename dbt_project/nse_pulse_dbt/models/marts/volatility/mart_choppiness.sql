with d as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        case when daily_return > 0 then 1 when daily_return < 0 then -1 else 0 end as direction
    from {{ ref('int_returns') }}
),
flips as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        direction,
        lag(direction) over (partition by ticker_symbol order by trade_date) as prev_direction
    from d
)
select
    ticker_symbol,
    asset_class,
    sum(case when direction != prev_direction then 1 else 0 end) as flip_count,
    count(*) as total_days,
    sum(case when direction != prev_direction then 1 else 0 end) / count(*) as choppiness_ratio
from flips
group by ticker_symbol, asset_class
order by choppiness_ratio desc
