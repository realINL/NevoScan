"""
Тесты для app.Nevoscan.Nevoscan.Nevoscan (логика predict и веток ошибок).

Экземпляр создаётся через object.__new__, без вызова __init__: иначе при
импорте тестов подтягивались бы YOLO/DeepLab/ResNet и файлы весов из Config.
Все тяжёлые шаги подменяются через patch.object на «манглированные» имена
методов (_Nevoscan__...).
"""
from unittest.mock import patch

import numpy as np
import pytest
import torch

from app.Nevoscan.Nevoscan import Nevoscan
from app.Models.Schemas import (
    CompletedInferenceResult,
    NoObjectInferenceResult,
    ResultStatus,
)


def _nevoscan_without_init() -> Nevoscan:
    """Nevoscan без конструктора: только CPU-устройство для совместимости с моками."""
    n = object.__new__(Nevoscan)
    n._Nevoscan__DEVICE = torch.device("cpu")
    return n


def test_predict_none_upload_returns_none() -> None:
    """Если файл не передан, тело predict не выполняется — сейчас возвращается None."""
    n = _nevoscan_without_init()
    assert n.predict(None) is None


def test_predict_invalid_bytes_preprocess_returns_error() -> None:
    """Невалидные байты изображения: __preprocess бросает ValueError → ERROR."""
    n = _nevoscan_without_init()
    out = n.predict(b"not-a-valid-image")
    assert isinstance(out, NoObjectInferenceResult)
    assert out.status == ResultStatus.ERROR


def test_predict_no_detection_returns_no_object() -> None:
    """Детекция не нашла бокс: ожидаем NoObjectInferenceResult(NO_OBJECT)."""
    n = _nevoscan_without_init()
    fake_bgr = np.zeros((64, 64, 3), dtype=np.uint8)

    with (
        patch.object(n, "_Nevoscan__preprocess", return_value=fake_bgr),
        patch.object(n, "_Nevoscan__detection", return_value=(None, fake_bgr)),
    ):
        out = n.predict(b"ignored")

    assert isinstance(out, NoObjectInferenceResult)
    assert out.status == ResultStatus.NO_OBJECT


def test_predict_unexpected_exception_returns_error() -> None:
    """Любая ошибка вне ValueError логируется и мапится в ERROR."""
    n = _nevoscan_without_init()
    fake_bgr = np.zeros((32, 32, 3), dtype=np.uint8)

    with (
        patch.object(n, "_Nevoscan__preprocess", return_value=fake_bgr),
        patch.object(
            n, "_Nevoscan__detection", side_effect=RuntimeError("model failure")
        ),
    ):
        out = n.predict(b"x")

    assert isinstance(out, NoObjectInferenceResult)
    assert out.status == ResultStatus.ERROR


def test_predict_success_returns_completed_inference_result() -> None:
    """
    Успешный путь: мокаем цепочку после препроцесса.
    Проверяем тип ответа, текст класса и наличие кропа/маски (ndarray).
    """
    n = _nevoscan_without_init()
    fake_bgr = np.zeros((100, 100, 3), dtype=np.uint8)
    box = np.array([10, 10, 50, 50], dtype=np.float32)
    cropped = np.ones((40, 40, 3), dtype=np.uint8) * 128
    mask = np.zeros((40, 40), dtype=np.uint8)

    with (
        patch.object(n, "_Nevoscan__preprocess", return_value=fake_bgr),
        patch.object(n, "_Nevoscan__detection", return_value=(box, fake_bgr)),
        patch.object(n, "_Nevoscan__crop_image", return_value=cropped),
        patch.object(n, "_Nevoscan__segmentation", return_value=mask),
        patch.object(
            n,
            "_Nevoscan__classify",
            return_value=("Доброкачественное", 0.7, 0.3),
        ),
    ):
        out = n.predict(b"ignored")

    assert isinstance(out, CompletedInferenceResult)
    assert out.status == "completed"
    assert out.result == "Доброкачественное"
    assert out.probability_benign == 0.7
    assert out.probability_malign == 0.3
    assert np.array_equal(out.cropped_image, cropped)
    assert np.array_equal(out.mask, mask)
