with m as (
    select
        asset_class,
        ticker_symbol,
        date_trunc('month', trade_date) as trade_month,
        avg(daily_return) as monthly_return
    from {{ ref('int_returns') }}
    group by asset_class, ticker_symbol, date_trunc('month', trade_date)
)
select
    ticker_symbol,
    asset_class,
    sum(case when monthly_return > 0 then 1 else 0 end) as positive_months,
    count(*) as total_months,
    stddev(monthly_return) as monthly_return_stddev
from m
group by ticker_symbol, asset_class
order by positive_months desc, monthly_return_stddev asc
