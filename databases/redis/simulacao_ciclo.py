"""Um lote de temperaturas: PostgreSQL → simulador → MQTT → coletor → Redis.

Execução finita para GitHub Actions. Não substitui o worker de alertas.
"""

from __future__ import annotations

import json
import math
import os
import threading
import time
from uuid import uuid4

import paho.mqtt.client as mqtt
import psycopg

import mqtt_to_redis as coletor


def main() -> None:
    # Uma única conexão PostgreSQL, fechada antes do processamento MQTT.
    with psycopg.connect(os.environ["SKADI_DATABASE_URL"], connect_timeout=15) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT cod_termometro FROM tb_camara_frigorifica ORDER BY cod_termometro")
            ids = [row[0] for row in cursor.fetchall()]
    if not ids:
        raise RuntimeError("Nenhum termômetro associado a uma câmara no banco configurado.")

    coletor.redis_client.ping()
    # Evita que coletores externos dupliquem o mesmo lote de teste.
    topico = f"{coletor.MQTT_TOPIC}/simulacao/{uuid4().hex}"
    pronto = threading.Event()
    concluido = threading.Event()
    recebidos: set[int] = set()
    erros: list[str] = []

    def conectado(client, _userdata, _flags, reason_code, _properties):
        if reason_code != 0:
            erros.append("Conexão MQTT recusada")
            pronto.set()
            return
        client.subscribe(topico, qos=1)

    def inscrito(_client, _userdata, _mid, reason_codes, _properties):
        if any(reason.is_failure for reason in reason_codes):
            erros.append("Inscrição MQTT recusada")
        pronto.set()

    def recebido(client, userdata, message):
        try:
            identificador = int(json.loads(message.payload)["cod_termometro"])
            if identificador in recebidos:
                return
            if not coletor.on_message(client, userdata, message):
                erros.append("Falha ao persistir leitura no Redis")
                concluido.set()
                return
            recebidos.add(identificador)
            if len(recebidos) == len(ids):
                concluido.set()
        except Exception:
            erros.append("Falha no processamento MQTT do lote")
            concluido.set()

    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2,
                         client_id=f"skadi-ci-{uuid4().hex[:12]}")
    client.on_connect = conectado
    client.on_subscribe = inscrito
    client.on_message = recebido
    client.connect(coletor.MQTT_BROKER, coletor.MQTT_PORT, keepalive=60)
    client.loop_start()
    try:
        if not pronto.wait(30) or erros:
            raise RuntimeError("Não foi possível preparar a assinatura MQTT do lote.")
        numero_leitura = int(time.time() // 300)
        for identificador in ids:
            temperatura = round(-17.5 + 2.5 * math.sin(numero_leitura * 0.7 + identificador), 1)
            mensagem = json.dumps({"temp": temperatura, "cod_termometro": identificador})
            entrega = client.publish(topico, mensagem, qos=1)
            entrega.wait_for_publish(timeout=15)
            if not entrega.is_published():
                raise RuntimeError("Publicação MQTT não confirmada.")
        if not concluido.wait(60) or erros or len(recebidos) != len(ids):
            raise RuntimeError(f"Lote incompleto: {len(recebidos)}/{len(ids)} leituras gravadas.")
        print(f"Lote concluído: {len(recebidos)} leituras gravadas no Redis.")
    finally:
        client.disconnect()
        client.loop_stop()
        coletor.redis_client.close()


if __name__ == "__main__":
    main()
