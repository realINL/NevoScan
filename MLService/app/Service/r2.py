import os
import sys
import redis


REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6380"))
REDIS_DB = int(os.getenv("REDIS_DB", "0"))
REDIS_USERNAME = os.getenv("REDIS_USERNAME", "admin")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "admin123")
REDIS_QUEUE_NAME = os.getenv("REDIS_QUEUE_NAME", "ml:queue")


def main() -> None:
    client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        db=REDIS_DB,
        username=REDIS_USERNAME,
        password=REDIS_PASSWORD,
        decode_responses=True,
    )

    try:
        client.ping()
        print(f"Подключение к Redis успешно. Очередь: '{REDIS_QUEUE_NAME}'")

        # Если переданы аргументы: отправляем их как одно сообщение и выходим.
        if len(sys.argv) > 1:
            message = " ".join(sys.argv[1:])
            queue_size = client.rpush(REDIS_QUEUE_NAME, message)
            print(f"Задача добавлена в очередь: {message}")
            print(f"Текущий размер очереди: {queue_size}")
            return

        # Иначе запускаем интерактивный режим отправки задач.
        print("Введите задачу и нажмите Enter (exit для выхода):")
        while True:
            message = input("> ").strip()
            if not message:
                continue
            if message.lower() in {"exit", "quit"}:
                print("Остановка producer.")
                break

            queue_size = client.rpush(REDIS_QUEUE_NAME, message)
            print(f"Задача добавлена. Размер очереди: {queue_size}")
    except KeyboardInterrupt:
        print("\nОстановка producer по Ctrl+C")
    except redis.exceptions.RedisError as error:
        print(f"Ошибка Redis: {error}")


if __name__ == "__main__":
    main()