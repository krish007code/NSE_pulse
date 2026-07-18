from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Request
from fastapi.responses import JSONResponse
from typing import Annotated
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import clickhouse_connect
from clickhouse_connect.driver.client import Client
import os
from dotenv import load_dotenv
from pydantic import BaseModel


class TickerResponse(BaseModel):
    trade_date: str
    ticker_symbol: str
    close_price: float
    rolling_max_365d: float
    drawdown_pct: float


load_dotenv()
HOST = os.environ.get("CLICKHOUSE_HOST")
PORT = os.environ.get("CLICKHOUSE_HTTP_PORT", 8123)
USER = os.environ.get("CLICKHOUSE_USER")
PWD = os.environ.get("CLICKHOUSE_PWD")

app = FastAPI(title="NSE_pulse API")


def get_client():
    client = clickhouse_connect.get_client(
        host=HOST, port=int(PORT), username=USER, password=PWD
    )
    try:
        yield client  # give the connection to the endpoint
    finally:
        client.close()  # close it when request is done


ClientDep = Annotated[Client, Depends(get_client)]


limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
def rate_limit_handler(request: Request, exec: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"message": "rate limit exceeded"})


@app.get("/health", tags=["Core FastAPI mechanics"])
def health():
    return {"status": "NSE Pulse API running"}


@app.get("/tickers/compare", tags=["Core FastAPI mechanics"])
def get_tickers_compare(symbols: str, client: ClientDep):
    symbol_list = tuple(symbols.strip().upper().split(","))
    result = client.query(
        f"SELECT * FROM default.mart_drawdown WHERE ticker_symbol in {symbol_list} ORDER BY trade_date desc LIMIT {len(symbol_list)}"
    )
    return result.named_results()


@app.get("/ticker/{ticker}/summary", tags=["Core FastAPI mechanics"])
@limiter.limit("30/minute")
def get_summary(request: Request, ticker: str, client: ClientDep):
    result = client.query(
        "SELECT * FROM default.mart_drawdown WHERE ticker_symbol = {ticker:String} ORDER BY trade_date desc LIMIT 1",
        parameters={"ticker": ticker},
    )
    if not result.named_results():
        raise HTTPException(status_code=404, detail=f"Ticker {ticker} not found")

    return result.named_results()


import httpx


def trigger_airflow_dag():
    httpx.post(
        "http://webserver:8080/api/v1/dags/nse_pipeline/dagRuns",
        json={"conf": {}},
        auth=("krish", "krish123"),
    )


@app.post("/refresh", tags=["refresh"])
def refresh_today(background_tasks: BackgroundTasks):
    background_tasks.add_task(trigger_airflow_dag)
    return {"message": "refresh request sent"}
