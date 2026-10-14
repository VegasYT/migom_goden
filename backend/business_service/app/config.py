from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # Приложение
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # БД
    db_host: str
    db_port: int = 5432
    db_name: str
    db_user: str
    db_password: str

    # Redis
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_password: str = ""

    # Keycloak (realm goden): адрес realm для запросов сервиса и издатель, записанный в токенах.
    # Из контейнера Keycloak доступен по другому адресу, чем тот, что стоит в токене.
    keycloak_realm_url: str
    keycloak_issuer: str
    keycloak_audience: str = "migom-api"
    keycloak_client_id: str = "migom-backend"
    keycloak_client_secret: str

    # MinIO
    minio_endpoint: str
    minio_access_key: str
    minio_secret_key: str
    minio_bucket: str = "migom-media"
    minio_use_ssl: bool = False
    # Публичный хост для генерации URL файлов (то что видит браузер)
    minio_public_endpoint: str = ""

    @property
    def db_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def redis_url(self) -> str:
        if self.redis_password:
            return f"redis://:{self.redis_password}@{self.redis_host}:{self.redis_port}/0"
        return f"redis://{self.redis_host}:{self.redis_port}/0"


settings = Settings()
