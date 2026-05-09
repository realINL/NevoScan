from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest

from app.Service.InferenceService import InferenceService
from app.Models.Schemas import (
    NoObjectInferenceResult,
    NoObjectResult,
    TaskQueue,
    TaskResult,
    ResultStatus,
    TaskStatus
)


@pytest.fixture
def sample_task() -> TaskQueue:
    return TaskQueue(
        task_id="task-1",
        status="pending",
        created_at=datetime(2026, 1, 1, 12, 0, 0),
        updated_at=datetime(2026, 1, 1, 12, 5, 0),
        object_key="uploads/test.png",
    )


def test_process_result_no_object(sample_task: TaskQueue) -> None:

    service = InferenceService(processor=MagicMock(), s3=MagicMock())
    inference = NoObjectInferenceResult(status=ResultStatus.NO_OBJECT)

    out = service.process_result(sample_task, inference)

    assert isinstance(out, TaskResult)
    assert out.task_id == sample_task.task_id
    assert out.status == "completed"
    assert out.object_key == sample_task.object_key
    assert out.created_at == sample_task.created_at
    assert isinstance(out.result, NoObjectResult)
    assert out.result.status == "no_object"


def test_process_result_inference_error(sample_task: TaskQueue) -> None:
    service = InferenceService(processor=MagicMock(), s3=MagicMock())
    inference = NoObjectInferenceResult(status=ResultStatus.ERROR)

    out = service.process_result(sample_task, inference)

    assert out.status == "failed"
    assert out.result.status == "error"



@patch.object(InferenceService, "download_image", return_value=None)
def test_process_task_no_downloaded_object(
    _mock_download: MagicMock, sample_task: TaskQueue
) -> None:
    mock_nevoscan = MagicMock()

    service = InferenceService(processor=mock_nevoscan, s3=MagicMock())
    out = service.process_task(sample_task)

    assert out.task_id == sample_task.task_id
    assert out.status == TaskStatus.FAILED
    assert out.result.status == ResultStatus.ERROR

@patch.object(InferenceService, "download_image", return_value=b"\xff\xd8\xff\xe0")
def test_process_task_broken_downloaded_object(
    _mock_download: MagicMock, sample_task: TaskQueue
) -> None:
    mock_nevoscan = MagicMock()
    mock_nevoscan.predict.return_value = NoObjectInferenceResult(status=ResultStatus.ERROR)

    service = InferenceService(processor=mock_nevoscan, s3=MagicMock())
    out = service.process_task(sample_task)

    mock_nevoscan.predict.assert_called_once_with(b"\xff\xd8\xff\xe0")
    assert out.task_id == sample_task.task_id
    assert out.status == TaskStatus.FAILED
    assert out.result.status == ResultStatus.ERROR

def test_process_task_invalid_task() -> None:
    mock_nevoscan = MagicMock()

    service = InferenceService(processor=mock_nevoscan, s3=MagicMock())

    with pytest.raises(ValueError) as exc_info:
        out = service.process_task(None)

    assert "Failed to parse task" in str(exc_info.value)
