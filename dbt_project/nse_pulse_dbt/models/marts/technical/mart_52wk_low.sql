with p as (
    select * from {{ ref('stg_raw_nse__daily_prices') }}
),
rolling as (
    select
        ticker_symbol,
        asset_class,
        trade_date,
        close_price,
        min(close_price) over (partition by ticker_symbol order by trade_date rows between 251 preceding and current row) as rolling_52wk_low
    from p
)
select
    ticker_symbol,
    asset_class,
    trade_date,
    close_price
from rolling
where close_price = rolling_52wk_low
and trade_date >= dateadd(day, -30, current_date)
