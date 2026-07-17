from minio import Minio
import os
from dotenv import load_dotenv
from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))
config_path = project_root / "config.ini"

from utility.custom_logger import logger
import configparser

config = configparser.ConfigParser()
config.read(config_path)
logger.info("ref config")

load_dotenv()
MINIO_USER = os.environ.get("USER1")
MINIO_PASS = os.environ.get("PWD1")
bucket = config.get("minio", "bucket")


def daily():
    logger.info("started daily")

    path = config.get("data_paths", "daily_path")
    object_name = Path(path).name
    client = Minio(
        "minio:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )
    if client.bucket_exists(bucket_name=bucket):
        client.fput_object(bucket_name=bucket, object_name=object_name, file_path=path)
        logger.info(f"uploaded inside {bucket}")
        path = Path(path)
        if path.exists():
            logger.info(f"freed data {bucket}")
            path.unlink()
    else:
        logger.info("error bucket not exist")


def one_time():
    logger.info("started once")
    path = config.get("data_paths", "historical_path")
    object_name = Path(path).name

    client = Minio(
        "localhost:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )
    if client.bucket_exists(bucket_name=bucket):
        logger.info(f"bucket already exists {bucket}")
    else:
        logger.info("bucket does not exist")
        client.make_bucket(bucket_name=bucket)
    client.fput_object(bucket_name=bucket, object_name=object_name, file_path=path)

    path = Path(path)
    if path.exists():
        logger.info(f"freed {bucket}")
        path.unlink()


if __name__ == "__main__":
    try:
        one_time()
        logger.info("minio upload script successfull.")
    except Exception as e:
        logger.exception(f"minio upload script failed due to error: {e}")
