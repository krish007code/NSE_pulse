import os
import psutil
from dotenv import load_dotenv
from rich.console import Console
from rich.table import Table

load_dotenv()
console = Console()

services = [
    ("PostgreSQL", "POSTGRES_EXTERNAL_PORT", 5433),
    ("ClickHouse HTTP", "CLICKHOUSE_HTTP_PORT", 8123),
    ("ClickHouse Native", "CLICKHOUSE_NATIVE_PORT", 9005),
    ("MinIO API", "MINIO_API_PORT", 9000),
    ("MinIO Console", "MINIO_CONSOLE_PORT", 9001),
    ("FastAPI", "FASTAPI_PORT", 8000),
    ("Airflow", "AIRFLOW_PORT", 8080),
    ("Metabase", "METABASE_PORT", 3000),
]


def get_port_value(key, default):
    try:
        port = int(os.getenv(key, str(default)))
        return port if 1 <= port <= 65535 else None
    except ValueError:
        return None


def get_listening_ports():
    port_info = {}

    try:
        connections = psutil.net_connections(kind="tcp")
    except (psutil.AccessDenied, OSError):
        return None

    for conn in connections:
        if conn.status != psutil.CONN_LISTEN or not conn.laddr:
            continue

        try:
            process = psutil.Process(conn.pid) if conn.pid else None
            name = process.name() if process else "Unknown"
            if conn.pid:
                name += f" (PID {conn.pid})"
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            name = f"PID {conn.pid} (unknown)"

        port_info.setdefault(conn.laddr.port, set()).add(name)

    return port_info


def main():
    listening_ports = get_listening_ports()

    table = Table(title="NSE Pulse — Port Availability")
    table.add_column("Service", style="cyan")
    table.add_column("Host Port", justify="right")
    table.add_column("Status")
    table.add_column("Process")

    for service, key, default in services:
        port = get_port_value(key, default)

        if port is None:
            table.add_row(service, "-", "[red]INVALID[/red]", "-")
        elif listening_ports is None:
            table.add_row(service, str(port), "[yellow]UNKNOWN[/yellow]", "-")
        elif port in listening_ports:
            process = ", ".join(sorted(listening_ports[port]))
            table.add_row(service, str(port), "[red]IN USE[/red]", process)
        else:
            table.add_row(service, str(port), "[green]FREE[/green]", "-")

    console.print(table)


if __name__ == "__main__":
    main()
