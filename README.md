# NSE Pulse

> A multi-asset market intelligence pipeline — NIFTY 50 equities, gold/silver, and crypto —
> extended with a Bluesky-sourced sentiment layer, backed by a 62-model dbt project with
> 294 passing data tests that caught real bugs before they shipped.

<!-- Optional badges — uncomment/edit once you confirm exact stack versions
[![Python](https://img.shields.io/badge/Python-3.x-blue)]()
[![Airflow](https://img.shields.io/badge/Airflow-2.9.2-red)]()
[![dbt](https://img.shields.io/badge/dbt-62%20models-orange)]()
[![Tests](https://img.shields.io/badge/dbt%20tests-294%2F294%20passing-brightgreen)]()
[![ClickHouse](https://img.shields.io/badge/ClickHouse-warehouse-yellow)]()
-->

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