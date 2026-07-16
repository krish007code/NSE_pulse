import os
import sys
import configparser
from datetime import datetime, timezone
from pathlib import Path

from minio import Minio
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
MINIO_PASS = os.environ.get("PWD1")
bucket = config.get("minio", "bucket")


def daily():
    logger.info("Starting 'daily' upload to MinIO...")

    path_str = config.get("data_paths", "daily_path")
    file_path = Path(path_str)
    object_name = file_path.name

    logger.info("Connecting to MinIO")
    client = Minio(
        "minio:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )

    if client.bucket_exists(bucket_name=bucket):
        logger.info(f"Uploading {object_name} to bucket '{bucket}'...")
        client.fput_object(
            bucket_name=bucket, object_name=object_name, file_path=path_str
        )
        logger.info(f"Successfully uploaded {object_name} to MinIO.")

        if file_path.exists():
            file_path.unlink()
            logger.info(f"Deleted local file: {file_path}")
    else:
        logger.error(f"Upload failed: Bucket '{bucket}' does not exist.")


def one_time():
    logger.info("Starting 'one_time' (historical) upload to MinIO...")

    path_str = config.get("data_paths", "historical_path")
    file_path = Path(path_str)
    object_name = file_path.name

    logger.info("Connecting to MinIO (host: localhost:9000)...")
    client = Minio(
        "localhost:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )

    if client.bucket_exists(bucket_name=bucket):
        logger.info(f"Bucket '{bucket}' already exists.")
    else:
        logger.info(f"Bucket '{bucket}' does not exist. Creating it now...")
        client.make_bucket(bucket_name=bucket)
        logger.info(f"Successfully created bucket '{bucket}'.")

    logger.info(f"Uploading {object_name} to bucket '{bucket}'...")
    client.fput_object(bucket_name=bucket, object_name=object_name, file_path=path_str)
    logger.info(f"Successfully uploaded {object_name} to MinIO.")

    if file_path.exists():
        file_path.unlink()
        logger.info(f"Deleted local file: {file_path}")


if __name__ == "__main__":
    try:
        one_time()
        logger.info("MinIO upload script completed successfully.")
    except Exception as e:
        logger.exception(f"MinIO upload script failed due to an error: {e}")
