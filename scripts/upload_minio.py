from minio import Minio
from dotenv import load_dotenv
from datetime import datetime, timezone
from pathlib import Path

import sys
import os
import io
import socket

from ingest import one_time_load, daily_load
from bluesky_ingest import historical_load as bluesky_historical_load, daily_load as bluesky_daily_load
import configparser


project_root = Path(__file__).resolve().parent.parent

sys.path.append(str(project_root))
from utility.custom_logger import setup_logger

log_directory = project_root / "utility/logs"
logger = setup_logger(log_dir=log_directory)

config_path = project_root / "config.ini"
config = configparser.ConfigParser(allow_no_value=True)
config.read(config_path)
logger.info("red config")

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

load_dotenv()
MINIO_USER = os.environ.get("MINIO_USER")
MINIO_PASS = os.environ.get("MINIO_PWD")
bucket = config.get("minio", "bucket")


def get_working_host(host):
    try:
        with socket.create_connection((host.split(":")[0], 9000), timeout=1):
            return host
    except Exception:
        return "localhost:9000"


def ensure_bucket_exists(host):
    client = Minio(host, access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False)
    if not client.bucket_exists(bucket_name=bucket):
        logger.info(f"bucket {bucket} not exist.")
        client.make_bucket(bucket_name=bucket)
        logger.info(f"created {bucket}")
    else:
        logger.info(f"bucket already exist: {bucket}")


def upload_dataframe_to_minio(df, object_name, host):
    if df is None:
        logger.warning("got empty df")
        return

    client = Minio(host, access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False)
    buffer = io.BytesIO()
    df.write_parquet(buffer)
    buffer.seek(0)

    client.put_object(
        bucket_name=bucket,
        object_name=object_name,
        data=buffer,
        length=buffer.getbuffer().nbytes,
    )
    logger.info(f"data put {object_name} to bucket {bucket}")


def daily():
    logger.info("started daily")
    object_name = config.get("data", "daily") + ".parquet"
    host = get_working_host("localhost:9000")
    ensure_bucket_exists(host)
    upload_dataframe_to_minio(daily_load(), object_name=object_name, host=host)
    logger.info("finish started")


def one_time():
    logger.info("started once")
    object_name = config.get("data", option="historical") + ".parquet"
    host = get_working_host("minio:9000")
    ensure_bucket_exists(host)
    upload_dataframe_to_minio(one_time_load(), object_name=object_name, host=host)
    logger.info("finish one_time")


# --- NEW: bluesky uploads, same pattern as daily()/one_time() above ---
# config.ini needs:
# [data]
# bluesky_daily = bluesky_posts_daily
# bluesky_historical = bluesky_posts_historical


def bluesky_daily():
    logger.info("started bluesky daily")
    object_name = f"bluesky/{config.get('data', 'bluesky_daily')}_{now}.parquet"
    host = get_working_host("localhost:9000")
    ensure_bucket_exists(host)
    upload_dataframe_to_minio(bluesky_daily_load(), object_name=object_name, host=host)
    logger.info("finish bluesky daily")


def bluesky_one_time():
    logger.info("started bluesky one_time")
    object_name = f"bluesky/{config.get('data', 'bluesky_historical')}_{now}.parquet"
    host = get_working_host("minio:9000")
    ensure_bucket_exists(host)
    upload_dataframe_to_minio(bluesky_historical_load(), object_name=object_name, host=host)
    logger.info("finish bluesky one_time")


if __name__ == "__main__":
    try:
        one_time()
        logger.info("minio upload script successfull")
    except Exception as e:
        logger.exception(f"minio upload script failed due to error: {e}")

    # NEW: run bluesky historical pull in the same script execution.
    # Kept as a separate try/except so a bluesky failure (e.g. API/auth
    # issue) doesn't hide whether the yfinance upload above succeeded.
    try:
        bluesky_one_time()
        logger.info("bluesky upload script successfull")
    except Exception as e:
        logger.exception(f"bluesky upload script failed due to error: {e}")