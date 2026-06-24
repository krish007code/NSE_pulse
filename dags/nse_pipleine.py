from airflow.decorators import dag, task
import pendulum

@dag(
    schedule="@daily",
    start_date=pendulum.datetime(2026, 6, 1, tz="UTC"),
    catchup=False,
    tags=["nse-pulse"],
)
def nse_pipeline():

    @task()
    def ingest():
        import sys
        sys.path.append('/opt/airflow/scripts')
        from ingest import daily_load
        daily_load()

    @task()
    def upload():
        import sys
        sys.path.append('/opt/airflow/scripts')
        from upload_minio import daily
        daily()

    @task()
    def load():
        import sys
        sys.path.append('/opt/airflow/scripts')
        from load_clickhouse import everyday
        everyday()

    ingest() >> upload() >> load()

nse_pipeline()