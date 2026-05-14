from pathlib import Path
from dotenv import load_dotenv
import os

ROOT_DIR = Path(__file__).parent.parent.parent
ENV_FILE = ROOT_DIR / '.env'
 
if ENV_FILE.exists():
    load_dotenv(dotenv_path=ENV_FILE)
    print(f"Загружен .env из {ENV_FILE}")  
else:
    print(f"Файл .env не найден в {ENV_FILE}")

class Config:
    # S3
    S3_ENDPOINT = os.getenv('S3_URL')  
    S3_ACCESS_KEY = os.getenv('S3_ROOT_USER')
    S3_SECRET_KEY = os.getenv('S3_ROOT_PASSWORD')
    S3_BUCKET = os.getenv('S3_BUCKET_NAME')  
    S3_SECURE = True  
    S3_REGION = os.getenv('S3_REGION')

    # Redis
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
    REDIS_DB = int(os.getenv("REDIS_DB", "0"))
    REDIS_USERNAME = os.getenv("REDIS_USERNAME", "admin")
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "admin123")
    REDIS_USER_PASSWORD = os.getenv("REDIS_USER_PASSWORD", REDIS_PASSWORD)
    REDIS_QUEUE_NAME = os.getenv("REDIS_QUEUE_NAME", "ml:queue") 
    REDIS_TASK_TTL = int(os.getenv("REDIS_TASK_TTL", "600"))

    # File upload limit
    MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", "1024000")) # 1MB

    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE = os.getenv("LOG_FILE", str(ROOT_DIR / "logs" / "gateway.log"))