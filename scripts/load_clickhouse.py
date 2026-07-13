import clickhouse_connect

from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")


from pathlib import Path

project_root = Path(__file__).resolve().parent.parent
config_path = project_root / "config.ini"

import configparser

config = configparser.ConfigParser()
config.read(config_path)

from dotenv import load_dotenv

load_dotenv()

import os

MINIO_USER = os.environ.get("USER1")
MINIO_PWD = os.environ.get("PWD1")
CLICKHOUSE_USER = os.environ.get("clickhouse_user")
CLICKHOUSE_PWD = os.environ.get("clikhouse_pwd")

database = config.get("clickhouse", "database")
table = config.get("clickhouse", "table")
bucket = config.get("minio", "bucket")


def once():
    path = config.get("data_paths", "historical_path")
    file_name = Path(path).name
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


def everyday():
    path = config.get("data_paths", "daily_path")
    file_name = Path(path).name
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


if __name__ == "__main__":
    once()
