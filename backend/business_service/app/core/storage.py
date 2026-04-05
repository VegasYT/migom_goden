import json
import uuid
from io import BytesIO

from minio import Minio
from minio.error import S3Error

from app.config import settings

_client: Minio | None = None


def get_minio() -> Minio:
    global _client
    if _client is None:
        _client = Minio(
            settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_use_ssl,
        )
        _ensure_bucket(_client)
    return _client


def _ensure_bucket(client: Minio) -> None:
    if not client.bucket_exists(settings.minio_bucket):
        client.make_bucket(settings.minio_bucket)

    # Публичная политика на чтение объектов бакета
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": ["*"]},
                "Action": ["s3:GetObject"],
                "Resource": [f"arn:aws:s3:::{settings.minio_bucket}/*"],
            }
        ],
    }
    client.set_bucket_policy(settings.minio_bucket, json.dumps(policy))


async def upload_photo(data: bytes, content_type: str, prefix: str = "items") -> str:
    """Загружает файл в MinIO, возвращает публичный URL."""
    client = get_minio()
    ext = content_type.split("/")[-1]
    object_name = f"{prefix}/{uuid.uuid4()}.{ext}"

    client.put_object(
        bucket_name=settings.minio_bucket,
        object_name=object_name,
        data=BytesIO(data),
        length=len(data),
        content_type=content_type,
    )

    # Используем публичный endpoint если задан, иначе внутренний
    public_host = settings.minio_public_endpoint or settings.minio_endpoint
    scheme = "https" if settings.minio_use_ssl else "http"
    return f"{scheme}://{public_host}/{settings.minio_bucket}/{object_name}"


async def delete_photo(photo_url: str) -> None:
    """Удаляет файл из MinIO по полному URL."""
    try:
        client = get_minio()
        prefix = f"/{settings.minio_bucket}/"
        idx = photo_url.find(prefix)
        if idx == -1:
            return
        object_name = photo_url[idx + len(prefix):]
        client.remove_object(settings.minio_bucket, object_name)
    except S3Error:
        pass
