FROM python:3.10-slim

WORKDIR /code

COPY Gateway/requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir -r /code/requirements.txt

COPY Gateway/app /code/app

COPY env.test /code/.env

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
