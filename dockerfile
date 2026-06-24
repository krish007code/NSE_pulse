FROM apache/airflow:2.9.2

WORKDIR /opt/airflow/

COPY requirements.txt .

RUN pip install -r requirements.txt