select ticker_symbol, asset_class, last_close, last_date
from {{ ref("int_ticker_summary") }}
