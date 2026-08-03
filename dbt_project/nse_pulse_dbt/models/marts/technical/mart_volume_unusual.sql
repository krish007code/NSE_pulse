select
    ticker_symbol,
    asset_class,
    trade_date,
    avg_volume_10d,
    avg_volume_60d,
    case when avg_volume_60d != 0
        then avg_volume_10d / avg_volume_60d end as volume_ratio
from {{ ref('int_moving_avgs') }}
qualify row_number() over (partition by ticker_symbol order by trade_date desc) = 1
order by volume_ratio desc
