import yfinance as yf
import polars as pl
from tqdm import tqdm
from datetime import datetime, timezone
now = datetime.now(timezone.utc).strftime('%Y-%m-%d')
# AI part start --------------------------------------------------------------------------------------------------------------------------------------------------

def get_asset_class(ticker):
    # Nifty 50 Equities
    if ticker.endswith(".NS"):
        return "Equity (Nifty 50)"
    
    # Cryptocurrencies
    elif ticker.endswith("-USD"):
        return "Cryptocurrency"
    
    # Precious Metals
    elif ticker in ["GC=F", "SI=F", "PL=F", "PA=F"]:
        return "Commodity (Precious Metal)"
    
    # Base & Industrial Metals
    elif ticker in ["HG=F", "ALI=F"]:
        return "Commodity (Industrial Metal)"
    
    # Energy Resources
    elif ticker in ["CL=F", "BZ=F", "NG=F", "HO=F", "RB=F"]:
        return "Commodity (Energy)"
    
    # Agricultural Resources (Optional bonus)
    elif ticker in ["ZC=F", "ZW=F", "ZS=F", "CC=F", "KC=F"]:
        return "Commodity (Agriculture)"
    
    else:
        return "Unknown"


holder = [
    # ==========================================
    # 1. NIFTY 50 CONSTITUENTS (Equities)
    # ==========================================
    "ADANIENT.NS", "ADANIPORTS.NS", "APOLLOHOSP.NS", "ASIANPAINT.NS", "AXISBANK.NS",
    "BAJAJ-AUTO.NS", "BAJFINANCE.NS", "BAJAJFINSV.NS", "BEL.NS", "BHARTIARTL.NS",
    "BPCL.NS", "BRITANNIA.NS", "CIPLA.NS", "COALINDIA.NS", "DIVISLAB.NS",
    "DRREDDY.NS", "EICHERMOT.NS", "GRASIM.NS", "HCLTECH.NS", "HDFCBANK.NS",
    "HDFCLIFE.NS", "HEROMOTOCO.NS", "HINDALCO.NS", "HINDUNILVR.NS", "ICICIBANK.NS",
    "INDUSINDBK.NS", "INFY.NS", "ITC.NS", "JSWSTEEL.NS", "KOTAKBANK.NS",
    "LT.NS", "LTIM.NS", "M&M.NS", "MARUTI.NS", "NESTLEIND.NS", "NTPC.NS",
    "ONGC.NS", "POWERGRID.NS", "RELIANCE.NS", "SBILIFE.NS", "SBIN.NS",
    "SHRIRAMFIN.NS", "SUNPHARMA.NS", "TATACONSUM.NS", "TATAMOTORS.NS", 
    "TATASTEEL.NS", "TCS.NS", "TECHM.NS", "TITAN.NS", "TRENT.NS", 
    "ULTRACEMCO.NS", "WIPRO.NS",

    # ==========================================
    # 2. COMMODITIES, MINERALS & RESOURCES
    # ==========================================
    # Precious Metals
    "GC=F",     # Gold Futures
    "SI=F",     # Silver Futures
    "PL=F",     # Platinum Futures
    "PA=F",     # Palladium Futures
    
    # Base/Industrial Metals
    "HG=F",     # Copper Futures
    "ALI=F",    # Aluminum Futures
    
    # Energy Resources
    "CL=F",     # Crude Oil (WTI)
    "BZ=F",     # Crude Oil (Brent)
    "NG=F",     # Natural Gas
    "HO=F",     # Heating Oil
    "RB=F",     # RBOB Gasoline

    # Agriculture (Highly traded resources)
    "ZC=F",     # Corn Futures
    "ZW=F",     # Wheat Futures
    "ZS=F",     # Soybean Futures
    "CC=F",     # Cocoa Futures
    "KC=F",     # Coffee Futures

    # ==========================================
    # 3. CRYPTOCURRENCIES (Top Market Cap)
    # ==========================================
    "BTC-USD",  # Bitcoin
    "ETH-USD",  # Ethereum
    "SOL-USD",  # Solana
    "BNB-USD",  # Binance Coin
    "XRP-USD",  # Ripple
    "ADA-USD",  # Cardano
    "DOGE-USD", # Dogecoin
    "AVAX-USD", # Avalanche
    "LINK-USD", # Chainlink
    "DOT-USD",  # Polkadot
    "MATIC-USD",# Polygon (or POL-USD depending on YF updates)
    "LTC-USD",  # Litecoin
    "BCH-USD",  # Bitcoin Cash
    "UNI-USD",  # Uniswap
    "XLM-USD"   # Stellar
]
# Ai part end----------------------------------------------------------------------------------------------------------------------------------------------------
def one_time_load():
    temp = []
    for code in tqdm(holder, desc='doing.....'):
        dat = yf.Ticker(code).history(period='3y')

        if dat.empty:
            print(f'empty {code}')
            continue

        dat.index = dat.index.tz_convert('UTC')
        dat = dat.reset_index() # for date 
        
        df = pl.from_pandas(
            dat
        )
        
        df = df.with_columns([
            pl.lit(code).alias('ticker'),
            pl.lit(get_asset_class(code)).alias('asset_class')
        ])

        temp.append(df)
    df = pl.concat(temp)
    print(df.shape)
    df.write_parquet('portfolio_data.parquet')

def daily_load():
    tmp = []
    for c in tqdm(holder, desc='doing.....'):
        data = yf.Ticker(c).history(period='1d')

        if data.empty:
            print(f'empty {c}')
            continue

        data.index = data.index.tz_convert('UTC')
        data = data.reset_index() # for date 
        
        df = pl.from_pandas(
            data
        )
        
        df = df.with_columns([
            pl.lit(c).alias('ticker'),
            pl.lit(get_asset_class(c)).alias('asset_class')
        ])

        tmp.append(df)
    df = pl.concat(tmp)
    print(df.shape)
    df.write_parquet(f'/tmp/portfolio_data{now}.parquet')

if __name__ == "__main__":
    one_time_load()