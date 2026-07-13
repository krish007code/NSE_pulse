with r as (
    select * from {{ ref('int_returns') }}
),
d as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        daily_return,
        case when daily_return > 0 then 1 when daily_return < 0 then -1 else 0 end as direction
    from r
),
g as (
    select
        *,
        row_number() over (partition by ticker_symbol order by trade_date) -
        row_number() over (partition by ticker_symbol, direction order by trade_date) as grp
    from d
)
select
    ticker_symbol,
    asset_class,
    direction,
    min(trade_date) as streak_start,
    max(trade_date) as streak_end,
    count(*) as streak_length
from g
where direction != 0
group by ticker_symbol, asset_class, direction, grp
