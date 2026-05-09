from datetime import datetime
from enum import Enum
from pydantic import BaseModel
from typing import Any, Literal, Union

class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    NO_OBJECT = "no_object"
    FAILED = "failed"

class ResultStatus(str, Enum):
    COMPLETED = "completed"
    NO_OBJECT = "no_object"
    ERROR = "error"

class TaskQueue(BaseModel):
    task_id: str
    status: TaskStatus
    created_at: datetime
    updated_at: datetime
    object_key: str

class CompletedResult(BaseModel):
    status: Literal["completed"]
    result: str
    probability_malign: float
    probability_benign: float
    cropped_image_url: str
    mask_url: str

class NoObjectResult(BaseModel):
    status: ResultStatus

Result = Union[CompletedResult, NoObjectResult]

class TaskResult(BaseModel):
    task_id: str
    status: TaskStatus
    created_at: datetime
    updated_at: datetime
    object_key: str
    result: Result

class CompletedInferenceResult(BaseModel):
    status: Literal[ResultStatus.COMPLETED] 
    result: str
    probability_malign: float
    probability_benign: float
    # Nevoscan отдаёт ndarray до кодирования в S3
    cropped_image: Any
    mask: Any

class NoObjectInferenceResult(BaseModel):
    status: ResultStatus

InferenceResult = Union[CompletedInferenceResult, NoObjectInferenceResult]
