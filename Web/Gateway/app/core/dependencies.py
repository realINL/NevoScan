from fastapi import Request
from app.services.task_service import TaskService

def get_task_service(request: Request) -> TaskService:
    return request.app.state.task_service