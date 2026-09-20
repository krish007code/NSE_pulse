with r as (
    select * from {{ ref('int_returns') }}
),
daily as (
    select
        asset_class,
        trade_date,
        avg(daily_return) as avg_return
    from r
    group by asset_class, trade_date
)
select
    asset_class,
    trade_date,
    -- On the first trading day of each asset class, all tickers lack a prior close,
    -- so daily_return = NULL → avg_return = NULL → ln(NULL) = NULL → exp(NULL) = NULL.
    -- COALESCE sets these day-1 rows to 1.0 (the base value of the index, meaning
    -- "started at par"). Every subsequent day compounds from there correctly.
    coalesce(
        exp(sum(ln(1 + avg_return)) over (partition by asset_class order by trade_date rows between unbounded preceding and current row)),
        1.0
    ) as index_value
from daily
