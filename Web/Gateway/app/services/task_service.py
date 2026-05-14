from fastapi import UploadFile
from app.services.image_service import ImageService
from app.infrastructure.prometheus import PrometheusMetrics
from app.core.exceptions import TaskError
from app.schemas.schemas import LoadImageResponse
import uuid

class TaskService:

    def __init__(self, broker, s3_client):
        self.broker = broker
        self.s3_client = s3_client

    async def create_task(self, file: UploadFile):
        await ImageService.validate_file(file)
        
        task_id = uuid.uuid4().hex

        # Загрузка в S3
        object_key = await self.s3_client.upload_file(file, task_id)
        if object_key is None:
            raise TaskError("Ошибка загрузки файла в S3")

         # Создание задачи и постановка в очередь
        try:
            self.broker.create_task(task_id, object_key)
            PrometheusMetrics.GATEWAY_TASKS_CREATED_TOTAL.inc()
        except Exception as e:             
            raise TaskError(f"Ошибка создания задачи: {str(e)}")
       
        return LoadImageResponse(
            task_id=task_id,
            status="pending",
        )

    def get_task(self, task_id):
        return self.broker.get_task(task_id)