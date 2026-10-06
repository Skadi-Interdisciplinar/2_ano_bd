"""Carga delta do banco legado para o PostgreSQL do Skadi.

O script preserva os IDs do legado no destino. Por isso, não usa uma tabela
de mapeamento: as chaves estrangeiras são copiadas com os mesmos valores.
"""

from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Callable
from datetime import datetime, timezone

import psycopg
from psycopg.rows import dict_row


LOGGER = logging.getLogger("rpa_skadi")

TABELAS_COM_DATA_ATUALIZACAO = (
    "cd",
    "endereco",
    "usuario",
    "categoria",
    "termometro",
    "frigorifico",
    "lote",
    "lote_frigorifico",
)


def configurar_logs() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )


def obter_configuracao(nome: str) -> str:
    valor = os.getenv(nome)
    if not valor:
        raise RuntimeError(f"A variável de ambiente {nome} é obrigatória.")
    return valor


def obter_ultima_execucao(
    conexao: psycopg.Connection,
    nome_carga: str,
) -> datetime | None:
    with conexao.cursor() as cursor:
        cursor.execute(
            """
            SELECT ultima_execucao_sucesso
            FROM tb_controle_rpa
            WHERE nome_carga = %s
            """,
            (nome_carga,),
        )
        linha = cursor.fetchone()
    return linha[0] if linha else None


def buscar_delta(
    conexao: psycopg.Connection,
    consulta: str,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> list[dict]:
    filtros = "data_atualizacao <= %s"
    parametros: list[datetime] = [limite_execucao]

    if ultima_execucao is not None:
        filtros = "data_atualizacao > %s AND " + filtros
        parametros.insert(0, ultima_execucao)

    with conexao.cursor(row_factory=dict_row) as cursor:
        cursor.execute(consulta.format(filtros=filtros), parametros)
        return list(cursor.fetchall())


def executar_upsert(
    conexao: psycopg.Connection,
    comando: str,
    registros: list[dict],
    parametros: Callable[[dict], tuple],
) -> int:
    if not registros:
        return 0

    with conexao.cursor() as cursor:
        for registro in registros:
            cursor.execute(comando, parametros(registro))
    return len(registros)


def carregar_cds(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT id_cd, nome, cnpj
        FROM cd
        WHERE {filtros}
        ORDER BY id_cd
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_cd (id, nome, cnpj)
        VALUES (%s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET nome = EXCLUDED.nome,
            cnpj = EXCLUDED.cnpj
        """,
        registros,
        lambda registro: (registro["id_cd"], registro["nome"], registro["cnpj"]),
    )


def obter_id_estado(destino: psycopg.Connection, sigla: str) -> int:
    with destino.cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO tb_estado (estado)
            VALUES (%s)
            ON CONFLICT (estado) DO UPDATE SET estado = EXCLUDED.estado
            RETURNING id
            """,
            (sigla,),
        )
        return cursor.fetchone()[0]


def carregar_enderecos(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT
            id_endereco, id_cd, rua, numero, complemento,
            bairro, cidade, estado, cep
        FROM endereco
        WHERE {filtros}
        ORDER BY id_endereco
        """,
        ultima_execucao,
        limite_execucao,
    )

    if not registros:
        return 0

    comando = """
        INSERT INTO tb_endereco (
            id, cep, rua, numero, cidade, bairro, complemento,
            cod_estado, cod_cd
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET cep = EXCLUDED.cep,
            rua = EXCLUDED.rua,
            numero = EXCLUDED.numero,
            cidade = EXCLUDED.cidade,
            bairro = EXCLUDED.bairro,
            complemento = EXCLUDED.complemento,
            cod_estado = EXCLUDED.cod_estado,
            cod_cd = EXCLUDED.cod_cd
    """
    with destino.cursor() as cursor:
        for registro in registros:
            cod_estado = obter_id_estado(destino, registro["estado"])
            cursor.execute(
                comando,
                (
                    registro["id_endereco"],
                    registro["cep"],
                    registro["rua"],
                    registro["numero"],
                    registro["cidade"],
                    registro["bairro"],
                    registro["complemento"],
                    cod_estado,
                    registro["id_cd"],
                ),
            )
    return len(registros)


def validar_usuario(registro: dict) -> None:
    niveis_validos = {"operador", "gestor", "admin", "super_admin"}
    nivel = registro["nivel_acesso"]

    if nivel not in niveis_validos:
        raise ValueError(
            f"Usuário legado {registro['id_usuario']} possui nível inválido: {nivel!r}."
        )

    if nivel == "super_admin":
        if any(
            registro[campo] is not None
            for campo in ("cpf", "id_cd", "cod_gestor")
        ):
            raise ValueError(
                "Usuário super_admin do legado deve possuir CPF, CD e gestor vazios. "
                f"ID: {registro['id_usuario']}."
            )
        return

    if registro["cpf"] is None or registro["id_cd"] is None:
        raise ValueError(
            "Usuário não super_admin deve possuir CPF e CD. "
            f"ID: {registro['id_usuario']}."
        )

    if nivel == "operador" and registro["cod_gestor"] is None:
        raise ValueError(
            f"Usuário operador {registro['id_usuario']} deve possuir gestor."
        )

    if nivel != "operador" and registro["cod_gestor"] is not None:
        raise ValueError(
            f"Usuário {nivel} {registro['id_usuario']} não pode possuir gestor."
        )


def carregar_usuarios(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT
            id_usuario, username, cod_gestor, nome, cpf, email,
            senha, nivel_acesso, id_cd
        FROM usuario
        WHERE {filtros}
        ORDER BY
            CASE nivel_acesso
                WHEN 'super_admin' THEN 1
                WHEN 'admin' THEN 2
                WHEN 'gestor' THEN 3
                WHEN 'operador' THEN 4
            END,
            id_usuario
        """,
        ultima_execucao,
        limite_execucao,
    )

    for registro in registros:
        validar_usuario(registro)

    return executar_upsert(
        destino,
        """
        INSERT INTO tb_usuario (
            id, nome, username, cpf, email, senha,
            nivel_acesso, cod_cd, cod_gestor
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET nome = EXCLUDED.nome,
            username = EXCLUDED.username,
            cpf = EXCLUDED.cpf,
            email = EXCLUDED.email,
            senha = EXCLUDED.senha,
            nivel_acesso = EXCLUDED.nivel_acesso,
            cod_cd = EXCLUDED.cod_cd,
            cod_gestor = EXCLUDED.cod_gestor
        """,
        registros,
        lambda registro: (
            registro["id_usuario"],
            registro["nome"],
            registro["username"],
            registro["cpf"],
            registro["email"],
            registro["senha"],
            registro["nivel_acesso"],
            registro["id_cd"],
            registro["cod_gestor"],
        ),
    )


def carregar_categorias(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT id_categoria, nome, temperatura_min, temperatura_max, vida_util_horas
        FROM categoria
        WHERE {filtros}
        ORDER BY id_categoria
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_categoria (
            id, nome, temperatura_min, temperatura_max, vida_util_horas
        )
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET nome = EXCLUDED.nome,
            temperatura_min = EXCLUDED.temperatura_min,
            temperatura_max = EXCLUDED.temperatura_max,
            vida_util_horas = EXCLUDED.vida_util_horas
        """,
        registros,
        lambda registro: (
            registro["id_categoria"],
            registro["nome"],
            registro["temperatura_min"],
            registro["temperatura_max"],
            registro["vida_util_horas"],
        ),
    )


def carregar_termometros(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT id_termometro, modelo
        FROM termometro
        WHERE {filtros}
        ORDER BY id_termometro
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_termometro (id, modelo)
        VALUES (%s, %s)
        ON CONFLICT (id) DO UPDATE
        SET modelo = EXCLUDED.modelo
        """,
        registros,
        lambda registro: (registro["id_termometro"], registro["modelo"]),
    )


def carregar_camaras(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT
            f.id_frigorifico,
            f.modelo,
            f.localizacao,
            f.temperatura_min,
            f.temperatura_max,
            f.id_cd,
            t.id_termometro
        FROM frigorifico f
        JOIN termometro t ON t.id_frigorifico = f.id_frigorifico
        WHERE f.{filtros}
        ORDER BY f.id_frigorifico
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_camara_frigorifica (
            id, modelo, localizacao, temperatura_min, temperatura_max,
            cod_cd, cod_termometro
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET modelo = EXCLUDED.modelo,
            localizacao = EXCLUDED.localizacao,
            temperatura_min = EXCLUDED.temperatura_min,
            temperatura_max = EXCLUDED.temperatura_max,
            cod_cd = EXCLUDED.cod_cd,
            cod_termometro = EXCLUDED.cod_termometro
        """,
        registros,
        lambda registro: (
            registro["id_frigorifico"],
            registro["modelo"],
            registro["localizacao"],
            registro["temperatura_min"],
            registro["temperatura_max"],
            registro["id_cd"],
            registro["id_termometro"],
        ),
    )


def carregar_lotes(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT id_lote, codigo_lote, id_categoria, data_fabricacao, data_validade, status
        FROM lote
        WHERE {filtros}
        ORDER BY id_lote
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_lote (
            id, codigo_lote, cod_categoria, data_fabricacao, data_validade, status
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET codigo_lote = EXCLUDED.codigo_lote,
            cod_categoria = EXCLUDED.cod_categoria,
            data_fabricacao = EXCLUDED.data_fabricacao,
            data_validade = EXCLUDED.data_validade,
            status = EXCLUDED.status
        """,
        registros,
        lambda registro: (
            registro["id_lote"],
            registro["codigo_lote"],
            registro["id_categoria"],
            registro["data_fabricacao"],
            registro["data_validade"],
            registro["status"],
        ),
    )


def carregar_lotes_camara(
    legado: psycopg.Connection,
    destino: psycopg.Connection,
    ultima_execucao: datetime | None,
    limite_execucao: datetime,
) -> int:
    registros = buscar_delta(
        legado,
        """
        SELECT id_lote_frigorifico, id_lote, id_frigorifico, data_entrada, data_saida
        FROM lote_frigorifico
        WHERE {filtros}
        ORDER BY id_lote_frigorifico
        """,
        ultima_execucao,
        limite_execucao,
    )
    return executar_upsert(
        destino,
        """
        INSERT INTO tb_lote_camara_frigorifica (
            id, cod_lote, cod_camara_frigorifica, data_entrada, data_saida
        )
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE
        SET cod_lote = EXCLUDED.cod_lote,
            cod_camara_frigorifica = EXCLUDED.cod_camara_frigorifica,
            data_entrada = EXCLUDED.data_entrada,
            data_saida = EXCLUDED.data_saida
        """,
        registros,
        lambda registro: (
            registro["id_lote_frigorifico"],
            registro["id_lote"],
            registro["id_frigorifico"],
            registro["data_entrada"],
            registro["data_saida"],
        ),
    )


def sincronizar_sequences(destino: psycopg.Connection) -> None:
    tabelas = (
        ("tb_cd", "id"),
        ("tb_endereco", "id"),
        ("tb_usuario", "id"),
        ("tb_categoria", "id"),
        ("tb_termometro", "id"),
        ("tb_camara_frigorifica", "id"),
        ("tb_lote", "id"),
        ("tb_lote_camara_frigorifica", "id"),
    )
    with destino.cursor() as cursor:
        for tabela, coluna in tabelas:
            cursor.execute(
                f"""
                SELECT setval(
                    pg_get_serial_sequence('{tabela}', '{coluna}'),
                    COALESCE(MAX({coluna}), 1),
                    MAX({coluna}) IS NOT NULL
                )
                FROM {tabela}
                """
            )


def registrar_execucao_sucesso(
    destino: psycopg.Connection,
    nome_carga: str,
    limite_execucao: datetime,
) -> None:
    with destino.cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO tb_controle_rpa (nome_carga, ultima_execucao_sucesso)
            VALUES (%s, %s)
            ON CONFLICT (nome_carga) DO UPDATE
            SET ultima_execucao_sucesso = EXCLUDED.ultima_execucao_sucesso
            """,
            (nome_carga, limite_execucao),
        )


def executar_carga(completa: bool, nome_carga: str) -> None:
    url_legado = obter_configuracao("LEGACY_DATABASE_URL")
    url_destino = obter_configuracao("SKADI_DATABASE_URL")
    limite_execucao = datetime.now(timezone.utc)

    with psycopg.connect(url_legado) as legado, psycopg.connect(url_destino) as destino:
        ultima_execucao = None if completa else obter_ultima_execucao(destino, nome_carga)
        LOGGER.info(
            "Iniciando %s. Última execução bem-sucedida: %s",
            nome_carga,
            ultima_execucao or "nenhuma (carga inicial)",
        )

        quantidades = {
            "cd": carregar_cds(legado, destino, ultima_execucao, limite_execucao),
            "endereco": carregar_enderecos(legado, destino, ultima_execucao, limite_execucao),
            "usuario": carregar_usuarios(legado, destino, ultima_execucao, limite_execucao),
            "categoria": carregar_categorias(legado, destino, ultima_execucao, limite_execucao),
            "termometro": carregar_termometros(legado, destino, ultima_execucao, limite_execucao),
            "frigorifico": carregar_camaras(
                legado, destino, ultima_execucao, limite_execucao
            ),
            "lote": carregar_lotes(legado, destino, ultima_execucao, limite_execucao),
            "lote_frigorifico": carregar_lotes_camara(
                legado, destino, ultima_execucao, limite_execucao
            ),
        }

        sincronizar_sequences(destino)
        registrar_execucao_sucesso(destino, nome_carga, limite_execucao)
        destino.commit()

    for tabela in TABELAS_COM_DATA_ATUALIZACAO:
        LOGGER.info("%s: %s registro(s) sincronizado(s)", tabela, quantidades[tabela])


def main() -> None:
    configurar_logs()
    parser = argparse.ArgumentParser(description="Executa a carga delta do Skadi.")
    parser.add_argument(
        "--completa",
        action="store_true",
        help="Ignora a última execução e sincroniza todos os registros do legado.",
    )
    parser.add_argument(
        "--nome-carga",
        default=os.getenv("RPA_NOME_CARGA", "carga_delta_legado"),
        help="Identificador da carga em tb_controle_rpa.",
    )
    argumentos = parser.parse_args()

    try:
        executar_carga(argumentos.completa, argumentos.nome_carga)
    except Exception:
        LOGGER.exception("A carga delta falhou. A data da última execução não foi atualizada.")
        raise


if __name__ == "__main__":
    main()
