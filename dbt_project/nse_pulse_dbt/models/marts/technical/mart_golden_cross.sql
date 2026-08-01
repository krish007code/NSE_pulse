with m as (
    select
        *,
        lag(avg_close_7d) over (partition by ticker_symbol order by trade_date) as prev_avg_7,
        lag(avg_close_30d) over (partition by ticker_symbol order by trade_date) as prev_avg_30
    from {{ ref('int_moving_avgs') }}
)
select
    ticker_symbol,
    asset_class,
    trade_date
from m
where prev_avg_7 <= prev_avg_30
and avg_close_7d > avg_close_30d
