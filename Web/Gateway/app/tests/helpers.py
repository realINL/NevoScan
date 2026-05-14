from io import BytesIO

from fastapi import UploadFile


PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 24
JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 28
HEIC_BYTES = b"\x00" * 4 + b"ftypheic" + b"\x00" * 20
PDF_BYTES = b"%PDF-1.4" + b"\x00" * 24


def make_upload_file(content: bytes, filename: str = "test.png") -> UploadFile:
    return UploadFile(filename=filename, file=BytesIO(content))
