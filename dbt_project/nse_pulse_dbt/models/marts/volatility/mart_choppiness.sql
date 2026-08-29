with d as (
    select * from {{ ref('int_drawdown') }}
),

trough as (
    select
        ticker_symbol,
        asset_class,
        trade_date as trough_date,
        close_price as trough_price,
        running_peak as peak_price,
        drawdown_pct
    from d
    order by drawdown_pct asc
    limit 1 by ticker_symbol
),

recovery as (
    select
        t.ticker_symbol,
        min(d.trade_date) as recovery_date
    from trough t
    inner join d on d.ticker_symbol = t.ticker_symbol
    -- Move non-equi conditions out of ON and into WHERE
    where d.trade_date > t.trough_date
      and d.close_price >= t.peak_price
    group by t.ticker_symbol
)

select
    t.ticker_symbol,
    t.asset_class,
    t.trough_date,
    t.drawdown_pct,
    r.recovery_date,
    dateDiff('day', t.trough_date, r.recovery_date) as days_to_recover
from trough t
left join recovery r on r.ticker_symbol = t.ticker_symbol
order by t.drawdown_pct asc