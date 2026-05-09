# import os
# import json
# import uuid
# import asyncio
# import redis
# from datetime import datetime
# from app.Service.InferenceService import Instance
# from ..schemas import TaskResult, TaskResponse
# from app.config import Config
#
# REDIS_HOST = Config.REDIS_HOST
# REDIS_PORT = Config.REDIS_PORT
# REDIS_DB = Config.REDIS_DB
# REDIS_USERNAME = Config.REDIS_USERNAME
# REDIS_PASSWORD = Config.REDIS_PASSWORD
# REDIS_QUEUE_NAME = Config.REDIS_QUEUE_NAME
# REDIS_GATEWAY_QUEUE_NAME = Config.REDIS_GATEWAY_QUEUE_NAME
#
# instance = Instance()
#
#
# def parse_task(message: str) -> tuple[str, str, str, str]:
#     """
#     Поддерживаем 2 формата сообщения:
#     1) обычная строка: "<object_key>"
#     2) JSON: {"object_key": "...", "file_path": "..."}
#     """
#     task_id = uuid.uuid4().hex
#     file_path = f"/tmp/{uuid.uuid4().hex}.jpg"
#     reply_queue = REDIS_GATEWAY_QUEUE_NAME
#
#     try:
#         payload = json.loads(message)
#         if isinstance(payload, dict):
#             object_key = payload.get("object_key")
#             task_id = payload.get("task_id", task_id)
#             file_path = payload.get("file_path", file_path)
#             reply_queue = payload.get("reply_queue", reply_queue)
#             if object_key:
#                 return task_id, object_key, file_path, reply_queue
#     except json.JSONDecodeError:
#         pass
#
#     return task_id, message, file_path, reply_queue
#
# def parse_task_response(redis_message: str) -> TaskResponse:
#     """
#     Парсит задачу из Redis-сообщения по схеме TaskResponse.
#
#     Args:
#         redis_message (str): Сообщение из Redis (в формате JSON).
#
#     Returns:
#         TaskResponse: Сериализованный объект TaskResponse.
#     """
#     data = json.loads(redis_message)
#     # Если 'result' присутствует - это подмодель TaskResult, обработаем отдельно
#     # if 'result' in data and isinstance(data['result'], dict):
#     #     data['result'] = TaskResult(**data['result'])

#     return TaskResponse(**data)
#
#
#
# def publish_result(
#     client: redis.Redis,
#     task: TaskResponse,
#     result: TaskResult | dict | None,
#     status: str | None = None
# ) -> None:
#     if status == "failed":
#         task.status = status
#
#     elif status == "completed":
#         if isinstance(result, TaskResult):
#             task.status = status
#             task.result = result
#         elif isinstance(result, dict):
#             task.status = result.get("status")
#
#     task.updated_at = datetime.now()
#
#     task_json = task.model_dump_json()
#     client.set(task.task_id, task_json)
#     print(f"[SET]: task_id={task.task_id} status={task.status} time={task.updated_at}")
#
#
# def main() -> None:
#     client = redis.Redis(
#         host=Config.REDIS_HOST,
#         port=Config.REDIS_PORT,
#         # password=Config.REDIS_PASSWORD,
#         db=Config.REDIS_DB,
#         decode_responses=True)
#
#     try:
#         client.ping()
#         print(f"Подключение к Redis успешно. Слушаю очередь '{REDIS_QUEUE_NAME}'...")
#
#         while True:
#             item = client.blpop(REDIS_QUEUE_NAME, timeout=0)
#             if item:
#                 _, message = item
#                 print(f"[QUEUE:{REDIS_QUEUE_NAME}] {message}")
#                 task = parse_task_response(message)
#                 try:
#                     result = asyncio.run(instance.p(task))
#                     print(f"[RESULT] {result}")
#                     publish_result(client, task, result, status="completed")
#                 except Exception as task_error:
#                     error_result = {"message": str(task_error)}
#                     publish_result(client, task, error_result, status="failed")
#                     print(f"[TASK_ERROR] task_id={task.task_id} error={task_error}")
#     except KeyboardInterrupt:
#         print("\nОстановка слушателя по Ctrl+C")
#     except redis.exceptions.RedisError as error:
#         print(f"Ошибка Redis: {error}")
#     except Exception as error:
#         print(f"Ошибка обработки задачи: {error}")
#
#
# if __name__ == "__main__":
#     print("hi")
#     main()