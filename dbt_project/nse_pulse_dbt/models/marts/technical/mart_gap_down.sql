select
    ticker_symbol,
    asset_class,
    trade_date,
    gap_pct
from {{ ref('int_returns') }}
where gap_pct < -0.02
order by gap_pct asc
