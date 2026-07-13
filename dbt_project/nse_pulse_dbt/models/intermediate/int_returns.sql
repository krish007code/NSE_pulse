with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
    -- for lag --
    order by ticker_symbol, trade_date
),
r as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        open_price,
        high_price,
        low_price,
        close_price,
        trade_volume,
        if(neighbor(ticker_symbol, -1) = ticker_symbol, neighbor(close_price, -1), null) as prev_close
    from p
)
select
    ticker_symbol,
    asset_class,
    trade_date,
    open_price,
    high_price,
    low_price,
    close_price,
    trade_volume,
    prev_close,
    case when prev_close is not null and prev_close != 0
        then (close_price - prev_close) / prev_close end as daily_return,
    case when open_price != 0
        then (high_price - low_price) / open_price end as range_pct,
    case when prev_close is not null and prev_close != 0
        then (open_price - prev_close) / prev_close end as gap_pct
from r
