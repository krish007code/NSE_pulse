import yfinance as yf
import polars as pl
from tqdm import tqdm

from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime("%Y-%m-%d")

from pathlib import Path

project_root = Path(__file__).resolve().parent.parent
config_path = project_root / "config.ini"
data_dir = project_root / "data"
import configparser

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


def one_time_load():
    temp = []
    for code in tqdm(holder, desc="doing....."):
        dat = yf.Ticker(code).history(period="5y")

        if dat.empty:
            print(f"empty {code}")
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
    print(df.shape)
    output_path = data_dir / "portfolio_data_historical.parquet"
    df.write_parquet(output_path)

    config.set("data_paths", "historical_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)


def daily_load():
    tmp = []
    for c in tqdm(holder, desc="doing....."):
        data = yf.Ticker(c).history(period="1d")

        if data.empty:
            print(f"empty {c}")
            continue

        data.index = data.index.tz_convert("UTC")
        data = data.reset_index()  # for date

        df = pl.from_pandas(data)

        df = df.with_columns(
            [pl.lit(c).alias("ticker"), pl.lit(get_asset_class(c)).alias("asset_class")]
        )

        tmp.append(df)
    df = pl.concat(tmp)
    print(df.shape)
    output_path = data_dir / f"portfolio_data_{now}.parquet"
    df.write_parquet(output_path)
    config.set("data_paths", "daily_path", str(output_path))
    with open(config_path, "w", encoding="utf-8") as configfile:
        config.write(configfile, space_around_delimiters=True)


if __name__ == "__main__":
    one_time_load()
