select
    asset_class,
    uniqExact(ticker_symbol) as tickers_in_class
from {{ ref('int_ticker_summary') }}
group by 1
