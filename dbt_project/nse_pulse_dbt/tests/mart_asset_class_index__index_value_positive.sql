-- Test: index_value must be strictly positive.
-- index_value = exp(cumulative sum of ln(1 + avg_return)).
-- exp() always returns a positive value. A zero or negative index_value would
-- mean ln(1 + avg_return) produced -Inf (i.e. avg_return = -1.0, meaning the
-- entire asset class had a -100% average return on a given day — impossible
-- in practice for a diversified group). Surface it so it can be investigated.
select
    asset_class,
    trade_date,
    index_value
from {{ ref('mart_asset_class_index') }}
where index_value <= 0
