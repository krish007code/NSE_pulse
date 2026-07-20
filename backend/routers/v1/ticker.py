from fastapi import APIRouter, HTTPException, Depends, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import Annotated
from clickhouse_connect.driver.client import Client
from dependencies import get_client, limiter

router = APIRouter(prefix="/ticker", tags=["ticker"])
ClientDep = Annotated[Client, Depends(get_client)]


@router.get("/compare")
def compare(symbols: str, client: ClientDep):
    symbol_list = tuple(symbols.strip().upper().split(","))
    result = client.query(
        f"SELECT * FROM default.mart_drawdown WHERE ticker_symbol in {symbol_list} ORDER BY trade_date desc LIMIT {len(symbol_list)}"
    )
    return result.named_results()


@router.get("/{ticker}/summary")
@limiter.limit("30/minute")
def summary(request: Request, ticker: str, client: ClientDep):
    result = client.query(
        "SELECT * FROM default.mart_drawdown WHERE ticker_symbol = {ticker:String} ORDER BY trade_date desc LIMIT 1",
        parameters={"ticker": ticker},
    )
    if not result.named_results():
        raise HTTPException(status_code=404, detail=f"Ticker {ticker} not found")
    return result.named_results()
