import redis

from app.Config.config import Config
from app.Models.Schemas import TaskResult


class RedisProducer:

    def __init__(self):
        self.client = redis.Redis(
            host=Config.REDIS_HOST,
            port=Config.REDIS_PORT,
            # password=Config.REDIS_PASSWORD,
            db=Config.REDIS_DB,
            decode_responses=True)
        try:
            self.client.ping()
        except redis.exceptions.RedisError as error:
            print(f"Ошибка Redis: {error}")

    def push(self, task: TaskResult):
        try:
            response = self.__convert_task(task)
            result = self.client.set(task.task_id, response)
            if not result:
                print(f"Не удалось записать задачу {task.task_id} в Redis")
        except redis.exceptions.RedisError as error:
            print(f"Ошибка Redis при push: {error}")
        except Exception as e:
            print(f"Ошибка при сохранении задачи: {e}")

    def __convert_task(self, task: TaskResult):
        try:
            result = task.model_dump_json()
            return result
        except Exception as e:
            print(f"Ошибка сериализации объекта TaskResult: {e}")
            return None
   