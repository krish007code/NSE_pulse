-- Test: close_price must lie within [low_price, high_price].
-- A close outside the day's range is impossible under normal market conditions
-- and strongly indicates a data pipeline issue (e.g. wrong date alignment,
-- incorrect column mapping in the Parquet loader).
--
-- Exemption: commodity futures tickers (ticker_symbol LIKE '%=F') are excluded.
-- Audit (2026-09-21) found 317 violations across exactly two futures contracts:
--   CC=F (Cocoa)  — 134 rows
--   KC=F (Coffee) — 183 rows
-- Both are caused by Yahoo Finance reporting the exchange settlement price as
-- `Close`, which is set post-session and can legitimately fall outside the
-- intraday [Low, High] range. This is a known data characteristic of commodity
-- futures settlement pricing, not a pipeline defect.
-- Using NOT LIKE '%=F' rather than a specific CC=F / KC=F list so the exemption
-- covers any future contract added to the dataset that exhibits the same pattern.
select
    ticker_symbol,
    trade_date,
    close_price,
    low_price,
    high_price
from {{ ref('stg_raw_nse__daily_prices') }}
where (close_price < low_price or close_price > high_price)
  and ticker_symbol not like '%=F'
