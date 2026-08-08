select
    r.ticker_symbol,
    r.asset_class,
    r.trade_date,
    r.range_pct,
    m.avg_range_pct_30d
from {{ ref('int_returns') }} r
join {{ ref('int_moving_avgs') }} m
    on m.ticker_symbol = r.ticker_symbol
    and m.trade_date = r.trade_date
where r.range_pct > 2 * m.avg_range_pct_30d
