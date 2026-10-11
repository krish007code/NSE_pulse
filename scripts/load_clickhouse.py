
import sys
import configparser
import os
from datetime import datetime, timezone
from pathlib import Path

import clickhouse_connect
from dotenv import load_dotenv

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import setup_logger

logger = setup_logger(log_dir=project_root / "utility/logs")

config_path = project_root / "config.ini"
config = configparser.ConfigParser()
config.read(config_path)
logger.info(f"Loaded config from {config_path}")

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

load_dotenv()

MINIO_USER = os.environ.get("MINIO_USER")
MINIO_PWD = os.environ.get("MINIO_PWD")
CLICKHOUSE_USER = os.environ.get("CLICKHOUSE_USER")
CLICKHOUSE_PWD = os.environ.get("CLICKHOUSE_PWD")

database = config.get("clickhouse", "database")
table = config.get("clickhouse", "table")
bluesky_table = config.get("clickhouse", "bluesky_table")
bucket = config.get("minio", "bucket")

# Option A: table already includes its database name in config.ini.
stock_table = table
sentiment_table = f"{database}.{bluesky_table}"


def get_clickhouse_client(host: str):
    return clickhouse_connect.get_client(
        host=host,
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )


def once():
    """Load historical stock data."""
    logger.info("Started historical stock load")

    file_name = config.get("data", "historical") + ".parquet"
    client = get_clickhouse_client("localhost")

    try:
        client.command(f"CREATE DATABASE IF NOT EXISTS {database}")

        client.command(f"""
            CREATE TABLE IF NOT EXISTS {stock_table} (
                Date DateTime64(3, 'UTC'),
                Open Float64,
                High Float64,
                Low Float64,
                Close Float64,
                Volume Int64,
                ticker String,
                asset_class String
            ) ENGINE = ReplacingMergeTree()
            ORDER BY (ticker, Date)
        """)

        client.command(f"""
            INSERT INTO {stock_table}
            SELECT
                Date,
                Open,
                High,
                Low,
                Close,
                Volume,
                ticker,
                asset_class
            FROM s3(
                'http://minio:9000/{bucket}/{file_name}',
                '{MINIO_USER}',
                '{MINIO_PWD}',
                'Parquet'
            )
        """)

        logger.info(
            f"Historical stock data loaded from {file_name} "
            f"into {stock_table}"
        )
    except Exception:
        logger.exception("Historical stock load failed")
        raise
    finally:
        client.close()


def everyday():
    """Load daily stock data. Intended for Airflow."""
    logger.info("Started daily stock load")

    file_name = config.get("data", "daily") + ".parquet"
    client = get_clickhouse_client("clickhouse")

    try:
        client.command(f"""
            INSERT INTO {stock_table}
            SELECT
                Date,
                Open,
                High,
                Low,
                Close,
                Volume,
                ticker,
                asset_class
            FROM s3(
                'http://minio:9000/{bucket}/{file_name}',
                '{MINIO_USER}',
                '{MINIO_PWD}',
                'Parquet'
            )
        """)

        logger.info(
            f"Daily stock data loaded from {file_name} "
            f"into {stock_table}"
        )
    except Exception:
        logger.exception("Daily stock load failed")
        raise
    finally:
        client.close()


def bluesky_once():
    """Load historical Bluesky sentiment data."""
    logger.info("Started historical Bluesky sentiment load")

    file_name = (
        f"bluesky/"
        f"{config.get('data', 'bluesky_scored_historical')}_{now}.parquet"
    )
    client = get_clickhouse_client("localhost")

    try:
        client.command(f"CREATE DATABASE IF NOT EXISTS {database}")

        client.command(f"""
            CREATE TABLE IF NOT EXISTS {sentiment_table} (
                uri String,
                ticker String,
                created_at DateTime64(3, 'UTC'),
                sentiment_compound Float32,
                sentiment_label String,
                is_finance_relevant Bool,
                engagement_score UInt32,
                source String
            ) ENGINE = ReplacingMergeTree()
            ORDER BY (ticker, created_at)
        """)

        client.command(f"""
            INSERT INTO {sentiment_table}
            SELECT
                uri,
                ticker,
                parseDateTime64BestEffort(created_at, 3) AS created_at,
                sentiment_compound,
                sentiment_label,
                is_finance_relevant,
                engagement_score,
                source
            FROM s3(
                'http://minio:9000/{bucket}/{file_name}',
                '{MINIO_USER}',
                '{MINIO_PWD}',
                'Parquet'
            )
        """)

        logger.info(
            f"Historical Bluesky data loaded from {file_name} "
            f"into {sentiment_table}"
        )
    except Exception:
        logger.exception("Historical Bluesky sentiment load failed")
        raise
    finally:
        client.close()


def bluesky_everyday():
    """Load daily Bluesky sentiment data. Intended for Airflow."""
    logger.info("Started daily Bluesky sentiment load")

    file_name = (
        f"bluesky/"
        f"{config.get('data', 'bluesky_scored_daily')}_{now}.parquet"
    )
    client = get_clickhouse_client("clickhouse")

    try:
        client.command(f"""
            INSERT INTO {sentiment_table}
            SELECT
                uri,
                ticker,
                parseDateTime64BestEffort(created_at, 3) AS created_at,
                sentiment_compound,
                sentiment_label,
                is_finance_relevant,
                engagement_score,
                source
            FROM s3(
                'http://minio:9000/{bucket}/{file_name}',
                '{MINIO_USER}',
                '{MINIO_PWD}',
                'Parquet'
            )
        """)

        logger.info(
            f"Daily Bluesky data loaded from {file_name} "
            f"into {sentiment_table}"
        )
    except Exception:
        logger.exception("Daily Bluesky sentiment load failed")
        raise
    finally:
        client.close()


if __name__ == "__main__":
    try:
        once()
        logger.info("Historical stock data loaded successfully")
    except Exception:
        logger.exception("Historical stock data load failed")
        raise

    try:
        bluesky_once()
        logger.info("Historical Bluesky sentiment data loaded successfully")
    except Exception:
        logger.exception("Historical Bluesky sentiment load failed")
        raise
