"""Worker Redis/PostgreSQL do monitoramento de temperatura do Skadi.

O worker orquestra fila, temporização e comunicação entre os bancos. As
regras de negócio continuam no PostgreSQL: inserir uma leitura anormal aciona
as triggers que criam o alerta, o atendimento e a notificação.
"""

from __future__ import annotations

import json
import logging
import os
import threading
import time
from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any
from zoneinfo import ZoneInfo

import psycopg
import redis
from dotenv import load_dotenv

load_dotenv()

LOGGER = logging.getLogger("skadi.redis_worker")
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

DATABASE_URL = os.environ["DATABASE_URL"]
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
WORKER_USER_ID = int(os.getenv("WORKER_USER_ID", "1"))
TEMPERATURE_STREAM = os.getenv(
    "REDIS_TEMPERATURE_STREAM", "skadi:leituras:temperatura"
)
TEMPERATURE_GROUP = os.getenv(
    "REDIS_TEMPERATURE_GROUP", "skadi-temperature-workers"
)
CONSUMER_NAME = os.getenv("REDIS_CONSUMER_NAME", "worker-1")
ESCALATION_ZSET = os.getenv("REDIS_ESCALATION_ZSET", "skadi:escalonamentos")
PUSH_STREAM = os.getenv("REDIS_PUSH_STREAM", "skadi:notificacoes:push")
POSTGRES_ALERT_CHANNEL = os.getenv("POSTGRES_ALERT_CHANNEL", "novo_alerta")
BLOCK_MS = int(os.getenv("WORKER_BLOCK_MS", "5000"))
BATCH_SIZE = int(os.getenv("WORKER_BATCH_SIZE", "100"))
SCHEDULER_POLL_SECONDS = float(os.getenv("SCHEDULER_POLL_SECONDS", "1"))


def parse_timestamp(value: Any) -> datetime:
    """Converte a data do evento para TIMESTAMP sem fuso do PostgreSQL."""

    if value is None or value == "":
        return datetime.now()

    parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(ZoneInfo("America/Sao_Paulo")).replace(
            tzinfo=None
        )
    return parsed


def parse_temperature(value: Any) -> Decimal:
    try:
        temperature = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError) as exc:
        raise ValueError("temperatura inválida") from exc

    if not temperature.is_finite():
        raise ValueError("temperatura inválida")
    return temperature


class PostgresRepository:
    def connect(self) -> psycopg.Connection:
        connection = psycopg.connect(DATABASE_URL)
        connection.autocommit = True
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT set_config('app.usuario_atual', %s, false)",
                (str(WORKER_USER_ID),),
            )
        return connection

    def camera_context(
        self, connection: psycopg.Connection, thermometer_id: int
    ) -> tuple[int, Decimal, Decimal, bool] | None:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    cam.id,
                    cam.temperatura_min,
                    cam.temperatura_max,
                    EXISTS (
                        SELECT 1
                        FROM tb_alerta a
                        WHERE a.cod_camara_frigorifica = cam.id
                          AND a.status IN ('ativo', 'reconhecido')
                    ) AS possui_alerta_aberto
                FROM tb_camara_frigorifica cam
                WHERE cam.cod_termometro = %s
                """,
                (thermometer_id,),
            )
            return cursor.fetchone()

    def persist_reading(
        self,
        connection: psycopg.Connection,
        event_id: str,
        thermometer_id: int,
        temperature: Decimal,
        measured_at: datetime,
    ) -> int | None:
        context = self.camera_context(connection, thermometer_id)
        if context is None:
            raise ValueError(
                f"termômetro {thermometer_id} não está associado a uma câmara"
            )

        _camera_id, minimum, maximum, has_open_alert = context
        outside_range = temperature < minimum or temperature > maximum

        # Leituras normais só são persistidas quando representam recuperação
        # de uma câmara com alerta aberto. Isso preserva o histórico necessário
        # para fn_camara_temperatura_normal sem gravar todas as leituras normais.
        if not outside_range and not has_open_alert:
            return None

        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO tb_leitura_temperatura
                    (cod_termometro, temperatura, data_hora, id_evento_redis)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (id_evento_redis) DO NOTHING
                RETURNING id
                """,
                (thermometer_id, temperature, measured_at, event_id),
            )
            row = cursor.fetchone()
            if row is not None:
                return row[0]

            cursor.execute(
                """
                SELECT id
                FROM tb_leitura_temperatura
                WHERE id_evento_redis = %s
                """,
                (event_id,),
            )
            existing = cursor.fetchone()
            return existing[0] if existing else None

    def reading_alert_id(
        self, connection: psycopg.Connection, reading_id: int
    ) -> int | None:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT cod_alerta FROM tb_leitura_temperatura WHERE id = %s",
                (reading_id,),
            )
            row = cursor.fetchone()
            return row[0] if row else None

    def schedule_deadlines(
        self, connection: psycopg.Connection, alert_id: int
    ) -> list[tuple[str, float]]:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    a.nivel_atual,
                    EXTRACT(EPOCH FROM (
                        (
                            a.data_hora
                            + fn_calcular_prazo_escalonamento(a.id, 40)
                              * INTERVAL '1 hour'
                        ) AT TIME ZONE 'America/Sao_Paulo'
                    )) AS prazo_40,
                    EXTRACT(EPOCH FROM (
                        (
                            a.data_hora
                            + fn_calcular_prazo_escalonamento(a.id, 70)
                              * INTERVAL '1 hour'
                        ) AT TIME ZONE 'America/Sao_Paulo'
                    )) AS prazo_70
                FROM tb_alerta a
                WHERE a.id = %s
                  AND a.status = 'ativo'
                """,
                (alert_id,),
            )
            row = cursor.fetchone()

        if row is None:
            return []

        level, deadline_40, deadline_70 = row
        deadlines: list[tuple[str, float]] = []
        if level == "operador":
            deadlines.append((f"{alert_id}:40", float(deadline_40)))
        if level in ("operador", "gestor"):
            deadlines.append((f"{alert_id}:70", float(deadline_70)))
        return deadlines

    def active_alert_ids(self, connection: psycopg.Connection) -> list[int]:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM tb_alerta WHERE status = 'ativo'")
            return [row[0] for row in cursor.fetchall()]

    def call_escalation_procedure(self, connection: psycopg.Connection) -> None:
        with connection.cursor() as cursor:
            cursor.execute("CALL sp_escalonar_alertas_pendentes()")

    def notification_cursor(self, connection: psycopg.Connection) -> int:
        with connection.cursor() as cursor:
            cursor.execute("SELECT COALESCE(MAX(id), 0) FROM tb_notificacao_alerta")
            return cursor.fetchone()[0]

    def notifications_after(
        self, connection: psycopg.Connection, last_id: int
    ) -> list[tuple[int, int, int, datetime]]:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, cod_alerta, cod_usuario, data_hora_envio
                FROM tb_notificacao_alerta
                WHERE id > %s
                ORDER BY id
                """,
                (last_id,),
            )
            return cursor.fetchall()

    def notifications_for_alert(
        self, connection: psycopg.Connection, alert_id: int
    ) -> list[tuple[int, int, int, datetime]]:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, cod_alerta, cod_usuario, data_hora_envio
                FROM tb_notificacao_alerta
                WHERE cod_alerta = %s
                ORDER BY id
                """,
                (alert_id,),
            )
            return cursor.fetchall()


class RedisWorker:
    def __init__(self) -> None:
        self.redis = redis.Redis.from_url(REDIS_URL, decode_responses=True)
        self.repository = PostgresRepository()
        self.stop_event = threading.Event()

    def ensure_consumer_group(self) -> None:
        try:
            self.redis.xgroup_create(
                name=TEMPERATURE_STREAM,
                groupname=TEMPERATURE_GROUP,
                id="0",
                mkstream=True,
            )
        except redis.ResponseError as exc:
            if "BUSYGROUP" not in str(exc):
                raise

    def publish_notifications(
        self,
        notifications: list[tuple[int, int, int, datetime]],
    ) -> None:
        for notification_id, alert_id, user_id, sent_at in notifications:
            marker = f"skadi:notificacao:publicada:{notification_id}"
            if not self.redis.set(marker, "1", nx=True, ex=7 * 24 * 60 * 60):
                continue

            self.redis.xadd(
                PUSH_STREAM,
                {
                    "id_notificacao": str(notification_id),
                    "id_alerta": str(alert_id),
                    "id_usuario": str(user_id),
                    "data_hora_envio": sent_at.isoformat(),
                },
                maxlen=10000,
                approximate=True,
            )

    def schedule_alert(self, alert_id: int) -> None:
        with self.repository.connect() as connection:
            deadlines = self.repository.schedule_deadlines(connection, alert_id)
        if deadlines:
            self.redis.zadd(ESCALATION_ZSET, dict(deadlines))

    def temperature_loop(self) -> None:
        connection = self.repository.connect()
        while not self.stop_event.is_set():
            try:
                messages = self.redis.xreadgroup(
                    groupname=TEMPERATURE_GROUP,
                    consumername=CONSUMER_NAME,
                    streams={TEMPERATURE_STREAM: ">"},
                    count=BATCH_SIZE,
                    block=BLOCK_MS,
                )

                for _stream, entries in messages:
                    for message_id, fields in entries:
                        try:
                            event_id = fields.get("id_evento_redis", message_id)
                            thermometer_id = int(fields["cod_termometro"])
                            temperature = parse_temperature(fields["temperatura"])
                            measured_at = parse_timestamp(fields.get("data_hora"))

                            reading_id = self.repository.persist_reading(
                                connection,
                                event_id,
                                thermometer_id,
                                temperature,
                                measured_at,
                            )
                            if reading_id is not None:
                                alert_id = self.repository.reading_alert_id(
                                    connection, reading_id
                                )
                                if alert_id is not None:
                                    self.schedule_alert(alert_id)
                                    self.publish_notifications(
                                        self.repository.notifications_for_alert(
                                            connection, alert_id
                                        )
                                    )

                            self.redis.xack(
                                TEMPERATURE_STREAM, TEMPERATURE_GROUP, message_id
                            )
                        except (KeyError, ValueError, psycopg.Error) as exc:
                            LOGGER.exception(
                                "Falha ao processar leitura %s; mensagem não confirmada: %s",
                                message_id,
                                exc,
                            )
            except (redis.RedisError, psycopg.Error):
                LOGGER.exception("Falha no consumidor de temperatura; reconectando")
                connection.close()
                time.sleep(2)
                connection = self.repository.connect()

    def listen_for_alerts(self) -> None:
        connection = self.repository.connect()
        connection.execute(f"LISTEN {POSTGRES_ALERT_CHANNEL}")

        while not self.stop_event.is_set():
            try:
                for notification in connection.notifies(timeout=1):
                    try:
                        payload = json.loads(notification.payload)
                        self.schedule_alert(int(payload["id_alerta"]))
                    except (KeyError, TypeError, ValueError, json.JSONDecodeError):
                        LOGGER.exception(
                            "Payload inválido no canal %s", POSTGRES_ALERT_CHANNEL
                        )
            except psycopg.Error:
                LOGGER.exception("Falha ao escutar alertas; reconectando")
                connection.close()
                time.sleep(2)
                connection = self.repository.connect()
                connection.execute(f"LISTEN {POSTGRES_ALERT_CHANNEL}")

    def scheduler_loop(self) -> None:
        with self.repository.connect() as connection:
            for alert_id in self.repository.active_alert_ids(connection):
                self.schedule_alert(alert_id)

        connection = self.repository.connect()
        while not self.stop_event.is_set():
            due_jobs = self.redis.zrangebyscore(
                ESCALATION_ZSET, min=0, max=time.time(), start=0, num=100
            )

            for job in due_jobs:
                lock_key = f"{ESCALATION_ZSET}:lock:{job}"
                if not self.redis.set(lock_key, CONSUMER_NAME, nx=True, ex=60):
                    continue

                try:
                    last_notification_id = self.repository.notification_cursor(connection)
                    self.repository.call_escalation_procedure(connection)
                    self.publish_notifications(
                        self.repository.notifications_after(
                            connection, last_notification_id
                        )
                    )
                    self.redis.zrem(ESCALATION_ZSET, job)
                except psycopg.Error:
                    LOGGER.exception("Falha ao escalonar o job %s", job)
                finally:
                    self.redis.delete(lock_key)

            time.sleep(SCHEDULER_POLL_SECONDS)

    def run(self) -> None:
        self.ensure_consumer_group()
        threads = [
            threading.Thread(target=self.temperature_loop, name="temperature"),
            threading.Thread(target=self.listen_for_alerts, name="pg-listener"),
            threading.Thread(target=self.scheduler_loop, name="scheduler"),
        ]
        for thread in threads:
            thread.start()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            LOGGER.info("Encerrando worker")
            self.stop_event.set()
            for thread in threads:
                thread.join(timeout=5)


if __name__ == "__main__":
    RedisWorker().run()
