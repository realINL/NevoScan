FROM python:3.10-slim

WORKDIR /code

COPY Gateway/requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir -r /code/requirements.txt

COPY Gateway/app /code/app
# Корневой env.test (коммитится в репозиторий) — не зависим от локального .env для сборки образа.
COPY env.test /code/.env

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--log-level", "info"]
