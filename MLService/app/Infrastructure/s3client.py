import boto3
import logging
from botocore.exceptions import ClientError
from app.Config.config import Config as s3config

class S3client:
    def __init__(self):
        self.MINIO_ENDPOINT = s3config.MINIO_ENDPOINT
        self.MINIO_ACCESS_KEY = s3config.MINIO_ACCESS_KEY
        self.MINIO_SECRET_KEY = s3config.MINIO_SECRET_KEY
        self.MINIO_BUCKET = s3config.MINIO_BUCKET
        self.MINIO_SECURE = s3config.MINIO_SECURE
        self.MINIO_REGION = s3config.MINIO_REGION

        required_config = {
            "MINIO_URL": self.MINIO_ENDPOINT,
            "MINIO_ROOT_USER": self.MINIO_ACCESS_KEY,
            "MINIO_ROOT_PASSWORD": self.MINIO_SECRET_KEY,
            "MINIO_BUCKET_NAME": self.MINIO_BUCKET,
        }
        missing = [key for key, value in required_config.items() if not value]
        if missing:
            raise ValueError(f"Отсутствуют обязательные переменные окружения MinIO: {', '.join(missing)}")

        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.MINIO_ENDPOINT,
            aws_access_key_id=self.MINIO_ACCESS_KEY,
            aws_secret_access_key=self.MINIO_SECRET_KEY,
            region_name=self.MINIO_REGION
        )

        try:
            self.s3_client.head_bucket(Bucket=self.MINIO_BUCKET)
            logging.info(f"Bucket '{self.MINIO_BUCKET}' уже существует")
        except ClientError:
            logging.info(f"Bucket '{self.MINIO_BUCKET}' не существует")
            self.s3_client.create_bucket(Bucket=self.MINIO_BUCKET)
            logging.info(f"Bucket '{self.MINIO_BUCKET}' создан")

            
    def get_object(self, object_key):
        response = self.s3_client.get_object(Bucket=self.MINIO_BUCKET, Key=object_key)
        return response["Body"].read()
        
    
    def put_object(self, file, object_key: str, content_type: str = "application/octet-stream"):
        if hasattr(file, "read"):
            file_content = file.read()
        elif hasattr(file, "tobytes"):
            file_content = file.tobytes()
        else:
            file_content = file

        if not isinstance(file_content, (bytes, bytearray)):
            raise ValueError("put_object ожидает bytes/bytearray, file-like объект или numpy массив")

        detected_content_type = getattr(file, "content_type", content_type)
        self.s3_client.put_object(
            Bucket=self.MINIO_BUCKET,
            Key=object_key,
            Body=file_content,
            ContentType=detected_content_type,
        )
        return f'http://{self.MINIO_ENDPOINT}/{self.MINIO_BUCKET}/{object_key}'
    
    def generate_presigned_url(self, object_key, expires_in=3600):
        presigned_url = self.s3_client.generate_presigned_url(
            'get_object', 
            Params={'Bucket': self.MINIO_BUCKET, 'Key': object_key}, 
            ExpiresIn=expires_in)
            
        logging.info(f"Presigned URL generated: {presigned_url}")
        return presigned_url
        
    def delete_object(self, bucket_name, object_key):
        return self.s3_client.delete_object(Bucket=bucket_name, Key=object_key)
    def list_objects(self, bucket_name):
        return self.s3_client.list_objects(Bucket=bucket_name)
    def list_objects_v2(self, bucket_name):
        return self.s3_client.list_objects_v2(Bucket=bucket_name)
    def get_object_url(self, bucket_name, object_key):
        return f'http://{self.MINIO_ENDPOINT}/{bucket_name}/{object_key}'