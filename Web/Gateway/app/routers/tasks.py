from fastapi import APIRouter, UploadFile, HTTPException, status, Depends
from app.schemas.schemas import LoadImageResponse, TaskResponse
from app.core.exceptions import FileError, TaskError
from app.core.dependencies import get_task_service

router = APIRouter()

@router.get("/")
async def root():
    return {"message": "MinIO File Uploader API"}

@router.get("/health")
async def health():
    return {"status": "ok"}

@router.post("/load_image",
          response_model=LoadImageResponse,
          summary="Загрузка фото и начало анализа")
async def load_image(file: UploadFile, task_service = Depends(get_task_service)):

    try: 
        return await task_service.create_task(file)
    except FileError as e:
        raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
        )
    except TaskError as e:
        raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Unknown errorr",
        )

@router.get("/task/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str, task_service = Depends(get_task_service)):
    try: 
        task = task_service.get_task(task_id)
        return task
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка: {str(e)}")