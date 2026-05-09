from typing import Literal

from pydantic import BaseModel, Field


class LoadImageResponse(BaseModel):
    task_id: str = Field(..., description="Идентификатор задачи обработки изображения")
    status: Literal["pending"] = Field(
        default="pending",
        description="Статус постановки задачи в очередь",
    )

from typing import Optional, Literal
from datetime import datetime
from pydantic import BaseModel, Field


class TaskResult(BaseModel):
    status: Literal["completed", "no_object"] = Field(
        ...,
        description="Статус результата обработки изображения"
    )
    result: str = Field(
        None, 
        description="Результат обработки изображения (например, 'Доброкачественное' или 'Злокачественное')"
    )
    probability_malign: float = Field(
        None, 
        description="Вероятность злокачественности"
    )
    probability_benign: float = Field(
        None, 
        description="Вероятность доброкачественности"
    )
    cropped_image_url: str = Field(
        None, 
        description="URL обрезанного изображения"
    )
    hair_removed_rgb_image_url: str = Field(
        None, 
        description="URL изображения без волос (RGB)"
    )
    mask_url: str = Field(
        None, 
        description="URL маски"
    )


class TaskResponse(BaseModel):
    task_id: str = Field(..., description="Идентификатор задачи обработки изображения")
    status: Literal["pending", "processing", "completed", "no_object", "failed"] = Field(
        ...,
        description="Статус задачи"
    )
    created_at: datetime = Field(..., description="Время создания задачи")
    updated_at: datetime = Field(..., description="Время обновления задачи")
    object_key: str = Field(..., description="Ключ объекта в S3")
    result: Optional[TaskResult] = Field(
        None,
        description="Результат обработки изображения",
        example={
            "status": "completed",
            "result": "Доброкачественное",
            "probability_malign": 0.2,
            "probability_benign": 0.7,
            "cropped_image_url": "https://example.com/cropped_image.jpg",
            "hair_removed_rgb_image_url": "https://example.com/hair_removed_rgb_image.jpg",
            "mask_url": "https://example.com/mask.jpg",
        }
    )