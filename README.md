# NSE Pulse

> A multi-asset market intelligence pipeline — NIFTY 50 equities, gold/silver, and crypto —
> extended with a Bluesky-sourced sentiment layer, backed by a 62-model dbt project with
> 294 passing data tests that caught real bugs before they shipped.

[![Python](https://img.shields.io/badge/Python-3.x-blue)]()
[![Airflow](https://img.shields.io/badge/Airflow-2.9.2-red)]()
[![dbt](https://img.shields.io/badge/dbt-62%20models-orange)]()
[![Tests](https://img.shields.io/badge/dbt%20tests-294%2F294%20passing-brightgreen)]()
[![ClickHouse](https://img.shields.io/badge/ClickHouse-warehouse-yellow)]()


---

## What this does

- Ingests daily price data via **yfinance** across multiple asset classes — NIFTY 50 equities, gold/silver, and crypto.
- Pulls posts from **Bluesky** (chosen after X/Twitter and Reddit API access proved gated) mentioning tracked tickers.
- Scores each post with **VADER** sentiment analysis and lands it in a bronze layer on **MinIO**.
- Loads bronze data into **ClickHouse**, then builds a **62-model dbt project** — staging → intermediate → marts — covering technicals, volatility, returns, portfolio/relative-value analytics, and data-quality checks, plus a daily sentiment index per ticker.
- All orchestrated with a single daily **Apache Airflow** DAG, served via a **FastAPI** backend.

---

## Why this stack

Each piece was picked for a reason, not just to pad a resume:

- **Airflow** — orchestrates ingestion, sentiment scoring, and loading as a single daily DAG with retry/failure handling, which cron scripts don't give you for free.
- **yfinance** — free, reliable OHLC source across equities, commodities, and crypto, no paid API key needed to get the project running.
- **Bluesky** — the only major microblogging platform with an open, unrestricted API left after X and Reddit gated theirs; the sentiment layer needed *some* live social feed.
- **VADER** — a lightweight, rule-based sentiment scorer built specifically for short, informal social text. No GPU, no training data, no model drift to manage — appropriate for a data-engineering pipeline where sentiment scoring is one stage, not the focus of the project.
- **MinIO** — S3-compatible object storage for the bronze (raw) layer, so ingestion is decoupled from the warehouse and replayable if downstream models change.
- **ClickHouse** — columnar OLAP store built for fast time-series aggregation; also used here via `ReplacingMergeTree` for engine-level deduplication (see the dbt section below for a real bug this surfaced).
- **dbt** — turns raw bronze data into 62 tested, documented staging/intermediate/mart models instead of ad-hoc SQL scripts.
- **uv** — fast, reproducible Python dependency management for the ingestion/scoring scripts.
- **FastAPI** — serves the resulting sentiment index / query layer.

---

## Architecture

```
yfinance (multi-asset OHLC) ─────┐
                                  ▼
Bluesky posts ──► VADER scoring ──► MinIO (bronze)
                                  │
                                  ▼
                    ClickHouse (ReplacingMergeTree)
                                  │
                                  ▼
        dbt: staging → intermediate → marts (62 models, 294 tests)
                                  │
                                  ▼
                         FastAPI backend
```

Ingestion, sentiment scoring, and loading are orchestrated as a single daily **Airflow DAG** (`nse_pipeline`) defined in `dags/nse_pipeline.py`.

---

## dbt Model Layer

62 models across staging, intermediate, and mart layers, covered by **294 data tests — all passing**.

| Layer | Models | Materialization | Covers |
|---|---|---|---|
| Staging | 2 | view | Raw price + sentiment source normalization |
| Intermediate | 10 | ephemeral / view | Returns, drawdown, streaks, correlations, moving averages, ticker/market summaries |
| Marts — technical | 10 | table | Crossovers, breakouts, 52wk highs/lows, volume anomalies |
| Marts — volatility | 10 | table | Drawdowns, rolling volatility, risk-by-asset-class |
| Marts — returns | 10 | table | Cumulative/YTD/monthly returns, streaks, best/worst days |
| Marts — portfolio | 10 | table | Correlated/inverse pairs, asset-class indices, relative performance |
| Marts — advanced | 5 | table | Lead/lag, divergence, contrarian and low-vol screens |
| Marts — data quality | 5 | table | Missing days, zero-volume days, coverage checks |

### Mart models reference

**`mart_daily_sentiment`** *(root)* — Aggregates Bluesky posts per ticker per day into avg sentiment score, sentiment volatility, positive/negative counts, post volume, and total engagement.

---

**`technical/`** — price-action signals and breakout detection

| Model | Purpose |
|---|---|
| `mart_moving_averages` | Daily 7-day and 30-day closing-price moving averages per ticker; the base series for all crossover and trend models. |
| `mart_golden_cross` | Dates where a ticker's 7-day MA crossed above its 30-day MA — a bullish momentum signal. |
| `mart_death_cross` | Dates where a ticker's 7-day MA crossed below its 30-day MA — a bearish momentum signal. |
| `mart_above_30d_avg` | Most recent day per ticker where close was above its 30-day MA — a simple trend filter. |
| `mart_52wk_high` | Tickers whose close matched their rolling 52-week high within the last 30 days. |
| `mart_52wk_low` | Tickers whose close matched their rolling 52-week low within the last 30 days. *(See bug note in test section.)* |
| `mart_gap_up` | All days a ticker opened more than 2% above the prior close. |
| `mart_gap_down` | All days a ticker opened more than 2% below the prior close. |
| `mart_volume_unusual` | Latest 10-day vs 60-day volume ratio per ticker — flags tickers with unusually elevated recent activity. |
| `mart_market_wide_volume_spike` | Top 10 trading days by total market-wide volume across all tickers. |

---

**`volatility/`** — risk measurement, drawdowns, and intraday range analysis

| Model | Purpose |
|---|---|
| `mart_rolling_volatility_30d` | 30-day rolling return standard deviation per ticker per day. |
| `mart_max_drawdown` | Worst peak-to-trough drawdown percentage per ticker over full history. |
| `mart_drawdown_recovery` | Per-ticker trough date, drawdown depth, recovery date, and days to recover to prior peak. |
| `mart_choppiness` | Same drawdown-recovery logic as above using a simpler JOIN approach; retained as an alternative formulation. |
| `mart_volatility_spike` | Days where a ticker's intraday range exceeded 2× its 30-day average range. |
| `mart_largest_intraday_swing` | Single row — the globally largest intraday high-low range event across all tickers and dates. |
| `mart_most_volatile` | Top 10 tickers by return standard deviation. |
| `mart_near_all_time_high_low` | Per-ticker percentage distance from all-time high and all-time low based on latest close. |
| `mart_return_to_risk_ratio` | Sharpe-like ratio (avg daily return ÷ stddev) per ticker over full history. |
| `mart_risk_by_asset_class` | Average return volatility per asset class — ranks asset classes from riskiest to calmest. |

---

**`returns/`** — performance measurement across time horizons

| Model | Purpose |
|---|---|
| `mart_cumulative_return` | All-time cumulative return per ticker: (last close − first close) / first close. |
| `mart_ytd_return` | Year-to-date return and rank per ticker from the first trading day of the current year. |
| `mart_avg_return_by_asset_class` | Average daily return and standard deviation per asset class over full history. |
| `mart_monthly_return_by_asset_class` | Average daily return per asset class per calendar month. |
| `mart_top_gainers_30d` | Top 10 tickers by 30-day price return. |
| `mart_top_losers_7d` | Bottom 10 tickers by 7-day price return. |
| `mart_best_day` | Single row — the globally best single-day return across all tickers and all time. |
| `mart_worst_day` | Single row — the globally worst single-day return across all tickers and all time. |
| `mart_up_streaks` | Consecutive winning streaks of 5+ days per ticker. |
| `mart_down_streaks` | Consecutive losing streaks of 5+ days per ticker. |

---

**`portfolio/`** — cross-asset, relative-value, and portfolio-level analytics

| Model | Purpose |
|---|---|
| `mart_asset_class_index` | Compounded return index (base ≈ 1.0) per asset class per day — a synthetic "index fund" for each class. |
| `mart_asset_class_perf_6m` | Average 6-month price return per asset class. |
| `mart_market_breadth` | Daily advance/decline ratio — fraction of tickers that rose vs fell each day. |
| `mart_consistent_growth` | Per-ticker count of positive months and monthly return stddev — identifies steady growers. |
| `mart_correlated_pairs` | Top 10 most positively correlated ticker pairs by Pearson correlation of daily returns. |
| `mart_inverse_pairs` | Top 10 most negatively correlated ticker pairs — natural hedging candidates. |
| `mart_ticker_beats_asset_class` | YTD tickers whose average daily return exceeds their own asset-class average. |
| `mart_risk_adjusted_return_quarter` | Sharpe-like risk-adjusted return per asset class over the last 90 days. |
| `mart_equal_weight_portfolio` | Single aggregate: value of $1 split equally across all tickers at their first available date. |
| `mart_crypto_selloff_reaction` | On crypto crash days (avg return < −5%), shows how every other asset class responded. |

---

**`advanced/`** — screening, predictive signals, and contrarian views

| Model | Purpose |
|---|---|
| `mart_low_vol_steady_growth_picks` | Top 5 tickers with positive avg return ordered by lowest volatility — the "steady compounder" screener. |
| `mart_price_volume_divergence` | Days where price rose but volume fell below the prior day — a classic weak-rally / bearish divergence flag. |
| `mart_lead_lag` | All-pairs correlation between ticker A's return today and ticker B's return tomorrow — surfaces predictive relationships. |
| `mart_worst_day_recovery` | Per-ticker worst single-day drop and how many days it took to recover to the prior close. |
| `mart_risk_averse_avoid_asset_class` | Asset classes ranked by 90-day volatility and 90-day max drawdown — tells risk-averse allocators what to avoid. |

---

**`data_quality/`** — pipeline health and coverage monitoring

| Model | Purpose |
|---|---|
| `mart_latest_close` | Most recent closing price and date per ticker — source of truth for last-known price. |
| `mart_ticker_date_summary` | Per-ticker audit of first date, last date, and total days tracked — data completeness at a glance. |
| `mart_tickers_per_asset_class` | Count of distinct tickers per asset class — catches unexpected drops in the tracked instrument universe. |
| `mart_missing_days` | (ticker, date) combinations absent from price data in the last 30 days but expected — zero rows is healthy. |
| `mart_zero_volume_days` | Ticker-days with zero volume when other tickers did trade — flags suspected trading halts or ingestion gaps. |

---

### The test suite caught real bugs

Writing the test suite wasn't a formality — it surfaced production bugs that had been shipping silently:

- **`mart_52wk_low`** was using `MAX(close_price)` in its rolling window instead of `MIN`, so it was silently producing 52-week-*high* events under a 52-week-*low* name.
- **`mart_daily_sentiment`** was grouping by the raw source column `ticker` instead of the renamed CTE column `ticker_symbol` — a silent column resolution that would have broken without warning on any upstream schema change.
- **`mart_drawdown_recovery`** and **`mart_worst_day_recovery`** were returning `1970-01-01` instead of NULL for tickers that had never recovered, because ClickHouse's `minIf()` emits its type default rather than NULL when no row matches.
- **106,067 duplicate rows** in the `ohlcv` source table (and 305 duplicate Bluesky posts) were traced to ClickHouse's `ReplacingMergeTree` engine not yet having compacted its background parts — the tables were already designed correctly with the right `ORDER BY` keys, but dbt was reading unmerged parts between Airflow runs. Fixed with `OPTIMIZE TABLE ... FINAL` plus `FINAL` on both staging source reads, so future loads stay correct regardless of merge timing.

Full test breakdown (162 generic schema tests, 75+ singular SQL tests) is in `models/**/*.yml` and `tests/`.

---

## Tech Stack

| Layer           | Tool                          |
| --------------- | ----------------------------- |
| Orchestration   | Apache Airflow 2.9.2          |
| Price ingestion | yfinance                      |
| Social ingestion| Bluesky API                   |
| Sentiment       | VADER                         |
| Package mgmt    | uv                            |
| Storage         | MinIO (bronze), ClickHouse    |
| Modeling        | dbt Core (62 models, 294 tests)|
| API             | FastAPI                       |
| Infra           | Docker / Docker Compose       |

---

## Project Structure

```
├── Assets/          # Excalidraw architecture and design diagrams
├── backend/         # FastAPI service
├── dags/            # Airflow DAGs
├── dbt_project/     # dbt staging + intermediate + mart models (62 models, 294 tests)
├── scripts/         # Ingestion / sentiment scoring scripts (run via uv)
├── utility/         # Shared helpers
├── docker-compose.yaml
├── dockerfile.airflow
├── dockerfile.dbt
├── dockerfile.fastapi
└── .env.example     # Copy to .env and fill in your own credentials
```

---

## Setup

### 1. Clone and configure environment

```bash
git clone https://github.com/krish007code/NSE_pulse.git
cd NSE_pulse
cp .env.example .env   # fill in your own credentials — never commit .env
```

### 2. Generate an Airflow Fernet key

Airflow needs this to encrypt connection secrets in its metadata DB. Generate one and paste it into `.env` as `AIRFLOW__CORE__FERNET_KEY`:

```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 3. Bring up the stack

```bash
docker compose up -d
```

This starts Airflow (webserver + scheduler), the dbt runner, ClickHouse, MinIO, and the FastAPI backend as defined in `docker-compose.yaml`.

| Service             | URL                              |
| ------------------- | -------------------------------- |
| Airflow webserver   | http://localhost:8080            |
| FastAPI docs        | http://localhost:8000/docs       |
| ClickHouse HTTP     | http://localhost:8123            |
| MinIO console       | http://localhost:9001            |
| Metabase            | http://localhost:3000            |

### 4. Install `uv`

The ingestion/scoring scripts can be run outside the Airflow containers via `uv` (useful for one-time historical loads):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 5. Run the ingestion scripts

> **For daily runs, skip this step** — the `nse_pipeline` DAG runs these automatically every day. Trigger it from the Airflow UI at http://localhost:8080 or wait for the `@daily` schedule.

For a **one-time historical load**, run manually:

```bash
uv run scripts/upload_minio.py    # pulls price + Bluesky data, scores sentiment, writes to MinIO bronze
uv run scripts/load_clickhouse.py # loads bronze data from MinIO into ClickHouse
```

### 6. Run dbt models and tests

dbt is not triggered by the Airflow DAG — run it manually inside the dbt container:

```bash
docker exec -it dbt bash
dbt run
dbt test
```

---

## What's intentionally excluded from version control

The following are gitignored and must never be committed — they're either secrets, local state, or regenerable artifacts:

- `.env` — real credentials (use `.env.example` as the template)
- `__pycache__/`, `*.pyc` — Python bytecode
- `.venv/` — local virtual environment
- Airflow's local `logs/` and `airflow.db` (if running outside Docker)
- Any local data dumps or exported CSVs from MinIO/ClickHouse
- `.DS_Store`, `.idea/`, `.vscode/` — OS/editor cruft
- dbt local state (`.local/`, `.cache/`, `.user.yml`), IDE/tool state (`.copilot/`, `.dotnet/`), and machine-specific files (`.bash_history`, `.ssh/known_hosts`, `.gitconfig`)

---

## Charts / Visualization

[FILL IN — Metabase is running (see Setup table) but its role isn't documented yet. If dashboards are built there against ClickHouse, describe them here — ticker/asset-class views, sentiment overlays, etc. If it's not yet wired up for that, note it as planned and keep the earlier suggested set: price vs. sentiment overlay, sentiment distribution, correlation heatmap.]

---

## Status

Actively being extended — sentiment pipeline (Bluesky → MinIO → ClickHouse) is live and loading data;
staging and mart dbt models for the daily sentiment index are the current focus, as part of ongoing
work supervised by Dr. Sandeep Kumar at BML Munjal University.

---

## Author

**Kavyansh (krish007code)**
Focus: Data Engineering · Analytical Engineering
Contact: kavyanshkumarbaghel@gmail.com