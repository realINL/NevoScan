import boto3
import os
import logging
from botocore.exceptions import ClientError
from fastapi import UploadFile
from app.core.config import Config as config

class S3Client:
    def __init__(self):
        self.S3_ENDPOINT = config.S3_ENDPOINT  
        self.S3_ACCESS_KEY = config.S3_ACCESS_KEY
        self.S3_SECRET_KEY = config.S3_SECRET_KEY
        self.S3_BUCKET = config.S3_BUCKET  
        self.S3_SECURE = False  
        self.S3_REGION = config.S3_REGION

        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.S3_ENDPOINT,
            aws_access_key_id=self.S3_ACCESS_KEY,
            aws_secret_access_key=self.S3_SECRET_KEY,
            region_name=self.S3_REGION
        )
            
        self.s3_resource = boto3.resource(
            's3',
            endpoint_url=self.S3_ENDPOINT,
            aws_access_key_id=self.S3_ACCESS_KEY,
            aws_secret_access_key=self.S3_SECRET_KEY,
            region_name=self.S3_REGION
        )

        try:
            self.s3_client.head_bucket(Bucket=self.S3_BUCKET)
            logging.info(f"Bucket '{self.S3_BUCKET}' уже существует")
        except ClientError:
            logging.info(f"Bucket '{self.S3_BUCKET}' не существует")
            self.s3_client.create_bucket(Bucket=self.S3_BUCKET)
            logging.info(f"Bucket '{self.S3_BUCKET}' создан")

            
    def __get_object(self, bucket_name, object_key):
        return self.s3_client.get_object(Bucket=bucket_name, Key=object_key)
    
    async def __put_object(self, file: UploadFile, object_key: str):
        file_content = await file.read()
        self.s3_client.put_object(Bucket=self.S3_BUCKET, Key=object_key, Body=file_content, ContentType=file.content_type)
        return f'http://{self.S3_ENDPOINT}/{self.S3_BUCKET}/{object_key}'
    
    def __generate_presigned_url(self, object_key, expires_in=3600):
        presigned_url = self.s3_client.generate_presigned_url(
            'get_object', 
            Params={'Bucket': self.S3_BUCKET, 'Key': object_key}, 
            ExpiresIn=expires_in)
            
        logging.info(f"Presigned URL generated: {presigned_url}")
        return presigned_url

    def __delete_object(self, bucket_name, object_key):
        return self.s3_client.delete_object(Bucket=bucket_name, Key=object_key)
    def __list_objects(self, bucket_name):
        return self.s3_client.list_objects(Bucket=bucket_name)
    def __list_objects_v2(self, bucket_name):
        return self.s3_client.list_objects_v2(Bucket=bucket_name)
    def __get_object_url(self, bucket_name, object_key):
        return f'http://{self.S3_ENDPOINT}/{bucket_name}/{object_key}'

    async def upload_file(self, file: UploadFile, task_id: str):
        file_ext = os.path.splitext(file.filename or "")[1]
        object_key = f"{task_id}_original{file_ext}"
        try:
            await self.__put_object(file, object_key)
        except Exception as e:
            return None
        return object_key