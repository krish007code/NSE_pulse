select
    ticker_symbol,
    asset_class,
    last_close,
    all_time_high,
    all_time_low,
    (last_close - all_time_high) / all_time_high as pct_from_high,
    (last_close - all_time_low) / all_time_low as pct_from_low
from {{ ref('int_ticker_summary') }}
order by pct_from_high desc
