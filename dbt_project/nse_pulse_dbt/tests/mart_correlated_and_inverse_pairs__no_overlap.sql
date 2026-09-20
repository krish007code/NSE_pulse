-- Test: no ticker pair should appear in both mart_correlated_pairs and
-- mart_inverse_pairs. A pair can't simultaneously be the most positively
-- correlated AND the most negatively correlated. An overlap means both
-- models are selecting from the same ordered result set without correct
-- directional filtering — or the HAVING isFinite() let through NaN/Inf rows.
select
    c.ticker_a,
    c.ticker_b,
    c.correlation as correlated_value,
    i.correlation as inverse_value
from {{ ref('mart_correlated_pairs') }} c
inner join {{ ref('mart_inverse_pairs') }} i
    on i.ticker_a = c.ticker_a
    and i.ticker_b = c.ticker_b
