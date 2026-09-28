"""Sincroniza as entidades relacionais principais do Skadi para o Neo4j."""

from __future__ import annotations

import os
from collections.abc import Iterable
from datetime import date, datetime
from decimal import Decimal
from typing import Any

import psycopg
from dotenv import load_dotenv
from neo4j import GraphDatabase

load_dotenv()

DATABASE_URL = os.environ["DATABASE_URL"]
NEO4J_URI = os.environ.get("NEO4J_URI", "neo4j://localhost:7687")
NEO4J_USER = os.environ.get("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.environ["NEO4J_PASSWORD"]
NEO4J_DATABASE = os.environ.get("NEO4J_DATABASE", "neo4j")


def serializable(value: Any) -> Any:
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    return value


def fetch_rows(connection: psycopg.Connection, query: str) -> list[dict[str, Any]]:
    with connection.cursor() as cursor:
        cursor.execute(query)
        columns = [column.name for column in cursor.description]
        return [
            {column: serializable(value) for column, value in zip(columns, row)}
            for row in cursor.fetchall()
        ]


def write_batches(session: Any, query: str, rows: Iterable[dict[str, Any]]) -> None:
    values = list(rows)
    if values:
        session.run(query, rows=values).consume()


def sync() -> None:
    with psycopg.connect(DATABASE_URL) as postgres:
        data = {
            "cds": fetch_rows(postgres, "SELECT id, nome, cnpj FROM tb_cd"),
            "camaras": fetch_rows(
                postgres,
                """
                SELECT id, modelo, localizacao, temperatura_min,
                       temperatura_max, cod_cd, cod_termometro
                FROM tb_camara_frigorifica
                """,
            ),
            "termometros": fetch_rows(
                postgres, "SELECT id, modelo FROM tb_termometro"
            ),
            "categorias": fetch_rows(
                postgres,
                """
                SELECT id, nome, temperatura_ideal, vida_util_horas
                FROM tb_categoria
                """,
            ),
            "lotes": fetch_rows(
                postgres,
                """
                SELECT id, codigo_lote, cod_categoria, data_fabricacao,
                       data_validade, status
                FROM tb_lote
                """,
            ),
            "armazenamentos": fetch_rows(
                postgres,
                """
                SELECT id, cod_lote, cod_camara_frigorifica,
                       data_entrada, data_saida
                FROM tb_lote_camara_frigorifica
                """,
            ),
            "usuarios": fetch_rows(
                postgres,
                """
                SELECT id, nome, username, nivel_acesso, cod_cd, cod_gestor
                FROM tb_usuario
                """,
            ),
            "alertas": fetch_rows(
                postgres,
                """
                SELECT id, cod_camara_frigorifica,
                       vida_util_referencia_horas, nivel_atual,
                       data_hora, tipo, nivel_gravidade, status
                FROM tb_alerta
                """,
            ),
            "atendimentos": fetch_rows(
                postgres,
                """
                SELECT id, cod_alerta, cod_usuario,
                       data_hora_reconhecimento, data_hora_resolucao, status
                FROM tb_atendimento
                """,
            ),
            "justificativas": fetch_rows(
                postgres,
                """
                SELECT id, cod_atendimento, motivo, descricao, data_hora
                FROM tb_justificativa
                """,
            ),
        }

    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    try:
        with driver.session(database=NEO4J_DATABASE) as session:
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:CD {id: row.id})
                SET n.nome = row.nome, n.cnpj = row.cnpj
                """,
                data["cds"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Termometro {id: row.id})
                SET n.modelo = row.modelo
                """,
                data["termometros"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Categoria {id: row.id})
                SET n.nome = row.nome,
                    n.temperatura_ideal = row.temperatura_ideal,
                    n.vida_util_horas = row.vida_util_horas
                """,
                data["categorias"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Lote {id: row.id})
                SET n.codigo_lote = row.codigo_lote,
                    n.data_fabricacao = row.data_fabricacao,
                    n.data_validade = row.data_validade,
                    n.status = row.status
                WITH n, row
                MATCH (categoria:Categoria {id: row.cod_categoria})
                MERGE (n)-[:PERTENCE_A_CATEGORIA]->(categoria)
                """,
                data["lotes"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:CamaraFrigorifica {id: row.id})
                SET n.modelo = row.modelo,
                    n.localizacao = row.localizacao,
                    n.temperatura_min = row.temperatura_min,
                    n.temperatura_max = row.temperatura_max
                WITH n, row
                MATCH (cd:CD {id: row.cod_cd})
                MERGE (cd)-[:POSSUI_CAMARA]->(n)
                WITH n, row
                MATCH (termometro:Termometro {id: row.cod_termometro})
                MERGE (n)-[:TEM_TERMOMETRO]->(termometro)
                """,
                data["camaras"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MATCH (camara:CamaraFrigorifica {id: row.cod_camara_frigorifica})
                MATCH (lote:Lote {id: row.cod_lote})
                MERGE (camara)-[r:ARMAZENA_LOTE {id: row.id}]->(lote)
                SET r.data_entrada = row.data_entrada,
                    r.data_saida = row.data_saida
                """,
                data["armazenamentos"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Usuario {id: row.id})
                SET n.nome = row.nome,
                    n.username = row.username,
                    n.nivel_acesso = row.nivel_acesso
                WITH n, row
                OPTIONAL MATCH (cd:CD {id: row.cod_cd})
                FOREACH (_ IN CASE WHEN cd IS NULL THEN [] ELSE [1] END |
                    MERGE (n)-[:TRABALHA_NO_CD]->(cd))
                WITH n, row
                OPTIONAL MATCH (gestor:Usuario {id: row.cod_gestor})
                FOREACH (_ IN CASE WHEN gestor IS NULL THEN [] ELSE [1] END |
                    MERGE (n)-[:RESPONDE_A]->(gestor))
                """,
                data["usuarios"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Alerta {id: row.id})
                SET n.vida_util_referencia_horas = row.vida_util_referencia_horas,
                    n.nivel_atual = row.nivel_atual,
                    n.data_hora = row.data_hora,
                    n.tipo = row.tipo,
                    n.nivel_gravidade = row.nivel_gravidade,
                    n.status = row.status
                WITH n, row
                MATCH (camara:CamaraFrigorifica {id: row.cod_camara_frigorifica})
                MERGE (camara)-[:GEROU_ALERTA]->(n)
                """,
                data["alertas"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Atendimento {id: row.id})
                SET n.status = row.status,
                    n.data_hora_reconhecimento = row.data_hora_reconhecimento,
                    n.data_hora_resolucao = row.data_hora_resolucao
                WITH n, row
                MATCH (alerta:Alerta {id: row.cod_alerta})
                MERGE (alerta)-[:POSSUI_ATENDIMENTO]->(n)
                WITH n, row
                OPTIONAL MATCH (usuario:Usuario {id: row.cod_usuario})
                FOREACH (_ IN CASE WHEN usuario IS NULL THEN [] ELSE [1] END |
                    MERGE (n)-[:ATENDIDO_POR]->(usuario))
                """,
                data["atendimentos"],
            )
            write_batches(
                session,
                """
                UNWIND $rows AS row
                MERGE (n:Justificativa {id: row.id})
                SET n.motivo = row.motivo,
                    n.descricao = row.descricao,
                    n.data_hora = row.data_hora
                WITH n, row
                MATCH (atendimento:Atendimento {id: row.cod_atendimento})
                MERGE (atendimento)-[:TEM_JUSTIFICATIVA]->(n)
                """,
                data["justificativas"],
            )
    finally:
        driver.close()


if __name__ == "__main__":
    sync()
