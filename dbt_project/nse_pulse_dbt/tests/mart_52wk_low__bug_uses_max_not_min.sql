-- ⚠️  BUG DETECTION TEST — mart_52wk_low uses MAX() instead of MIN().
--
-- mart_52wk_low.sql contains:
--     max(close_price) over (...) as rolling_52wk_low   <-- MAX, not MIN
--     WHERE close_price = rolling_52wk_low              <-- so this finds 52-WEEK HIGHS
--
-- As a result, mart_52wk_low currently produces the same rows as mart_52wk_high.
-- This test verifies that claim: every row in mart_52wk_low should also appear
-- in mart_52wk_high. If this test passes it CONFIRMS the bug is present.
-- Fix: change MAX to MIN in the mart_52wk_low window function.
--
-- This test returning 0 rows means: either the bug is confirmed (all low rows
-- are also high rows), OR the data has no dates where the 52wk-high and
-- 52wk-low (incorrectly computed) differ — which is equally suspicious.
--
-- We flag rows that are in mart_52wk_low but NOT in mart_52wk_high, which
-- should be zero if both models are computing the same (wrong) thing.
select
    l.ticker_symbol,
    l.trade_date,
    l.close_price
from {{ ref('mart_52wk_low') }} l
left join {{ ref('mart_52wk_high') }} h
    on h.ticker_symbol = l.ticker_symbol
    and h.trade_date = l.trade_date
where h.ticker_symbol is null
