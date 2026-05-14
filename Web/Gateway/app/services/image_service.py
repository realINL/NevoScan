from fastapi import UploadFile, HTTPException, status
from app.core.config import Config
from app.infrastructure.prometheus import PrometheusMetrics
from app.core.exceptions import FileError

class ImageService:

    valid_types = [
        'image/png',
        'image/jpeg',
        'image/jpg',
        'image/heic'
    ]

    max_size = Config.MAX_FILE_SIZE
    
    @staticmethod
    def _detect_mime_by_signature(header: bytes) -> str | None:
        if header.startswith(b"\x89PNG\r\n\x1a\n"):
            return "image/png"

        if header.startswith(b"\xff\xd8\xff"):
            return "image/jpeg"

        # HEIC/HEIF
        if len(header) >= 12:
            # Поиск сигнатуры ftyp
            for i in range(0, min(len(header) - 8, 32)):
                if header[i:i + 4] == b"ftyp":
                    brand = header[i + 4:i + 8]
                    heif_brands = {b"heic", b"heix", b"hevc", b"hevx", b"mif1", b"msf1"}
                    if brand in heif_brands:
                        return "image/heic"
                    break 

        return None
    @staticmethod
    async def validate_file(file: UploadFile):
        if not file.filename:
            raise FileError("Имя файла отсутствует")

        file.file.seek(0)
        header = file.file.read(32)
        detected_mime = ImageService._detect_mime_by_signature(header)

        if detected_mime not in ImageService.valid_types:
            raise FileError("Файл не является валидным изображением PNG, JPG, JPEG или HEIC")

        if ImageService.max_size is not None:
            file.file.seek(0, 2)
            file_size = file.file.tell()
            PrometheusMetrics.GATEWAY_UPLOAD_SIZE.observe(file_size)
            max_bytes = ImageService.max_size * 1024 * 1024
            if file_size > max_bytes:
                raise FileError(f"Размер файла превышает {ImageService.max_size} MB")


        file.file.seek(0)
        return
    
    