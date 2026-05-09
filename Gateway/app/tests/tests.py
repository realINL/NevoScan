import pytest
import pytest_asyncio
from fastapi import UploadFile
from app.main import validate_file
from io import BytesIO


# def test_validate_file():
#     with open("test_png.png", "rb") as f:
#         file = UploadFile(filename="test_png.png", file=BytesIO(f.read()))
#     result = validate_file(file)
#     assert result is None



