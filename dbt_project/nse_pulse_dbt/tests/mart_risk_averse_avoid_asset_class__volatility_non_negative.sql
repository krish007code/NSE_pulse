-- Test: volatility_90d and max_drawdown_90d must satisfy their mathematical constraints.
-- volatility_90d = stddevPop(daily_return) — must be >= 0.
-- max_drawdown_90d = min(drawdown_pct) over last 90 days — must be <= 0.
select
    asset_class,
    volatility_90d,
    max_drawdown_90d
from {{ ref('mart_risk_averse_avoid_asset_class') }}
where volatility_90d < 0
   or max_drawdown_90d > 0
