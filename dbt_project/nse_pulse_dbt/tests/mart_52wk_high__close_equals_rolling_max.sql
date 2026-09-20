-- Test: in mart_52wk_high, close_price must equal the 252-row rolling maximum.
-- The model filters WHERE close_price = rolling_52wk_high.
-- We recompute rolling_52wk_high here and verify the condition holds for every
-- row that made it through — catching cases where the filter was loosened
-- or the rolling window size was changed without updating the WHERE clause.
with recomputed as (
    select
        ticker_symbol,
        trade_date,
        close_price,
        max(close_price) over (
            partition by ticker_symbol
            order by trade_date
            rows between 251 preceding and current row
        ) as expected_52wk_high
    from {{ ref('stg_raw_nse__daily_prices') }}
)
select
    m.ticker_symbol,
    m.trade_date,
    m.close_price,
    r.expected_52wk_high
from {{ ref('mart_52wk_high') }} m
join recomputed r
    on r.ticker_symbol = m.ticker_symbol
    and r.trade_date = m.trade_date
where m.close_price != r.expected_52wk_high
