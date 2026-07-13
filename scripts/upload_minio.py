from minio import Minio
import os
from dotenv import load_dotenv
from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

from pathlib import Path

project_root = Path(__file__).resolve().parent.parent
config_path = project_root / "config.ini"

import configparser

config = configparser.ConfigParser()
config.read(config_path)

load_dotenv()
MINIO_USER = os.environ.get("USER1")
MINIO_PASS = os.environ.get("PWD1")
bucket = config.get("minio", "bucket")


def daily():
    path = config.get("data_paths", "daily_path")
    object_name = Path(path).name
    client = Minio(
        "minio:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )
    if client.bucket_exists(bucket_name=bucket):
        client.fput_object(bucket_name=bucket, object_name=object_name, file_path=path)

        path = Path(path)
        if path.exists():
            path.unlink()
    else:
        print("error bucket not exist")


def one_time():
    path = config.get("data_paths", "historical_path")
    object_name = Path(path).name

    client = Minio(
        "localhost:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False
    )
    if client.bucket_exists(bucket_name=bucket):
        print("bucket already exists")
    else:
        print("bucket does not exist")
        client.make_bucket(bucket_name=bucket)
    client.fput_object(bucket_name=bucket, object_name=object_name, file_path=path)

    path = Path(path)
    if path.exists():
        path.unlink()


if __name__ == "__main__":
    one_time()
