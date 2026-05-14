from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers.tasks import router
from app.services.task_service import TaskService


@pytest.fixture
def mock_broker() -> MagicMock:
    broker = MagicMock()
    broker.create_task.return_value = "abc123"
    broker.get_task.return_value = {
        "task_id": "abc123",
        "status": "pending",
        "created_at": "2026-01-01T12:00:00",
        "updated_at": "2026-01-01T12:00:00",
        "object_key": "abc123_original.png",
    }
    return broker


@pytest.fixture
def mock_s3() -> MagicMock:
    s3 = MagicMock()
    s3.upload_file = AsyncMock(return_value="abc123_original.png")
    return s3


@pytest.fixture
def task_service(mock_broker: MagicMock, mock_s3: MagicMock) -> TaskService:
    return TaskService(mock_broker, mock_s3)


@pytest.fixture
def test_app(task_service: TaskService) -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    app.state.task_service = task_service
    return app


@pytest.fixture
def client(test_app: FastAPI) -> TestClient:
    return TestClient(test_app)
