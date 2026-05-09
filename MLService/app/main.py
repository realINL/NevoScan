import redis

from app.Infrastructure.RedisConsumer import RedisConsumer
from app.Infrastructure.RedisProducer import RedisProducer
from app.Infrastructure.s3client import S3client
from app.Service.InferenceService import InferenceService
from app.Nevoscan.Nevoscan import Nevoscan
from app.Worker.Worker import Worker


def main():

    processor = Nevoscan()

    consumer = RedisConsumer()
    producer = RedisProducer()
    s3 = S3client()

    service = InferenceService(processor, s3)

    worker = Worker(consumer, producer, service)

    worker.run()

if __name__ == "__main__":
    main()