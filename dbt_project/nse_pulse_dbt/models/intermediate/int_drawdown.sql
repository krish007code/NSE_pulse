with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
peak as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        close_price,
        max(close_price) over (partition by ticker_symbol order by trade_date rows between unbounded preceding and current row) as running_peak
    from p
)
select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price,
    running_peak,
    case when running_peak != 0 then (close_price - running_peak) / running_peak end as drawdown_pct
from peak
