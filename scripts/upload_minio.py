from minio import Minio
import os
from dotenv import load_dotenv
from datetime import datetime, timezone
now = datetime.now(timezone.utc).strftime('%Y-%m-%d')

load_dotenv()
MINIO_USER   = os.environ.get("USER1")
MINIO_PASS   = os.environ.get("PWD1")


def daily():
    client = Minio("minio:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False)
    if client.bucket_exists("bronze"):
        client.fput_object("bronze", f"portfolio_data{now}.parquet", f'/tmp/portfolio_data{now}.parquet')
    else:
        print('error bucket doesnt exist')

def one_time():
    client = Minio("localhost:9000", access_key=MINIO_USER, secret_key=MINIO_PASS, secure=False)
    if client.bucket_exists("bronze"):
        print("brinze exists")
    else:
        print("my-bucket does not exist")
        client.make_bucket("bronze")
    client.fput_object("bronze", "portfolio_data.parquet", "portfolio_data.parquet")

if __name__ == "__main__":
    one_time()