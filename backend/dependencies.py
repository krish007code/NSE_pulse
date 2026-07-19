from slowapi import Limiter
from slowapi.util import get_remote_address
import clickhouse_connect
import os

HOST = os.environ.get("CLICKHOUSE_HOST")
PORT = os.environ.get("CLICKHOUSE_HTTP_PORT")
USER = os.environ.get("CLICKHOUSE_USER")
PWD = os.environ.get("CLICKHOUSE_PWD")

limiter = Limiter(key_func=get_remote_address)


def get_client():
    client = clickhouse_connect.get_client(
        host=HOST, port=int(PORT), username=USER, password=PWD
    )
    try:
        yield client
    finally:
        client.close()
