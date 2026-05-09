import json

import redis
from datetime import datetime
from typing import Optional
import logging
from app.Config.config import Config
from app.Models.Schemas import TaskQueue

class RedisConsumer:

    def __init__(self):
        self.client = redis.Redis(
            host=Config.REDIS_HOST,
            port=Config.REDIS_PORT,
            # password=Config.REDIS_PASSWORD,
            db=Config.REDIS_DB,
            decode_responses=True)
        self.__REDIS_QUEUE_NAME = Config.REDIS_QUEUE_NAME
        try:
            self.client.ping()
        except redis.exceptions.RedisError as error:
            print(f"Ошибка Redis: {error}")

    def pop(self) -> Optional[TaskQueue]:
        try:
            result = self.client.blpop(self.__REDIS_QUEUE_NAME, timeout=0)
            if not result:
                return None

            _, data = result
            return self.__parse_task(data)

        except Exception as e:
            logging.error(f"Error popping task from Redis: {e}")
            return None

    def __parse_task(self, data: bytes) -> Optional[TaskQueue]:
        try:
            payload = json.loads(data)
            if isinstance(payload, dict):
                task_id = payload.get("task_id")
                status = payload.get("status")
                created_at = datetime.fromisoformat(payload.get("created_at"))
                updated_at = datetime.fromisoformat(payload.get("updated_at"))
                object_key = payload.get("object_key")

                task = TaskQueue(task_id=task_id, status=status, created_at=created_at, updated_at=updated_at, object_key=object_key)
                return  task
            else:
                return None
        except json.JSONDecodeError as e:
            logging.error(f"JSON decode error: {e}")
            return None
        except Exception as e:
            logging.error(f"Unexpected error parsing task: {e}")
            return None



