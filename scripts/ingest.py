import configparser
import sys
from datetime import datetime, timezone
from pathlib import Path
import polars as pl
import yfinance as yf
from tqdm import tqdm

project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from utility.custom_logger import logger

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

config_path = project_root / "config.ini"
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


def data_from_yfinance(time):
    logger.info("started ingest function")
    temp = []
    for code in tqdm(holder, desc="doing....."):
        dat = yf.Ticker(code).history(period=time)

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

    if temp:
        df = pl.concat(temp)
    else:
        logger.warning("temp is empty")

    logger.info(f"data got {df.shape}")
    return df if temp else None


def one_time_load():
    logger.info("started one_time_load")
    time = "5y"
    return data_from_yfinance(time)


def daily_load():
    logger.info("started daily load")
    time = "1d"
    return data_from_yfinance(time)


if __name__ == "__main__":
    try:
        one_time_load()
        logger.info(" ingestion successful.")
    except Exception as e:
        logger.exception(f"Script failed {e}")
