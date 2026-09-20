-- Test: every row in mart_crypto_selloff_reaction must have crypto_return < -0.05.
-- The model's HAVING clause on the crypto CTE is avg(daily_return) < -0.05.
-- If a row with crypto_return >= -0.05 appears, the HAVING was changed or
-- the asset_class filter (WHERE asset_class = 'crypto') stopped matching.
select
    trade_date,
    crypto_return
from {{ ref('mart_crypto_selloff_reaction') }}
where crypto_return >= -0.05
