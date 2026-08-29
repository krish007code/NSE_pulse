import os
import time
import sys
import configparser
from pathlib import Path
from datetime import datetime, timezone, timedelta

import polars as pl
from dotenv import load_dotenv
from atproto import Client
from atproto_client.exceptions import AtProtocolError

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))
from utility.custom_logger import setup_logger

log_directory = project_root / "utility/logs"
logger = setup_logger(log_dir=log_directory)

load_dotenv()
config_path = project_root / "config.ini"
config = configparser.ConfigParser(allow_no_value=True)
config.read(config_path)
logger.info("read config")

BLUESKY_HANDLE = os.environ.get("BLUESKY_HANDLE")
BLUESKY_APP_PASSWORD = os.environ.get("BLUESKY_APP_PASSWORD")

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

bluesky_tickers = config.get("bluesky_tickers", "holder")
holder = [line.strip() for line in bluesky_tickers.split("\n") if line.strip()]
logger.info(f"found {len(holder)} bluesky tickers")

MAX_POSTS_PER_KEYWORD = 100
REQUEST_DELAY_SECONDS = 1.0

FINANCE_CONTEXT_WORDS = {
    "stock", "share", "shares", "nse", "bse", "nifty", "sensex",
    "target", "buy", "sell", "rupee", "₹", "q1", "q2", "q3", "q4",
    "earnings", "results", "ipo", "market cap",
}


def looks_finance_relevant(text: str, symbol: str) -> bool:
    text_lower = text.lower()
    has_context = any(word in text_lower for word in FINANCE_CONTEXT_WORDS)
    has_cashtag = f"${symbol.lower()}" in text_lower
    return has_cashtag or has_context


def keywords_for_symbol(symbol: str) -> list[str]:
    return [f"${symbol}", f"{symbol} stock", f"{symbol} share", f"{symbol} results"]


def post_to_record(post_view, ticker_symbol: str, matched_keyword: str) -> dict:
    record = post_view.record
    text = getattr(record, "text", "")
    return {
        "uri": post_view.uri,
        "cid": post_view.cid,
        "author_handle": post_view.author.handle,
        "author_did": post_view.author.did,
        "text": text,
        "created_at": getattr(record, "created_at", None),
        "collected_at": datetime.now(timezone.utc).isoformat(),
        "like_count": post_view.like_count,
        "repost_count": post_view.repost_count,
        "reply_count": post_view.reply_count,
        "ticker": ticker_symbol,
        "matched_keyword": matched_keyword,
        "is_finance_relevant": looks_finance_relevant(text, ticker_symbol),
        "source": "bluesky",
    }


def search_keyword(client: Client, keyword: str, ticker_symbol: str, since_date: str, max_posts: int) -> list[dict]:
    collected: list[dict] = []
    cursor = None

    while len(collected) < max_posts:
        params = {
            "q": keyword,
            "limit": min(100, max_posts - len(collected)),
            "sort": "latest",
        }
        if since_date:
            params["since"] = since_date
        if cursor:
            params["cursor"] = cursor

        try:
            response = client.app.bsky.feed.search_posts(params)
        except AtProtocolError as e:
            logger.warning(f"search failed for '{keyword}': {e}")
            break

        posts = response.posts
        if not posts:
            break

        for post in posts:
            collected.append(post_to_record(post, ticker_symbol, keyword))

        cursor = response.cursor
        if not cursor:
            break
        time.sleep(REQUEST_DELAY_SECONDS)

    return collected


def deduplicate(records: list[dict]) -> list[dict]:
    seen = set()
    unique = []
    for r in records:
        if r["uri"] not in seen:
            seen.add(r["uri"])
            unique.append(r)
    return unique


def collect_tickers(since_date: str | None) -> pl.DataFrame | None:
    client = Client()
    client.login(BLUESKY_HANDLE, BLUESKY_APP_PASSWORD)
    logger.info(f"logged in as {BLUESKY_HANDLE}")

    all_records = []
    for symbol in holder:
        logger.info(f"searching ticker: {symbol}")
        ticker_records = []
        for keyword in keywords_for_symbol(symbol):
            results = search_keyword(client, keyword, symbol, since_date, MAX_POSTS_PER_KEYWORD)
            ticker_records.extend(results)
            time.sleep(REQUEST_DELAY_SECONDS)
        ticker_records = deduplicate(ticker_records)
        logger.info(f"{symbol}: {len(ticker_records)} unique posts")
        all_records.extend(ticker_records)

    all_records = deduplicate(all_records)
    if not all_records:
        logger.warning("no records collected")
        return None

    return pl.DataFrame(all_records)


def historical_load(days_back: int = 90) -> pl.DataFrame | None:
    # note: Bluesky search doesn't reliably index a full year back --
    # 90 days is a more realistic ceiling to actually get results
    logger.info("started bluesky historical_load")
    since_date = (datetime.now(timezone.utc) - timedelta(days=days_back)).isoformat()
    return collect_tickers(since_date)


def daily_load() -> pl.DataFrame | None:
    logger.info("started bluesky daily_load")
    since_date = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
    return collect_tickers(since_date)

if __name__ == "__main__":
    try:
        historical_load()
        logger.info("bluesky ingestion successful")
    except Exception as e:
        logger.exception(f"bluesky script failed: {e}")