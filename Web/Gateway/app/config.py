from pathlib import Path
from dotenv import load_dotenv
import os

ROOT_DIR = Path(__file__).parent.parent
ENV_FILE = ROOT_DIR / '.env'
 
if ENV_FILE.exists():
    load_dotenv(dotenv_path=ENV_FILE)
    print(f"Загружен .env из {ENV_FILE}")  
else:
    print(f"Файл .env не найден в {ENV_FILE}")

class Config:
    # Minio
    MINIO_ENDPOINT = os.getenv('MINIO_URL')  
    MINIO_ACCESS_KEY = os.getenv('MINIO_ROOT_USER')
    MINIO_SECRET_KEY = os.getenv('MINIO_ROOT_PASSWORD')
    MINIO_BUCKET = os.getenv('MINIO_BUCKET_NAME')  
    MINIO_SECURE = True  
    MINIO_REGION = os.getenv('MINIO_REGION')

    # Redis
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
    REDIS_DB = int(os.getenv("REDIS_DB", "0"))
    REDIS_USERNAME = os.getenv("REDIS_USERNAME", "admin")
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "admin123")
    REDIS_QUEUE_NAME = os.getenv("REDIS_QUEUE_NAME", "ml:queue") 