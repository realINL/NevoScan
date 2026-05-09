import logging
from http.client import responses

import cv2
import numpy as np
from botocore.exceptions import ClientError
from app.Nevoscan.Nevoscan import Nevoscan
from datetime import datetime
from app.Infrastructure.s3client import S3client
from app.Models.Schemas import *



class InferenceService:

    def __init__(self, processor, s3):
        self.__nevoscan = processor
        self.__s3 = s3
        self.task_id = None

    def process_task(self, task: TaskQueue | None) -> TaskResult:
        if isinstance(task, TaskQueue):
            image = self.download_image(task.object_key)
            if isinstance(image, bytes):
                inference_result = self.__nevoscan.predict(image)
            else:
                inference_result = NoObjectInferenceResult(status=ResultStatus.ERROR)
            return self.process_result(task, inference_result)
        raise ValueError("Failed to parse task")

    def download_image(self, object_key) -> bytes | None:
        """Скачивает изображение из S3"""
        try:
            image_bytes = self.__s3.get_object(object_key)
            return image_bytes
        except ClientError as e:
            logging.error(f"{e}")
            return None
        except Exception as e:
            logging.error(f"{e}")
            return None

    def upload_images(self, images):
        """Загрузка изображений в s3"""
        presigned_urls = {}
        for key in images.keys():
            result = self.upload_image(images[key], key)
            presigned_urls[key] = result['url']
        return presigned_urls


    def upload_image(self, image, image_type):
        """Загрузка изображения в s3 с обработкой типов"""
        try:
            if not isinstance(image, np.ndarray):
                raise ValueError("Ожидается numpy.ndarray для загрузки изображения")

            image_to_save = image
            # Для масок и float-данных приводим к диапазону 0..255.

            if image_to_save.max() <= 1:
                image_to_save = (image_to_save * 255).astype(np.uint8)
            elif image_to_save.dtype != np.uint8:
                image_to_save = np.clip(image_to_save, 0, 255).astype(np.uint8)

            success, encoded_image = cv2.imencode(".png", image_to_save)
            if not success:
                raise ValueError("Не удалось закодировать изображение в PNG")

            object_key = f"{self.task_id}_{image_type}.png"
            filename = object_key
            content_type = "image/png"

            # Загрузка в s3
            file_url = self.__s3.put_object(encoded_image, object_key)

            # Генерируем URL для доступа к файлу
            presigned_url = self.__s3.generate_presigned_url(object_key)

            return {
                "filename": filename,
                "object_key": object_key,
                "content_type": content_type,
                "message": "Файл успешно загружен",
                "url": presigned_url
            }

        except ClientError as e:
            logging.error(f"{e}")

        except Exception as e:
            logging.error(f"{e}")

    def process_result(self, task: TaskQueue, result: InferenceResult) -> TaskResult:
        if isinstance(result, NoObjectInferenceResult):
            result = NoObjectResult(
                status=result.status
            )
            if result.status == ResultStatus.ERROR:
                status = TaskStatus.FAILED
            else:
                status = TaskStatus.COMPLETED

            return TaskResult(
                task_id=task.task_id,
                status=status,
                created_at=task.created_at,
                updated_at=datetime.now().isoformat(),
                object_key=task.object_key,
                result=result)

        if isinstance(result, CompletedInferenceResult):
            result_images = {
                "cropped_image": result.cropped_image,
                "mask": result.mask,
            }

            uploaded_urls = self.upload_images(result_images)

            completed_result = CompletedResult(
                status="completed",
                result=result.result,
                probability_malign=result.probability_malign,
                probability_benign=result.probability_benign,
                cropped_image_url=uploaded_urls["cropped_image"],
                mask_url=uploaded_urls["mask"])

            response = TaskResult(
                task_id=task.task_id,
                status="completed",
                created_at=task.created_at,
                updated_at=datetime.now().isoformat(),
                object_key=task.object_key,
                result=completed_result)

            return response

        
        # if isinstance(result, CompletedInferenceResult):


        

# class Instance:
#
#     def __init__(self):
#         self.__nevoscan = Nevoscan()
#         self.task_id = None
#         self.__s3 = S3()
#
#     async def p(self, task: TaskResponse):
#         self.task_id = task.task_id
#         image_bytes = await self.downloal_image(task.object_key)
#         return await self.process_image(image_bytes)
#
#     async def process_image(self, image_data):
#
#         result = self.__nevoscan.predict(image_data)
#
#         # Обработка результата из Nevoscan.predict
#         if isinstance(result, dict):
#             if result.get("status") == "no_object":
#                 return {
#                     "status": "no_object",
#                     "message": result.get("message", "Родинка не обнаружена"),
#                 }
#             if result.get("status") == "error":
#                 logging.error(f"Ошибка: {result.get('message')}")
#                 raise ValueError(result.get("message", "Ошибка обработки изображения"))
#             if "error" in result:
#                 logging.error(f"Ошибка: {result['error']}")
#                 raise ValueError(result["error"])
#             else:
#
#                 result_images = {
#                     "cropped_image": result["cropped_image"],
#                     "hair_removed_rgb_image": result["hair_removed_rgb_image"],
#                     "mask": result["mask"],
#                 }
#                 uploaded_urls = await self.upload_images(result_images)
#
#                 return TaskResult(
#                     status=result.get("status"),
#                     result=result.get("result"),
#                     probability_malign=result.get("probability_malign"),
#                     probability_benign=result.get("probability_benign"),
#                     cropped_image_url=uploaded_urls.get("cropped_image"),
#                     hair_removed_rgb_image_url=uploaded_urls.get("hair_removed_rgb_image"),
#                     mask_url=uploaded_urls.get("mask"),
#                 )
#         else:
#             logging.error(f"Неожиданный формат результата: {result}")
#             raise ValueError("Неожиданный формат результата от Nevoscan")
#
#     async def downloal_image(self, object_key):
#         try:
#             image_bytes = self.__s3.get_object(object_key)
#             logging.info(f"Скачан {object_key}")
#             return image_bytes
#
#         except ClientError as e:
#             logging.error(f"{e}")
#             raise HTTPException(status_code=500, detail=f"Ошибка MinIO: {str(e)}")
#         except Exception as e:
#             logging.error(f"{e}")
#             raise HTTPException(status_code=500, detail=f"Ошибка: {str(e)}")
#
#     async def upload_image(self, image, type):
#         try:
#             if not isinstance(image, np.ndarray):
#                 raise ValueError("Ожидается numpy.ndarray для загрузки изображения")
#
#             image_to_save = image
#             # Для масок и float-данных приводим к диапазону 0..255.
#
#             if image_to_save.max() <= 1:
#                 image_to_save = (image_to_save * 255).astype(np.uint8)
#             elif image_to_save.dtype != np.uint8:
#                 image_to_save = np.clip(image_to_save, 0, 255).astype(np.uint8)
#
#             success, encoded_image = cv2.imencode(".png", image_to_save)
#             if not success:
#                 raise ValueError("Не удалось закодировать изображение в PNG")
#
#             object_key = f"{self.task_id}_{type}.png"
#             filename = object_key
#             content_type = "image/png"
#
#             # Загрузка в s3
#             file_url = await self.__s3.put_object(encoded_image, object_key)
#
#             # Генерируем URL для доступа к файлу
#             presigned_url = self.__s3.generate_presigned_url(object_key)
#
#             return {
#                 "filename": filename,
#                 "object_key": object_key,
#                 "content_type": content_type,
#                 "message": "Файл успешно загружен",
#                 "url": presigned_url
#             }
#
#         except ClientError as e:
#             logging.error(f"{e}")
#             raise HTTPException(status_code=500, detail=f"Ошибка MinIO: {str(e)}")
#         except Exception as e:
#             logging.error(f"{e}")
#             raise HTTPException(status_code=500, detail=f"Ошибка: {str(e)}")
#
#     async def upload_images(self, images):
#         presigned_urls = {}
#         for key in images.keys():
#             result = await self.upload_image(images[key], key)
#             presigned_urls[key] = result['url']
#         return presigned_urls
