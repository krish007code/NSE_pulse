with
    p as (select * from {{ ref("stg_raw_nse__daily_prices") }}),
    max_date_cte as (select max(trade_date) as max_date from p),
    dates as (
        select distinct trade_date
        from p
        where trade_date >= (select max_date from max_date_cte) - interval 30 day
    ),
    tickers as (select distinct ticker_symbol from p),
    expected as (
        select t.ticker_symbol, d.trade_date from tickers t cross join dates d
    ),
    actual as (
        select ticker_symbol, trade_date
        from p
        where trade_date >= (select max_date from max_date_cte) - interval 30 day
    )
select e.ticker_symbol, e.trade_date as missing_date
from expected e
left join actual a on a.ticker_symbol = e.ticker_symbol and a.trade_date = e.trade_date
where a.ticker_symbol is null
