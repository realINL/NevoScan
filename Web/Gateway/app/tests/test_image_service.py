import pytest
from fastapi import UploadFile

from app.core.exceptions import FileError
from app.services.image_service import ImageService
from app.tests.helpers import JPEG_BYTES, PNG_BYTES, HEIC_BYTES, PDF_BYTES, make_upload_file


class TestDetectMimeBySignature:
    @pytest.mark.parametrize(
        "header,expected",
        [
            (PNG_BYTES[:32], "image/png"),
            (JPEG_BYTES[:32], "image/jpeg"),
            (HEIC_BYTES[:32], "image/heic"),
            (PDF_BYTES[:32], None),
            (b"not-an-image", None),
        ],
    )
    def test_detect_mime(self, header: bytes, expected: str | None) -> None:
        assert ImageService._detect_mime_by_signature(header) == expected


class TestValidateFile:
    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "content,filename",
        [
            (PNG_BYTES, "photo.png"),
            (JPEG_BYTES, "photo.jpg"),
            (HEIC_BYTES, "photo.heic"),
        ],
    )
    async def test_valid_image(self, content: bytes, filename: str) -> None:
        file = make_upload_file(content, filename)
        await ImageService.validate_file(file)
        assert file.file.tell() == 0

    @pytest.mark.asyncio
    async def test_missing_filename(self) -> None:
        file = UploadFile(filename=None, file=make_upload_file(PNG_BYTES).file)
        with pytest.raises(FileError, match="Имя файла отсутствует"):
            await ImageService.validate_file(file)

    @pytest.mark.asyncio
    async def test_invalid_content(self) -> None:
        file = make_upload_file(PDF_BYTES, "document.pdf")
        with pytest.raises(FileError, match="не является валидным изображением"):
            await ImageService.validate_file(file)

    @pytest.mark.asyncio
    async def test_file_too_large(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(ImageService, "max_size", 0)
        file = make_upload_file(PNG_BYTES, "large.png")
        with pytest.raises(FileError, match="Размер файла превышает"):
            await ImageService.validate_file(file)
