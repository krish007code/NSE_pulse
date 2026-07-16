import os
import sys
import configparser
from datetime import datetime, timezone
from pathlib import Path

import clickhouse_connect
from dotenv import load_dotenv

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import logger

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
config_path = project_root / "config.ini"

config = configparser.ConfigParser()
config.read(config_path)
logger.info(f"Loaded configuration from {config_path}")

load_dotenv()
logger.info("Loaded environment variables from .env")

MINIO_USER = os.environ.get("USER1")
MINIO_PWD = os.environ.get("PWD1")
CLICKHOUSE_USER = os.environ.get("CLICKHOUSE_USER")
CLICKHOUSE_PWD = os.environ.get("CLICKHOUSE_PWD")

database = config.get("clickhouse", "database")
table = config.get("clickhouse", "table")
bucket = config.get("minio", "bucket")


def once():
    logger.info("Starting 'once' (historical) data load into ClickHouse...")

    path = config.get("data_paths", "historical_path")
    file_name = Path(path).name

    logger.info("Connecting to ClickHouse...")
    client = clickhouse_connect.get_client(
        host="localhost",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )

    logger.info(f"Ensuring database '{database}' exists...")
    client.command(f"CREATE DATABASE IF NOT EXISTS {database};")

    logger.info(f"Ensuring table '{table}' exists in database '{database}'...")
    client.command(f"""
        CREATE TABLE IF NOT EXISTS {database}.{table} (
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

    logger.info(
        f"Pulling data from MinIO bucket '{bucket}', file '{file_name}' into ClickHouse..."
    )
    client.command(f"""
        INSERT INTO {database}.{table}
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
    logger.info("Historical data successfully loaded into ClickHouse.")


def everyday():
    logger.info("Starting 'everyday' (daily) data load into ClickHouse...")

    path = config.get("data_paths", "daily_path")
    file_name = Path(path).name

    logger.info("Connecting to ClickHouse")
    client = clickhouse_connect.get_client(
        host="clickhouse",
        port=8123,
        username=CLICKHOUSE_USER,
        password=CLICKHOUSE_PWD,
        autogenerate_session_id=False,
    )

    logger.info(
        f"Pulling daily data from MinIO bucket '{bucket}', file '{file_name}' into ClickHouse..."
    )
    client.command(f"""
        INSERT INTO {database}.{table}
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
    logger.info("Daily data successfully loaded into ClickHouse.")


if __name__ == "__main__":
    try:
        once()
        logger.info("ClickHouse ingestion script completed successfully.")
    except Exception as e:
        logger.exception(f"ClickHouse ingestion script failed due to an error: {e}")
