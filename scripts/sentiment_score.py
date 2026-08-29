import sys
import io
import configparser
import os

from dotenv import load_dotenv
from datetime import datetime, timezone
from pathlib import Path

import polars as pl
from minio import Minio
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

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
bucket = config.get("minio", "bucket")

analyzer = SentimentIntensityAnalyzer()

# config.ini needs, alongside your existing [data] keys:
# bluesky_scored_historical = bluesky_posts_scored_historical
# bluesky_scored_daily = bluesky_posts_scored_daily


def label_from_compound(score: float) -> str:
    if score >= 0.05:
        return "positive"
    elif score <= -0.05:
        return "negative"
    return "neutral"


def get_minio_client(host: str) -> Minio:
    return Minio(host, access_key=MINIO_USER, secret_key=MINIO_PWD, secure=False)


def read_parquet_from_minio(client: Minio, object_name: str) -> pl.DataFrame:
    logger.info(f"reading {object_name} from bucket {bucket}")
    response = client.get_object(bucket, object_name)
    buffer = io.BytesIO(response.read())
    response.close()
    response.release_conn()
    return pl.read_parquet(buffer)


def write_parquet_to_minio(client: Minio, df: pl.DataFrame, object_name: str):
    buffer = io.BytesIO()
    df.write_parquet(buffer)
    buffer.seek(0)
    client.put_object(
        bucket_name=bucket,
        object_name=object_name,
        data=buffer,
        length=buffer.getbuffer().nbytes,
    )
    logger.info(f"wrote scored data to {object_name} in bucket {bucket}")


def score_sentiment(df: pl.DataFrame) -> pl.DataFrame:
    logger.info(f"scoring sentiment for {df.shape[0]} rows")

    compound_scores = [
        analyzer.polarity_scores(text)["compound"] if text else 0.0
        for text in df["text"].to_list()
    ]

    df = df.with_columns(pl.Series("sentiment_compound", compound_scores))
    df = df.with_columns(
        pl.col("sentiment_compound")
        .map_elements(label_from_compound, return_dtype=pl.Utf8)
        .alias("sentiment_label")
    )
    df = df.with_columns(
        (pl.col("like_count") + pl.col("repost_count") + pl.col("reply_count"))
        .alias("engagement_score")
    )

    # trim to silver schema -- full text/author stays recoverable in the
    # bronze parquet if ever needed, silver only carries what marts use
    silver = df.select([
        "uri", "ticker", "created_at", "sentiment_compound", "sentiment_label",
        "is_finance_relevant", "engagement_score", "source",
    ])
    logger.info(f"scored {silver.shape[0]} rows")
    return silver


def score_and_upload(source_object_name: str, dest_object_name: str, host: str):
    client = get_minio_client(host)
    raw_df = read_parquet_from_minio(client, source_object_name)
    scored_df = score_sentiment(raw_df)
    write_parquet_to_minio(client, scored_df, dest_object_name)


def once():
    logger.info("started sentiment score once")
    source = f"bluesky/{config.get('data', 'bluesky_historical')}_{now}.parquet"
    dest = f"bluesky/{config.get('data', 'bluesky_scored_historical')}_{now}.parquet"
    score_and_upload(source, dest, host="localhost:9000")
    logger.info("ended sentiment score once")


def everyday():
    logger.info("started sentiment score daily")
    source = f"bluesky/{config.get('data', 'bluesky_daily')}_{now}.parquet"
    dest = f"bluesky/{config.get('data', 'bluesky_scored_daily')}_{now}.parquet"
    score_and_upload(source, dest, host="minio:9000")
    logger.info("ended sentiment score daily")


if __name__ == "__main__":
    try:
        once()
        logger.info("sentiment_score successfull.")
    except Exception as e:
        logger.exception(f"sentiment_score failed due to an error: {e}")
