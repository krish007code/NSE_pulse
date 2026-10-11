
import sys
import io
import os
import configparser
from datetime import datetime, timezone
from pathlib import Path

import polars as pl
from dotenv import load_dotenv
from minio import Minio
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import setup_logger

logger = setup_logger(log_dir=project_root / "utility/logs")

config_path = project_root / "config.ini"
config = configparser.ConfigParser()
config.read(config_path)
logger.info(f"Loaded config from {config_path}")

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

load_dotenv()
MINIO_USER = os.environ.get("MINIO_USER")
MINIO_PWD = os.environ.get("MINIO_PWD")
bucket = config.get("minio", "bucket")

analyzer = SentimentIntensityAnalyzer()


def label_from_compound(score: float) -> str:
    if score >= 0.05:
        return "positive"
    if score <= -0.05:
        return "negative"
    return "neutral"


def get_minio_client(host: str) -> Minio:
    return Minio(
        host,
        access_key=MINIO_USER,
        secret_key=MINIO_PWD,
        secure=False,
    )


def read_parquet_from_minio(client: Minio, object_name: str) -> pl.DataFrame:
    logger.info(f"Reading {object_name} from bucket {bucket}")
    response = client.get_object(bucket, object_name)

    try:
        buffer = io.BytesIO(response.read())
    finally:
        response.close()
        response.release_conn()

    return pl.read_parquet(buffer)


def write_parquet_to_minio(
    client: Minio,
    df: pl.DataFrame,
    object_name: str,
) -> None:
    buffer = io.BytesIO()
    df.write_parquet(buffer)
    buffer.seek(0)

    client.put_object(
        bucket_name=bucket,
        object_name=object_name,
        data=buffer,
        length=buffer.getbuffer().nbytes,
    )

    logger.info(f"Wrote {object_name} to bucket {bucket}")


def score_sentiment(df: pl.DataFrame) -> pl.DataFrame:
    logger.info(f"Scoring sentiment for {df.height} rows")

    compound_scores = [
        analyzer.polarity_scores(text)["compound"] if text else 0.0
        for text in df["text"].to_list()
    ]

    scored = df.with_columns(
        pl.Series("sentiment_compound", compound_scores)
    ).with_columns(
        pl.col("sentiment_compound")
        .map_elements(label_from_compound, return_dtype=pl.Utf8)
        .alias("sentiment_label"),
        (
            pl.col("like_count")
            + pl.col("repost_count")
            + pl.col("reply_count")
        ).alias("engagement_score"),
    )

    silver = scored.select([
        "uri",
        "ticker",
        "created_at",
        "sentiment_compound",
        "sentiment_label",
        "is_finance_relevant",
        "engagement_score",
        "source",
    ])

    logger.info(f"Scored {silver.height} rows")
    return silver


def score_and_upload(
    source_object_name: str,
    dest_object_name: str,
    host: str,
) -> None:
    client = get_minio_client(host)
    raw_df = read_parquet_from_minio(client, source_object_name)
    scored_df = score_sentiment(raw_df)
    write_parquet_to_minio(client, scored_df, dest_object_name)


def once() -> None:
    logger.info("Started historical sentiment scoring")

    source = (
        f"bluesky/{config.get('data', 'bluesky_historical')}_{now}.parquet"
    )
    dest = (
        f"bluesky/{config.get('data', 'bluesky_scored_historical')}_{now}.parquet"
    )

    score_and_upload(source, dest, host="localhost:9000")
    logger.info("Finished historical sentiment scoring")


def everyday() -> None:
    logger.info("Started daily sentiment scoring")

    source = f"bluesky/{config.get('data', 'bluesky_daily')}_{now}.parquet"
    dest = (
        f"bluesky/{config.get('data', 'bluesky_scored_daily')}_{now}.parquet"
    )

    score_and_upload(source, dest, host="minio:9000")
    logger.info("Finished daily sentiment scoring")


if __name__ == "__main__":
    try:
        once()
        logger.info("Sentiment scoring completed successfully")
    except Exception:
        logger.exception("Sentiment scoring failed")
        raise
