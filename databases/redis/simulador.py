"""Simula uma leitura de temperatura para cada termômetro cadastrado no PostgreSQL."""

from __future__ import annotations

import json
import math
import os
import time
from pathlib import Path
from uuid import uuid4

import paho.mqtt.client as mqtt
import psycopg
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")
load_dotenv(Path(__file__).with_name(".env"), override=False)

MQTT_BROKER = os.getenv("MQTT_BROKER", "broker.mqttdashboard.com")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "camara-fria/temperatura")
READING_INTERVAL_SECONDS = float(os.getenv("READING_INTERVAL_SECONDS", "300"))


def thermometer_ids() -> list[int]:
    """Retorna somente termômetros vinculados a uma câmara frigorífica."""

    database_url = os.getenv("DATABASE_URL")
    if database_url:
        connection_factory = psycopg.connect(database_url)
    else:
        connection_factory = psycopg.connect(
            host=os.environ["POSTGRES_HOST"],
            port=int(os.getenv("POSTGRES_PORT", "16590")),
            dbname=os.environ["POSTGRES_DB"],
            user=os.environ["POSTGRES_USER"],
            password=os.environ["POSTGRES_PASSWORD"],
            sslmode=os.getenv("POSTGRES_SSLMODE", "require"),
        )

    with connection_factory as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT cod_termometro
                FROM tb_camara_frigorifica
                ORDER BY cod_termometro
                """
            )
            return [row[0] for row in cursor.fetchall()]


def simulated_temperature(thermometer_id: int, reading_number: int) -> float:
    """Gera uma curva entre -20 °C e -15 °C, distinta para cada termômetro."""

    return round(-17.5 + 2.5 * math.sin(reading_number * 0.7 + thermometer_id), 1)

client = mqtt.Client(
    mqtt.CallbackAPIVersion.VERSION2,
    client_id=f"skadi-sim-{uuid4().hex[:12]}",
)
client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
client.loop_start()

leitura = 0

try:
    while True:
        ids = thermometer_ids()
        if not ids:
            print("Nenhum termômetro associado a uma câmara foi encontrado.")

        for thermometer_id in ids:
            temperatura = simulated_temperature(thermometer_id, leitura)
            mensagem = json.dumps(
                {"temp": temperatura, "cod_termometro": thermometer_id}
            )
            client.publish(MQTT_TOPIC, mensagem)
            print(
                f"Termômetro {thermometer_id}: temperatura enviada: "
                f"{temperatura} °C"
            )

        leitura += 1
        time.sleep(READING_INTERVAL_SECONDS)

except KeyboardInterrupt:
    print("\nSimulador encerrado.")
finally:
    client.loop_stop()
    client.disconnect()
