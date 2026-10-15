from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # Приложение
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8001

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

    # Kafka
    kafka_bootstrap_servers: str = "localhost:9092"

    # Keycloak (realm goden): адрес realm для запросов сервиса и издатель, записанный в токенах
    keycloak_realm_url: str
    keycloak_issuer: str
    keycloak_audience: str = "migom-api"

    # API Goden (с /api/v1) и сервисная учётная запись Мигома в нём: заказы на кухню точки Goden
    goden_api_url: str
    goden_client_id: str = "migom-integration"
    goden_client_secret: str

    # максимальное расстояние от точки до адреса доставки, км
    delivery_radius_km: float = 8

    @property
    def db_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def redis_url(self) -> str:
        if self.redis_password:
            return f"redis://:{self.redis_password}@{self.redis_host}:{self.redis_port}/1"
        return f"redis://{self.redis_host}:{self.redis_port}/1"


settings = Settings()
