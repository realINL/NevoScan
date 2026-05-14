from io import BytesIO
from unittest.mock import AsyncMock

from app.core.exceptions import FileError, TaskError
from app.schemas.schemas import LoadImageResponse
from app.tests.helpers import PNG_BYTES, PDF_BYTES


def test_root(client) -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "MinIO File Uploader API"}


def test_health(client) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_load_image_success(client, task_service) -> None:
    task_service.create_task = AsyncMock(
        return_value=LoadImageResponse(task_id="abc123", status="pending")
    )

    response = client.post(
        "/load_image",
        files={"file": ("photo.png", BytesIO(PNG_BYTES), "image/png")},
    )

    assert response.status_code == 200
    assert response.json() == {"task_id": "abc123", "status": "pending"}


def test_load_image_file_error(client, task_service) -> None:
    task_service.create_task = AsyncMock(side_effect=FileError("Неверный файл"))

    response = client.post(
        "/load_image",
        files={"file": ("doc.pdf", BytesIO(PDF_BYTES), "application/pdf")},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Неверный файл"


def test_load_image_task_error(client, task_service) -> None:
    task_service.create_task = AsyncMock(side_effect=TaskError("S3 недоступен"))

    response = client.post(
        "/load_image",
        files={"file": ("photo.png", BytesIO(PNG_BYTES), "image/png")},
    )

    assert response.status_code == 500
    assert response.json()["detail"] == "S3 недоступен"


def test_get_task_success(client, task_service, mock_broker) -> None:
    response = client.get("/task/abc123")

    assert response.status_code == 200
    assert response.json()["task_id"] == "abc123"
    mock_broker.get_task.assert_called_once_with("abc123")


def test_get_task_error(client, task_service, mock_broker) -> None:
    mock_broker.get_task.side_effect = RuntimeError("redis error")

    response = client.get("/task/abc123")

    assert response.status_code == 500
    assert "redis error" in response.json()["detail"]
