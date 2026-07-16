from fastapi import FastAPI
import clickhouse_connect
import os
from dotenv import load_dotenv

load_dotenv()
HOST = os.environ.get("CLICKHOUSE_HOST")
PORT = os.environ.get("CLICKHOUSE_HTTP_PORT")
USER = os.environ.get("CLICKHOUSE_USER")
PWD = os.environ.get("CLICKHOUSE_PWD")

app = FastAPI()
client = clickhouse_connect.get_client(
    host=HOST, port=PORT, username=USER, password=PWD
)


@app.get("/health")
def health():
    return {"status": "NSE Pulse API running"}


@app.get("/drawdown")
def get_drawdown(ticker: str):
    result = client.query(
        f"SELECT * FROM default.mart_drawdown WHERE ticker_symbol = '{ticker}'"
    )
    return result.named_results()


@app.get("/ticker/{symbol}/price")
def get_ticker_price(symbol: str):
    result = client.query(
        f"SELECT * FROM default.stg_raw_nse__daily_prices WHERE ticker_symbol = '{symbol}' ORDER BY trade_date desc LIMIT 1"
    )
    return result.named_results()


@app.get("/ticker/")
def about_ticker(
    ticker_symbol: str,
    trade_date: str,
):
    result = client.query(
        f"SELECT * FROM default.stg_raw_nse__daily_prices WHERE ticker_symbol = '{ticker_symbol}' and trade_date = {trade_date}"
    )
    return result.named_results()
