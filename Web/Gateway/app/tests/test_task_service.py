from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.exceptions import FileError, TaskError
from app.services.task_service import TaskService
from app.tests.helpers import PDF_BYTES, PNG_BYTES, make_upload_file


@pytest.mark.asyncio
async def test_create_task_success(
    task_service: TaskService,
    mock_broker: MagicMock,
    mock_s3: MagicMock,
) -> None:
    file = make_upload_file(PNG_BYTES, "photo.png")

    response = await task_service.create_task(file)

    assert response.status == "pending"
    assert len(response.task_id) == 32
    mock_s3.upload_file.assert_awaited_once()
    mock_broker.create_task.assert_called_once()


@pytest.mark.asyncio
async def test_create_task_invalid_file(task_service: TaskService) -> None:
    file = make_upload_file(PDF_BYTES, "doc.pdf")

    with pytest.raises(FileError):
        await task_service.create_task(file)


@pytest.mark.asyncio
async def test_create_task_s3_failure(
    task_service: TaskService,
    mock_s3: MagicMock,
) -> None:
    mock_s3.upload_file = AsyncMock(return_value=None)
    file = make_upload_file(PNG_BYTES, "photo.png")

    with pytest.raises(TaskError, match="Ошибка загрузки файла в S3"):
        await task_service.create_task(file)


@pytest.mark.asyncio
async def test_create_task_broker_failure(
    task_service: TaskService,
    mock_broker: MagicMock,
) -> None:
    mock_broker.create_task.side_effect = RuntimeError("redis down")
    file = make_upload_file(PNG_BYTES, "photo.png")

    with pytest.raises(TaskError, match="Ошибка создания задачи"):
        await task_service.create_task(file)


def test_get_task(task_service: TaskService, mock_broker: MagicMock) -> None:
    result = task_service.get_task("abc123")

    assert result["task_id"] == "abc123"
    mock_broker.get_task.assert_called_once_with("abc123")
