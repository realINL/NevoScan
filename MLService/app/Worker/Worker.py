# app/worker/worker.py
import logging

from app.Infrastructure.RedisProducer import RedisProducer
from app.Infrastructure.RedisConsumer import RedisConsumer
from app.Service.InferenceService import InferenceService


class Worker:
    def __init__(self, consumer, producer, service):
        self.consumer = consumer
        self.producer = producer
        self.service = service

    def run(self):
        while True:
            task = self.consumer.pop()
            try:
                result = self.service.process_task(task)
                self.producer.push(result)
            except Exception as e:
                logging.error(msg=f"Task filed {e}")
