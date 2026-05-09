"""Тесты S3client: boto3 подменяется, конфиг MinIO — через patch модуля s3config."""
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from app.Infrastructure.s3client import S3client


def _valid_s3_config() -> SimpleNamespace:
    return SimpleNamespace(
        MINIO_ENDPOINT="localhost:9000",
        MINIO_ACCESS_KEY="access",
        MINIO_SECRET_KEY="secret",
        MINIO_BUCKET="test-bucket",
        MINIO_SECURE=False,
        MINIO_REGION="us-east-1",
    )


@pytest.fixture
def mock_boto_client() -> MagicMock:
    return MagicMock()


@patch("app.Infrastructure.s3client.boto3.client")
def test_init_raises_when_required_config_missing(mock_boto: MagicMock) -> None:
    """Пустые обязательные поля конфига → ValueError до вызова boto3."""
    cfg = SimpleNamespace(
        MINIO_ENDPOINT="",
        MINIO_ACCESS_KEY="x",
        MINIO_SECRET_KEY="y",
        MINIO_BUCKET="z",
        MINIO_SECURE=False,
        MINIO_REGION="us-east-1",
    )
    with patch("app.Infrastructure.s3client.s3config", cfg):
        with pytest.raises(ValueError, match="MINIO_URL"):
            S3client()
    mock_boto.assert_not_called()


@patch("app.Infrastructure.s3client.boto3.client")
def test_init_head_bucket_ok_no_create(mock_boto: MagicMock) -> None:
    """Бакет есть: create_bucket не вызывается."""
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        S3client()

    mock_s3.head_bucket.assert_called_once_with(Bucket="test-bucket")
    mock_s3.create_bucket.assert_not_called()


@patch("app.Infrastructure.s3client.boto3.client")
def test_init_creates_bucket_on_head_client_error(mock_boto: MagicMock) -> None:
    """head_bucket падает — создаём бакет (как в __init__)."""
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.side_effect = ClientError(
        {"Error": {"Code": "404", "Message": "Not Found"}}, "HeadBucket"
    )

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        S3client()

    mock_s3.create_bucket.assert_called_once_with(Bucket="test-bucket")


@patch("app.Infrastructure.s3client.boto3.client")
def test_get_object_returns_body_bytes(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}
    body = MagicMock()
    body.read.return_value = b"payload"
    mock_s3.get_object.return_value = {"Body": body}

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        data = client.get_object("path/to/key.bin")

    assert data == b"payload"
    mock_s3.get_object.assert_called_once_with(
        Bucket="test-bucket", Key="path/to/key.bin"
    )


@patch("app.Infrastructure.s3client.boto3.client")
def test_put_object_accepts_bytes(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        url = client.put_object(b"data", "k.bin", content_type="application/octet-stream")

    mock_s3.put_object.assert_called_once_with(
        Bucket="test-bucket",
        Key="k.bin",
        Body=b"data",
        ContentType="application/octet-stream",
    )
    assert url == "http://localhost:9000/test-bucket/k.bin"


@patch("app.Infrastructure.s3client.boto3.client")
def test_put_object_file_like_and_content_type_from_attr(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}

    buf = BytesIO(b"abc")
    buf.content_type = "image/png"  # type: ignore[attr-defined]

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        client.put_object(buf, "out.png")

    mock_s3.put_object.assert_called_once_with(
        Bucket="test-bucket",
        Key="out.png",
        Body=b"abc",
        ContentType="image/png",
    )


@patch("app.Infrastructure.s3client.boto3.client")
def test_put_object_numpy_like_tobytes(mock_boto: MagicMock) -> None:
    """Объект с tobytes() (как ndarray) без read()."""
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}

    class ArrLike:
        def tobytes(self) -> bytes:
            return b"\x00\xff"

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        client.put_object(ArrLike(), "mask.bin", content_type="application/octet-stream")

    mock_s3.put_object.assert_called_once_with(
        Bucket="test-bucket",
        Key="mask.bin",
        Body=b"\x00\xff",
        ContentType="application/octet-stream",
    )


@patch("app.Infrastructure.s3client.boto3.client")
def test_put_object_rejects_non_bytes_content(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        with pytest.raises(ValueError, match="put_object ожидает"):
            client.put_object(12345, "bad.bin")


@patch("app.Infrastructure.s3client.boto3.client")
def test_generate_presigned_url_delegates_to_client(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}
    mock_s3.generate_presigned_url.return_value = "https://signed-url"

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        out = client.generate_presigned_url("key.jpg", expires_in=7200)

    assert out == "https://signed-url"
    mock_s3.generate_presigned_url.assert_called_once_with(
        "get_object",
        Params={"Bucket": "test-bucket", "Key": "key.jpg"},
        ExpiresIn=7200,
    )


@patch("app.Infrastructure.s3client.boto3.client")
def test_delete_list_get_object_url_wrappers(mock_boto: MagicMock) -> None:
    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3
    mock_s3.head_bucket.return_value = {}
    mock_s3.delete_object.return_value = {"ResponseMetadata": {}}
    mock_s3.list_objects.return_value = {"Contents": []}
    mock_s3.list_objects_v2.return_value = {"KeyCount": 0}

    with patch("app.Infrastructure.s3client.s3config", _valid_s3_config()):
        client = S3client()
        assert client.delete_object("other-bucket", "k") == {"ResponseMetadata": {}}
        assert client.list_objects("b1") == {"Contents": []}
        assert client.list_objects_v2("b2") == {"KeyCount": 0}
        assert (
            client.get_object_url("my-bucket", "obj.txt")
            == "http://localhost:9000/my-bucket/obj.txt"
        )

    mock_s3.delete_object.assert_called_once_with(Bucket="other-bucket", Key="k")
    mock_s3.list_objects.assert_called_once_with(Bucket="b1")
    mock_s3.list_objects_v2.assert_called_once_with(Bucket="b2")