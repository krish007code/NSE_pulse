-- Test: a golden cross and a death cross must never occur on the same ticker/date.
-- Golden cross = 7d MA crosses above 30d MA.
-- Death cross  = 7d MA crosses below 30d MA.
-- Both require opposite directional conditions (prev_7 <= prev_30 AND curr_7 > curr_30
-- vs prev_7 >= prev_30 AND curr_7 < curr_30). They are logically mutually exclusive
-- for the same ticker on the same day. A row here means the filter conditions in
-- one of the two models overlap, which would indicate a boundary condition bug
-- (e.g. both using <= / >= simultaneously on exact equality).
select
    g.ticker_symbol,
    g.trade_date
from {{ ref('mart_golden_cross') }} g
inner join {{ ref('mart_death_cross') }} d
    on d.ticker_symbol = g.ticker_symbol
    and d.trade_date = g.trade_date
