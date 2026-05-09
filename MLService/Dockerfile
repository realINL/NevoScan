# syntax=docker/dockerfile:1.7
FROM python:3.10-slim

WORKDIR /code

ENV PYTHONUNBUFFERED=1 \
    TORCH_HOME=/opt/torch-cache

RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

COPY MLService/requirements.txt /code/requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    --verbose --use-pep517 \
    -r /code/requirements.txt

COPY MLService/app /code/app
COPY MLService/tests /code/tests
COPY env.test /code/.env


RUN python -c "from torchvision import models; \
models.resnet50(weights=models.ResNet50_Weights.DEFAULT); \
models.segmentation.deeplabv3_resnet101(weights=models.segmentation.DeepLabV3_ResNet101_Weights.DEFAULT)"

CMD ["python", "-m", "app.main"]
