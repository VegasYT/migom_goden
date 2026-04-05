import json
import logging
from typing import Any

from aiokafka import AIOKafkaProducer

from app.config import settings

logger = logging.getLogger(__name__)

# Глобальный producer, инициализируется в lifespan
producer: AIOKafkaProducer | None = None


async def start_producer() -> None:
    global producer
    try:
        producer = AIOKafkaProducer(
            bootstrap_servers=settings.kafka_bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )
        await producer.start()
        logger.warning("Kafka producer запущен на %s", settings.kafka_bootstrap_servers)
    except Exception as exc:
        logger.error("Не удалось запустить Kafka producer: %s", exc)
        producer = None


async def stop_producer() -> None:
    global producer
    if producer:
        await producer.stop()
        logger.info("Kafka producer остановлен")


async def publish_event(topic: str, payload: dict[str, Any]) -> None:
    """Публикует событие в Kafka-топик. Ошибки логируются, но не пробрасываются - не блокируем основной флоу."""
    if not producer:
        logger.warning("Kafka producer не инициализирован, событие не отправлено: %s", topic)
        return
    try:
        await producer.send_and_wait(topic, payload)
        logger.warning("Событие отправлено в топик '%s': %s", topic, payload)
    except Exception as exc:
        logger.error("Ошибка отправки события в Kafka топик '%s': %s", topic, exc)
