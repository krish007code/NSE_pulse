from fastapi import APIRouter, BackgroundTasks
import httpx

router = APIRouter(prefix="/pipeline", tags=["pipeline"])


def trigger_airflow_dag():
    httpx.post(
        "http://webserver:8080/api/v1/dags/nse_pipeline/dagRuns",
        json={"conf": {}},
        auth=("krish", "krish123"),
    )


@router.post("/refresh")
def refresh(background_tasks: BackgroundTasks):
    background_tasks.add_task(trigger_airflow_dag)
    return {"message": "refresh request sent"}
