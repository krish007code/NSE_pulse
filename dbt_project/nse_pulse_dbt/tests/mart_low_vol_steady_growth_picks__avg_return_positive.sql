-- Test: every row must have avg_return > 0.
-- The model uses HAVING avg(daily_return) > 0, so only tickers with positive
-- average returns survive. A non-positive avg_return here means the HAVING
-- was removed or the sign of daily_return was inadvertently flipped upstream.
select
    ticker_symbol,
    avg_return,
    volatility
from {{ ref('mart_low_vol_steady_growth_picks') }}
where avg_return <= 0
