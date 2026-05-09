import boto3
from botocore.client import Config
import os
import logging
from botocore.exceptions import ClientError
from fastapi import UploadFile
from app.config import Config as config

class S3:
    def __init__(self):
        self.MINIO_ENDPOINT = config.MINIO_ENDPOINT  
        self.MINIO_ACCESS_KEY = config.MINIO_ACCESS_KEY
        self.MINIO_SECRET_KEY = config.MINIO_SECRET_KEY
        self.MINIO_BUCKET = config.MINIO_BUCKET  
        self.MINIO_SECURE = False  
        self.MINIO_REGION = config.MINIO_REGION

        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.MINIO_ENDPOINT,
            aws_access_key_id=self.MINIO_ACCESS_KEY,
            aws_secret_access_key=self.MINIO_SECRET_KEY,
            # config=Config(signature_version='s3v4'),
            region_name=self.MINIO_REGION
        )
            
        self.s3_resource = boto3.resource(
            's3',
            endpoint_url=self.MINIO_ENDPOINT,
            aws_access_key_id=self.MINIO_ACCESS_KEY,
            aws_secret_access_key=self.MINIO_SECRET_KEY,
            # config=Config(signature_version='s3v4'),
            region_name=self.MINIO_REGION
        )

        try:
            self.s3_client.head_bucket(Bucket=self.MINIO_BUCKET)
            logging.info(f"Bucket '{self.MINIO_BUCKET}' уже существует")
        except ClientError:
            logging.info(f"Bucket '{self.MINIO_BUCKET}' не существует")
            self.s3_client.create_bucket(Bucket=self.MINIO_BUCKET)
            logging.info(f"Bucket '{self.MINIO_BUCKET}' создан")

            
    def get_object(self, bucket_name, object_key):
        return self.s3_client.get_object(Bucket=bucket_name, Key=object_key)
    
    async def put_object(self, file: UploadFile, object_key: str):
        file_content = await file.read()
        self.s3_client.put_object(Bucket=self.MINIO_BUCKET, Key=object_key, Body=file_content, ContentType=file.content_type)
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