with s as (
    select * from {{ ref('int_ticker_summary') }}
),
holdings as (
    select
        s.ticker_symbol,
        1.0 / (select count(*) from s) as weight,
        s.last_close / p.close_price as growth_multiple
    from s
    join {{ ref('stg_raw_nse__daily_prices') }} p
        on p.ticker_symbol = s.ticker_symbol
        and p.trade_date = s.first_date
)
select
    sum(weight * growth_multiple) as portfolio_value_per_unit_invested
from holdings
