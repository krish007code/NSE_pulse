import sys
import configparser
import os

import clickhouse_connect
from dotenv import load_dotenv
from datetime import datetime, timezone
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import setup_logger

log_directory = project_root / "utility/logs"
logger = setup_logger(log_dir=log_directory)


config = configparser.ConfigParser()
config_path = project_root / "config.ini"
config.read(config_path)
logger.info(f"load config from {config_path}")

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

load_dotenv()

MINIO_USER = os.environ.get("MINIO_USER")
MINIO_PWD = os.environ.get("MINIO_PWD")
CLICKHOUSE_USER = os.environ.get("CLICKHOUSE_USER")
CLICKHOUSE_PWD = os.environ.get("CLICKHOUSE_PWD")

database = config.get("clickhouse", "database")
table = config.get("clickhouse", "table")
bucket = config.get("minio", "bucket")

# NEW: config.ini needs, in [clickhouse]:
# bluesky_table = bluesky_sentiment
bluesky_table = config.get("clickhouse", "bluesky_table")


def once():
    logger.info("started once")
    file_name = config.get("data", "historical") + ".parquet"
    client = clickhouse_connect.get_client(
        host="localhost",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )
    client.command(f"CREATE DATABASE IF NOT EXISTS {database};")

    client.command(f"""
        CREATE TABLE IF NOT EXISTS {table} (
            Date Datetime64(3, 'UTC'),
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
        INSERT INTO {table}
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
    logger.info("ended once")


def everyday():
    logger.info("started daily")
    file_name = config.get("data", "daily") + ".parquet"
    client = clickhouse_connect.get_client(
        host="clickhouse",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )
    client.command(f"""
        INSERT INTO {table}
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
    logger.info("ended daily")


# --- NEW: bluesky sentiment load, mirrors once()/everyday() above ---


def bluesky_once():
    logger.info("started bluesky once")
    file_name = f"bluesky/{config.get('data', 'bluesky_scored_historical')}_{now}.parquet"
    client = clickhouse_connect.get_client(
        host="localhost",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )
    client.command(f"CREATE DATABASE IF NOT EXISTS {database};")

    client.command(f"""
        CREATE TABLE IF NOT EXISTS {database}.{bluesky_table} (
            uri String,
            ticker String,
            created_at Datetime64(3, 'UTC'),
            sentiment_compound Float32,
            sentiment_label String,
            is_finance_relevant Bool,
            engagement_score UInt32,
            source String
        ) ENGINE = ReplacingMergeTree()
        ORDER BY (ticker, created_at)
    """)

    client.command(f"""
        INSERT INTO {database}.{bluesky_table}
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
    logger.info("ended bluesky once")


def bluesky_everyday():
    logger.info("started bluesky daily")
    file_name = f"bluesky/{config.get('data', 'bluesky_scored_daily')}_{now}.parquet"
    client = clickhouse_connect.get_client(
        host="clickhouse",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )
    client.command(f"""
        INSERT INTO {database}.{bluesky_table}
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
    logger.info("ended bluesky daily")


if __name__ == "__main__":
    try:
        once()
        logger.info("load_clickhuose successfull.")
    except Exception as e:
        logger.exception(f"load clickhouse failed due to an error: {e}")

    try:
        bluesky_once()
        logger.info("bluesky load_clickhouse successfull.")
    except Exception as e:
        logger.exception(f"bluesky load clickhouse failed due to an error: {e}")