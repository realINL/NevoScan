from redis import Redis
from redis.exceptions import RedisError
import logging
from datetime import datetime
import json
from app.schemas.schemas import TaskResponse
from app.core.config import Config

class Broker:
    

    def __init__(self):        
        try:
            self.redis_client = Redis(
                host=Config.REDIS_HOST,
                port=Config.REDIS_PORT,
                username=Config.REDIS_USERNAME,
                password=Config.REDIS_USER_PASSWORD,
                db=Config.REDIS_DB,
                decode_responses=True,
            )
            self.redis_client.ping()
            logging.info(f"Connected to Redis: {Config.REDIS_HOST}")
        except RedisError as e:
            logging.error(f"Error connecting to Redis: {e}")
            raise e

    def create_task(self, task_id, object_key):
        now = datetime.now().isoformat()
        
        task_payload = TaskResponse(
            task_id=task_id,
            status="pending",
            created_at=now,
            updated_at=now,
            object_key=object_key
        )

        json_payload = task_payload.model_dump_json()

        # Постановка задачи в очередь Redis
        try:
            self.redis_client.rpush(Config.REDIS_QUEUE_NAME, json_payload)
            logging.info(f"Task created: {task_id}")
        except RedisError as e:
            logging.error(f"Error sending message to Redis: {e}")
            raise e
        except Exception as e:
            logging.error(f"Error creating task: {e}")
            raise e

        # Создание задания в Redis
        try:
            self.redis_client.set(task_id, json_payload, ex=Config.REDIS_TASK_TTL)
            logging.info(f"Task set: {task_id}")
        except RedisError as e:
            logging.error(f"Error setting task: {e}")
            raise e
        except Exception as e:
            logging.error(f"Error setting task: {e}")
            raise e
        return task_id

    def get_task(self, task_id):
        try:
            task = self.redis_client.get(task_id)
            logging.info(f"Task get: {task_id}")
        except RedisError as e:
            logging.error(f"Error getting task: {e}")
            raise e
        except Exception as e:
            logging.error(f"Error getting task: {e}")
            raise e
        return json.loads(task)