with latest_volumes as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        avg_volume_10d,
        avg_volume_60d,
        avg_volume_10d / nullIf(avg_volume_60d, 0) as volume_ratio
    from {{ ref('int_moving_avgs') }}
    order by trade_date desc
    limit 1 by ticker_symbol
)
select *
from latest_volumes
order by volume_ratio desc