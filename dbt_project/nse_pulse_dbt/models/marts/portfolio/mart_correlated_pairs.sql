select
    ticker_a,
    ticker_b,
    correlation
from {{ ref('int_pairs_corr') }}
order by correlation desc
limit 10
