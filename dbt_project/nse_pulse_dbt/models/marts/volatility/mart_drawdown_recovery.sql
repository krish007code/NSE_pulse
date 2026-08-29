with d as (
    select * from {{ ref('int_drawdown') }}
),

-- Native ClickHouse replacement for QUALIFY row_number() = 1
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
        minIf(d.trade_date, d.trade_date > t.trough_date and d.close_price >= t.peak_price) as recovery_date
    from trough t
    inner join d on d.ticker_symbol = t.ticker_symbol
    group by t.ticker_symbol
)

select
    t.ticker_symbol,
    t.asset_class,
    t.trough_date,
    t.drawdown_pct,
    r.recovery_date,
    -- ClickHouse requires the unit as a quoted string first: dateDiff('unit', d1, d2)
    dateDiff('day', t.trough_date, r.recovery_date) as days_to_recover
from trough t
left join recovery r on r.ticker_symbol = t.ticker_symbol
order by t.drawdown_pct asc