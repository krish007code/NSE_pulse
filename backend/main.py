from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from dependencies import limiter, get_client
from routers.v1 import ticker, pipeline

app = FastAPI(title="NSE Pulse API")
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"message": "rate limit exceeded"})


@app.get("/health", tags=["health"])
def health():
    return {"status": "NSE Pulse API running"}


app.include_router(ticker.router, prefix="/api/v1")
app.include_router(pipeline.router, prefix="/api/v1")
