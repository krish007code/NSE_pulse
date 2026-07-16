import configparser
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
import polars as pl
import yfinance as yf
from tqdm import tqdm

# ai has bee used for logs
project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import logger

# mute yfinance
logging.getLogger("yfinance").setLevel(logging.CRITICAL)

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
config_path = project_root / "config.ini"
data_dir = project_root / "data"

config = configparser.ConfigParser(allow_no_value=True)
config.read(config_path)
logger.info(f"Loaded config from {config_path}")


def get_asset_class(ticker):
    if ticker.endswith(".NS"):
        return "Equity (Nifty 50)"
    elif ticker.endswith("-USD"):
        return "Cryptocurrency"
    elif ticker in ["GC=F", "SI=F", "PL=F", "PA=F"]:
        return "Commodity (Precious Metal)"
    elif ticker in ["HG=F", "ALI=F"]:
        return "Commodity (Industrial Metal)"
    elif ticker in ["CL=F", "BZ=F", "NG=F", "HO=F", "RB=F"]:
        return "Commodity (Energy)"
    elif ticker in ["ZC=F", "ZW=F", "ZS=F", "CC=F", "KC=F"]:
        return "Commodity (Agriculture)"
    else:
        return "Unknown"


ticker_symbols = config.get("ticker_symbols", "holder")
holder = [line.strip() for line in ticker_symbols.split("\n") if line.strip()]
logger.info(f"Found {len(holder)} ticker")


def one_time_load():
    logger.info("Start one_time_load")
    temp = []
    failed = []

    for code in tqdm(holder, desc="doing....."):
        dat = yf.Ticker(code).history(period="5y")

        if dat.empty:
            logger.warning(f"Ticker missing: {code}")
            failed.append(code)
            continue

        dat.index = dat.index.tz_convert("UTC")
        dat = dat.reset_index()

        df = pl.from_pandas(dat)
        df = df.with_columns(
            [
                pl.lit(code).alias("ticker"),
                pl.lit(get_asset_class(code)).alias("asset_class"),
            ]
        )
        temp.append(df)

    if failed:
        logger.error(f"failed to fetch {len(failed)} historical tickers: {failed}")

    if not temp:
        logger.error("No data fetched for any tickers")
        return

    df = pl.concat(temp)
    logger.info(f"historical data combined successfully Final shape: {df.shape}")

    output_path = data_dir / "portfolio_data_historical.parquet"
    df.write_parquet(output_path)
    logger.info(f"Saved historical parquet file to: {output_path}")

    config.set("data_paths", "historical_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)
    logger.info("Updated config.ini with historical_path.")


def daily_load():
    logger.info("Starting daily_load for 1-day data...")
    tmp = []
    failed = []

    for c in tqdm(holder, desc="Fetching Daily"):
        data = yf.Ticker(c).history(period="1d")

        if data.empty:
            logger.warning(f"Ticker missing or no daily data: {c}")
            failed.append(c)
            continue

        data.index = data.index.tz_convert("UTC")
        data = data.reset_index()

        df = pl.from_pandas(data)
        df = df.with_columns(
            [pl.lit(c).alias("ticker"), pl.lit(get_asset_class(c)).alias("asset_class")]
        )
        tmp.append(df)

    if failed:
        logger.error(f"Failed to fetch {len(failed)} daily tickers: {failed}")

    if not tmp:
        logger.error("No daily data fetched for any tickers. Aborting save.")
        return

    df = pl.concat(tmp)
    logger.info(f"Daily data combined successfully. Final shape: {df.shape}")

    output_path = data_dir / f"portfolio_data_{now}.parquet"
    df.write_parquet(output_path)
    logger.info(f"Saved daily parquet file to: {output_path}")

    config.set("data_paths", "daily_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)
    logger.info("Updated config.ini with daily_path.")


if __name__ == "__main__":
    try:
        one_time_load()
        # daily_load()
        logger.info("Script execution completed successfully.")
    except Exception as e:
        logger.exception(f"Script failed due to an unexpected error: {e}")
