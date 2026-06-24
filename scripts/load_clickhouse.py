import clickhouse_connect
import os
from dotenv import load_dotenv
from datetime import datetime, timezone
now = datetime.now(timezone.utc).strftime('%Y-%m-%d')

load_dotenv()

MINIO_USER   = os.environ.get("USER1")
MINIO_PWD   = os.environ.get("PWD1")


def once():
    client = clickhouse_connect.get_client(
    host='localhost',
    port='8123',
    username='default',
    password="",
    autogenerate_session_id=False
    )
    client.command('CREATE DATABASE IF NOT EXISTS bronze;')

    client.command("""
        CREATE TABLE IF NOT EXISTS bronze.ohlcv (
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
        INSERT INTO bronze.ohlcv
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
            'http://minio:9000/bronze/portfolio_data.parquet',
            '{MINIO_USER}',
            '{MINIO_PWD}', 
            'Parquet'
        )                
    """)
def everyday():
    client = clickhouse_connect.get_client(
    host='clickhouse',
    port='8123',
    username='default',
    password="",
    autogenerate_session_id=False
    )
    client.command(f"""
        INSERT INTO bronze.ohlcv
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
            'http://minio:9000/bronze/portfolio_data{now}.parquet',
            '{MINIO_USER}',
            '{MINIO_PWD}', 
            'Parquet'
        )                
    """)

if __name__ == "__main__":
    once()