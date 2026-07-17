import configparser
import sys
from datetime import datetime, timezone
from pathlib import Path
import polars as pl
import yfinance as yf
from tqdm import tqdm

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))
from utility.custom_logger import logger

config_path = project_root / "config.ini"
data_dir = project_root / "data"

config = configparser.ConfigParser(allow_no_value=True)
config.read(config_path)


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
logger.info(f"found {len(holder)} tickers")


def one_time_load():
    temp = []
    for code in tqdm(holder, desc="doing....."):
        dat = yf.Ticker(code).history(period="1y")

        if dat.empty:
            logger.info(f"empty {code}")
            continue

        dat.index = dat.index.tz_convert("UTC")
        dat = dat.reset_index()  # for date

        df = pl.from_pandas(dat)
        df = df.with_columns(
            [
                pl.lit(code).alias("ticker"),
                pl.lit(get_asset_class(code)).alias("asset_class"),
            ]
        )
        temp.append(df)

    df = pl.concat(temp)
    logger.info(f"hostorical data{df.shape}")

    output_path = data_dir / "portfolio_data_historical.parquet"
    df.write_parquet(output_path)
    logger.info("wrote once file")

    config.set("data_paths", "historical_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)


def daily_load():
    tmp = []
    for c in tqdm(holder, desc="doing....."):
        data = yf.Ticker(c).history(period="1d")

        if data.empty:
            logger.info(f"empty {c}")
            continue

        data.index = data.index.tz_convert("UTC")
        data = data.reset_index()  # for date

        df = pl.from_pandas(data)
        df = df.with_columns(
            [pl.lit(c).alias("ticker"), pl.lit(get_asset_class(c)).alias("asset_class")]
        )
        tmp.append(df)

    df = pl.concat(tmp)
    logger.info(f"daily data{df.shape}")

    output_path = data_dir / f"portfolio_data_{now}.parquet"
    df.write_parquet(output_path)
    logger.info("wrote everyday file")

    config.set("data_paths", "daily_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)


if __name__ == "__main__":
    try:
        one_time_load()
        logger.info(" ingestion successful.")
    except Exception as e:
        logger.exception(f"Script failed {e}")
