with m as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        avg_close_7d,
        avg_close_30d,
        if(neighbor(ticker_symbol, -1) = ticker_symbol, neighbor(avg_close_7d, -1), null) as prev_avg_7,
        if(neighbor(ticker_symbol, -1) = ticker_symbol, neighbor(avg_close_30d, -1), null) as prev_avg_30
    from {{ ref('int_moving_avgs') }}
    order by ticker_symbol, trade_date
)
select
    ticker_symbol,
    asset_class,
    trade_date
from m
where prev_avg_7 is not null
  and prev_avg_30 is not null
  and prev_avg_7 >= prev_avg_30
  and avg_close_7d < avg_close_30d