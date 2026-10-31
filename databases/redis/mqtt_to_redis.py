"""Recebe a temperatura do simulador Wokwi via MQTT e a registra no Redis."""

from __future__ import annotations

import json
import logging
import os
from datetime import UTC, datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from urllib.parse import urlparse
from uuid import uuid4

import paho.mqtt.client as mqtt
import redis
from dotenv import load_dotenv


# O coletor sempre usa a configuração do diretório Redis, independentemente
# da pasta em que o comando Python foi executado.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
# O worker usa o .env da raiz do projeto. O coletor usa a mesma configuração
# e permite que o .env local complete apenas opções MQTT ausentes.
load_dotenv(PROJECT_ROOT / ".env")
load_dotenv(Path(__file__).with_name(".env"), override=False)

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
LOGGER = logging.getLogger("skadi.mqtt_to_redis")

MQTT_BROKER = os.getenv("MQTT_BROKER", "broker.mqttdashboard.com")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "camara-fria/temperatura")
MQTT_CLIENT_ID = os.getenv("MQTT_CLIENT_ID", f"skadi-r-{uuid4().hex[:12]}")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
TEMPERATURE_KEY = os.getenv("REDIS_TEMPERATURE_KEY", "skadi:temperatura:atual")
TEMPERATURE_STREAM = os.getenv(
    "REDIS_TEMPERATURE_STREAM", "skadi:leituras:temperatura"
)
THERMOMETER_ID = os.getenv("THERMOMETER_ID", "1")


def connection_url(redis_url: str) -> str:
    """Ativa TLS nos endpoints Upstash informados no formato redis://."""

    parsed = urlparse(redis_url)
    if parsed.scheme == "redis" and (parsed.hostname or "").endswith(".upstash.io"):
        return f"rediss://{redis_url.split('://', 1)[1]}"
    return redis_url


redis_client = redis.Redis.from_url(connection_url(REDIS_URL), decode_responses=True)


def parse_reading(payload: bytes) -> tuple[Decimal, str]:
    """Extrai temperatura e termômetro da mensagem MQTT JSON."""

    try:
        data = json.loads(payload.decode("utf-8"))
        temperature = Decimal(str(data["temp"]))
        thermometer_id = str(data.get("cod_termometro", THERMOMETER_ID))
        if int(thermometer_id) <= 0:
            raise ValueError("termômetro inválido")
    except (
        UnicodeDecodeError,
        json.JSONDecodeError,
        KeyError,
        InvalidOperation,
        TypeError,
        ValueError,
    ) as exc:
        raise ValueError("mensagem MQTT sem leitura válida") from exc

    if not temperature.is_finite():
        raise ValueError("temperatura inválida")
    return temperature, thermometer_id


def on_connect(client: mqtt.Client, _userdata, _flags, reason_code, _properties) -> None:
    if reason_code != 0:
        LOGGER.error("Conexão MQTT recusada: %s", reason_code)
        return
    client.subscribe(MQTT_TOPIC, qos=1)
    LOGGER.info("Assinando o tópico MQTT %s", MQTT_TOPIC)


def on_disconnect(
    _client: mqtt.Client,
    _userdata,
    _disconnect_flags,
    reason_code,
    _properties,
) -> None:
    LOGGER.warning("MQTT desconectado: %s", reason_code)


def on_message(_client: mqtt.Client, _userdata, message: mqtt.MQTTMessage) -> bool:
    try:
        temperature, thermometer_id = parse_reading(message.payload)
    except ValueError:
        LOGGER.warning("Mensagem ignorada no tópico %s", message.topic, exc_info=True)
        return False

    measured_at = datetime.now(UTC).isoformat()
    fields = {
        # O worker usa este ID para tornar a inserção no PostgreSQL idempotente.
        "id_evento_redis": f"mqtt-{uuid4().hex}",
        "cod_termometro": thermometer_id,
        "temperatura": str(temperature),
        "data_hora": measured_at,
    }

    try:
        # A chave permite consultar imediatamente a leitura mais recente.
        # O Stream preserva o histórico e é compatível com o worker existente.
        pipe = redis_client.pipeline(transaction=True)
        pipe.set(TEMPERATURE_KEY, str(temperature))
        pipe.xadd(TEMPERATURE_STREAM, fields)
        _set_result, event_id = pipe.execute()
    except redis.RedisError:
        LOGGER.exception("Não foi possível gravar a temperatura no Redis")
        return False

    LOGGER.info(
        "Temperatura %s °C gravada em %s; evento %s no Stream %s",
        temperature,
        TEMPERATURE_KEY,
        event_id,
        TEMPERATURE_STREAM,
    )
    return True


def main() -> None:
    try:
        redis_client.ping()
    except redis.RedisError as exc:
        LOGGER.error("Não foi possível conectar ao Redis: %s", exc)
        raise SystemExit(1) from exc

    LOGGER.info("Redis conectado")
    client = mqtt.Client(
        mqtt.CallbackAPIVersion.VERSION2,
        client_id=MQTT_CLIENT_ID,
        protocol=mqtt.MQTTv311,
    )
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    client.reconnect_delay_set(min_delay=1, max_delay=30)
    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    client.loop_forever()


if __name__ == "__main__":
    main()
