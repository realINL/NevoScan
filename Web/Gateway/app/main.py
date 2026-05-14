from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import start_http_server
from app.core.logging import setup_logging
from app.infrastructure.broker import Broker
from app.infrastructure.s3 import S3Client
from app.services.task_service import TaskService
from app.routers.tasks import router as tasks_router
from app.routers.middleware import prometheus_middleware


setup_logging()


def create_app():
    app = FastAPI(
        title="NevoScan Gateway",
        version="1.0.0",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["https://twa777.ru"],  
        allow_credentials=True,
        allow_methods=["*"],  
        allow_headers=["*"],  
    )
    app.middleware("http")(prometheus_middleware)

    s3_client = S3Client()
    broker = Broker()
    task_service = TaskService(broker, s3_client)
    app.state.task_service = task_service
    
    start_http_server(8009)

    app.include_router(tasks_router)

    return app

app = create_app()
