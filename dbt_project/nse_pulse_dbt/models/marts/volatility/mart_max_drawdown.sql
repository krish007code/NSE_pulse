select
    ticker_symbol,
    asset_class,
    min(drawdown_pct) as max_drawdown
from {{ ref('int_drawdown') }}
group by ticker_symbol, asset_class
order by max_drawdown asc
