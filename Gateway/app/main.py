import os
import uuid
from botocore.exceptions import ClientError
from .broker import Broker
from .s3 import S3
from fastapi import FastAPI, UploadFile, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app.Schemas.schemas import LoadImageResponse, TaskResponse

app = FastAPI()
broker = Broker() 
s3 = S3()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://twa777.ru"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],  
)


@app.get("/")
async def root():
    return {"message": "MinIO File Uploader API"}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/load_image",
          response_model=LoadImageResponse,
          summary="Загрузка фото и начало анализа")
async def load_image(file: UploadFile):
    """
    Загрузка фото
    Валидация фото
    Загрузка фото в S3
    Создание и постановка задачи на анализ
    """
    valid_types = [
        'image/png',
        'image/jpeg',
        'image/jpg',
        'image/heic'
    ]
    # Валидация загруженного файла
    await validate_file(file, 5, valid_types)

   # Загрузка в S3
    try:

        # генерация filename
        file_ext = os.path.splitext(file.filename or "")[1]
        task_id = uuid.uuid4().hex
        object_key = f"{task_id}_original{file_ext}"
        
        # Загрузка в S3
        await s3.put_object(file, object_key)

        # Создание задачи и постановка в очередь
        try:
            broker.create_task(task_id, object_key)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Ошибка создания задачи: {str(e)}")

        return LoadImageResponse(task_id=task_id, status="pending")

    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Ошибка S3: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка: {str(e)}")


@app.get("/task/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str):
    try: 
        task = broker.get_task(task_id)
        return task
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка: {str(e)}")


def _detect_mime_by_signature(header: bytes) -> str | None:
    if header.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"

    if header.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"

    # HEIC/HEIF: ищем ftyp box в первых 50 байтах (с запасом)
    if len(header) >= 12:
        # Поиск сигнатуры ftyp
        for i in range(0, min(len(header) - 8, 32)):
            if header[i:i + 4] == b"ftyp":
                brand = header[i + 4:i + 8]
                heif_brands = {b"heic", b"heix", b"hevc", b"hevx", b"mif1", b"msf1"}
                if brand in heif_brands:
                    return "image/heic"
                break  # ftyp найден, но бренд не HEIC

    return None

async def validate_file(file: UploadFile, max_size: int = None, mime_types: list = None):
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Имя файла отсутствует",
        )

    # Read only a small header for signature-based MIME validation.
    file.file.seek(0)
    header = file.file.read(32)
    detected_mime = _detect_mime_by_signature(header)

    if mime_types and detected_mime not in mime_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Файл не является валидным изображением PNG, JPG, JPEG или HEIC",
        )

    if max_size is not None:
        file.file.seek(0, 2)
        file_size = file.file.tell()
        max_bytes = max_size * 1024 * 1024
        if file_size > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Размер файла превышает {max_size} MB",
            )

    # Reset pointer for subsequent upload reading.
    file.file.seek(0)
    return



