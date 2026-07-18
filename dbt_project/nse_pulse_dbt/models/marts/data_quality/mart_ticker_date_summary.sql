select
    ticker_symbol,
    asset_class,
    first_date,
    last_date,
    days_tracked
from {{ ref('int_ticker_summary') }}
