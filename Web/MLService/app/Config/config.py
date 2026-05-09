from pathlib import Path
from dotenv import load_dotenv
import os
import yaml

ROOT_DIR = Path(__file__).parent.parent.parent
ENV_FILE = ROOT_DIR / '.env'
CONFIG_FILE = Path(__file__).parent / 'ml_config.yaml'
 
if ENV_FILE.exists():
    load_dotenv(dotenv_path=ENV_FILE)
    print(f"Загружен .env из {ENV_FILE}")  # Для отладки
else:
    print(f"Файл .env не найден в {ENV_FILE}")

if CONFIG_FILE.exists():
    with open(CONFIG_FILE) as f:
        MODELS_CONFIG = yaml.safe_load(f)
        print("Конфигурация моделей загружена")
else:
    print("Не удалось загрузить конфигурацию моделей")

class Config:
    # Minio
    MINIO_ENDPOINT = os.getenv('MINIO_URL')  
    MINIO_ACCESS_KEY = os.getenv('MINIO_ROOT_USER')
    MINIO_SECRET_KEY = os.getenv('MINIO_ROOT_PASSWORD')
    MINIO_BUCKET = os.getenv('MINIO_BUCKET_NAME')  
    MINIO_SECURE = False  
    MINIO_REGION = os.getenv('MINIO_REGION')

    # Redis
    REDIS_HOST = os.getenv("REDIS_HOST", "redis")
    REDIS_PORT = int(os.getenv("REDIS_PORT", "6380"))
    REDIS_DB = int(os.getenv("REDIS_DB", "0"))
    REDIS_USERNAME = os.getenv("REDIS_USERNAME", "admin")
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "admin123")
    REDIS_QUEUE_NAME = os.getenv("REDIS_QUEUE_NAME", "ml:queue")
    REDIS_GATEWAY_QUEUE_NAME = os.getenv("REDIS_GATEWAY_QUEUE_NAME", "gateway:queue")

    # Models
    YOLO_FILE=Path(os.getenv("YOLO_FILE"))
    DEEPLAB_FILE=Path(os.getenv("DEEPLAB_FILE"))
    RESNET_FILE=Path(os.getenv("RESNET_FILE"))

    # Models config
    YOLO_IOU = MODELS_CONFIG['detection_model']['iou']
    YOLO_CONF = MODELS_CONFIG['detection_model']['conf']
    YOLO_IMAGESIZE = MODELS_CONFIG['detection_model']['imgsz']
    RESNET_THRESHOLD = MODELS_CONFIG['classification_model']['threshold']

    DEVICE =  MODELS_CONFIG['device']['device']