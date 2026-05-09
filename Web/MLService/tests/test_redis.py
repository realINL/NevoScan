"""
Тесты RedisConsumer / RedisProducer без реального подключения к Redis.

Клиент redis.Redis подменяется через patch, чтобы не требовать живого сервера
и не зависеть от Config при инициализации.
"""
import json
from datetime import datetime
from unittest.mock import MagicMock, patch

import redis

from app.Infrastructure.RedisConsumer import RedisConsumer
from app.Infrastructure.RedisProducer import RedisProducer
from app.Models.Schemas import NoObjectResult, ResultStatus, TaskResult, TaskStatus


@patch("app.Infrastructure.RedisConsumer.redis.Redis")
def test_consumer_pop_returns_taskqueue(mock_redis_cls: MagicMock) -> None:
    """Корректный JSON из очереди парсится в TaskQueue с ожидаемыми полями."""
    mock_client = MagicMock()
    mock_redis_cls.return_value = mock_client

    payload = {
        "task_id": "task-123",
        "status": "pending",
        "created_at": "2026-01-01T12:00:00",
        "updated_at": "2026-01-01T12:01:00",
        "object_key": "uploads/image.png",
    }
    mock_client.blpop.return_value = ("queue", json.dumps(payload))

    consumer = RedisConsumer()
    task = consumer.pop()

    assert task is not None
    assert task.task_id == "task-123"
    assert task.status == TaskStatus.PENDING
    assert task.object_key == "uploads/image.png"


@patch("app.Infrastructure.RedisConsumer.redis.Redis")
def test_consumer_pop_returns_none_on_invalid_json(mock_redis_cls: MagicMock) -> None:
    """Невалидный JSON: __parse_task возвращает None, pop() не падает."""
    mock_client = MagicMock()
    mock_redis_cls.return_value = mock_client
    mock_client.blpop.return_value = ("queue", "not-json")

    consumer = RedisConsumer()

    assert consumer.pop() is None


@patch("app.Infrastructure.RedisConsumer.redis.Redis")
def test_consumer_pop_returns_none_on_redis_exception(mock_redis_cls: MagicMock) -> None:
    """Ошибка при blpop перехватывается, pop() возвращает None."""
    mock_client = MagicMock()
    mock_redis_cls.return_value = mock_client
    mock_client.blpop.side_effect = redis.exceptions.RedisError("boom")

    consumer = RedisConsumer()

    assert consumer.pop() is None


@patch("app.Infrastructure.RedisProducer.redis.Redis")
def test_producer_push_uses_task_id_and_serialized_payload(
    mock_redis_cls: MagicMock,
) -> None:
    """Результат пишется под ключом task_id, значение — model_dump_json()."""
    mock_client = MagicMock()
    mock_client.set.return_value = True
    mock_redis_cls.return_value = mock_client

    producer = RedisProducer()
    task = TaskResult(
        task_id="task-321",
        status=TaskStatus.COMPLETED,
        created_at=datetime(2026, 1, 1, 12, 0, 0),
        updated_at=datetime(2026, 1, 1, 12, 5, 0),
        object_key="uploads/image.png",
        result=NoObjectResult(status=ResultStatus.NO_OBJECT),
    )

    producer.push(task)

    expected_payload = task.model_dump_json()
    mock_client.set.assert_called_once_with("task-321", expected_payload)


@patch("app.Infrastructure.RedisProducer.redis.Redis")
def test_producer_push_handles_redis_error(mock_redis_cls: MagicMock) -> None:
    """RedisError при set не пробрасывается наружу (push ловит и печатает)."""
    mock_client = MagicMock()
    mock_client.set.side_effect = redis.exceptions.RedisError("failed")
    mock_redis_cls.return_value = mock_client

    producer = RedisProducer()
    task = TaskResult(
        task_id="task-500",
        status=TaskStatus.FAILED,
        created_at=datetime(2026, 1, 1, 12, 0, 0),
        updated_at=datetime(2026, 1, 1, 12, 5, 0),
        object_key="uploads/image.png",
        result=NoObjectResult(status=ResultStatus.ERROR),
    )

    producer.push(task)

    mock_client.set.assert_called_once()
