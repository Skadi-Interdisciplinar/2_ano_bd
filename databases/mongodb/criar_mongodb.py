import os
from pathlib import Path

from dotenv import load_dotenv
from pymongo import ASCENDING, DESCENDING, MongoClient

# Carrega o .env localizado ao lado deste script, independentemente da pasta
# pela qual o comando for executado.
load_dotenv(Path(__file__).resolve().parent / ".env")

MONGO_URI = os.getenv("MONGODB_URI")
DATABASE_NAME = "Skadi"

if not MONGO_URI:
    raise ValueError("MONGODB_URI não encontrada no arquivo .env")


def criar_collection_se_necessario(db, nome: str) -> None:
    if nome not in db.list_collection_names():
        db.create_collection(nome)
        print(f"Collection criada: {nome}")
    else:
        print(f"Collection já existe: {nome}")


def criar_indice_se_nao_existir(collection, campos, nome_indice: str) -> None:
    indices = collection.index_information()

    if nome_indice in indices:
        print(f"Índice já existe: {collection.name}.{nome_indice}")
        return

    if any(tuple(info["key"]) == tuple(campos) for info in indices.values()):
        print(f"Índice equivalente já existe: {collection.name}")
        return

    collection.create_index(campos, name=nome_indice)
    print(f"Índice criado: {collection.name}.{nome_indice}")


# Cada mensagem pertence ao array conversas.mensagens. Não há collection
# separada chamada mensagens e cada mensagem não precisa de conversaId.
schema_mensagem = {
    "bsonType": "object",
    "required": ["dataHora", "remetente", "conteudo", "tipo"],
    "properties": {
        "dataHora": {"bsonType": "date"},
        "remetente": {"bsonType": "string"},
        "conteudo": {"bsonType": "string"},
        "tipo": {"bsonType": "string"},
        "agente": {"bsonType": "string"},
    },
}


validator_predicoes = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "refrigeradorId", "dataHora", "horizonte", "temperaturaAtual",
            "temperaturaPrevista", "limiteTemperatura", "gravidade",
            "probabilidade", "tendencia",
        ],
        "properties": {
            "refrigeradorId": {"bsonType": "int", "minimum": 1},
            "dataHora": {"bsonType": "date"},
            "horizonte": {
                "bsonType": "object",
                "required": ["minutos"],
                "properties": {"minutos": {"bsonType": "int", "minimum": 1}},
            },
            "temperaturaAtual": {"bsonType": ["double", "int", "long", "decimal"]},
            "temperaturaPrevista": {"bsonType": ["double", "int", "long", "decimal"]},
            "limiteTemperatura": {"bsonType": ["double", "int", "long", "decimal"]},
            # O Mongo apenas registra a gravidade calculada pela função do
            # PostgreSQL a partir da diferença absoluta entre temperatura atual
            # e ideal. Os valores abaixo são os retornados pela função atual.
            "gravidade": {
                "bsonType": "string",
                "enum": ["baixa", "atenção", "urgente", "crítica"],
            },
            # A escala de probabilidade ainda não foi definida; por isso não é
            # restringida artificialmente a 0-1 neste momento.
            "probabilidade": {"bsonType": ["double", "int", "long", "decimal"]},
            "tendencia": {"bsonType": "string"},
        },
    }
}


validator_diagnosticos = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "refrigeradorId", "alertaId", "dataHora", "causas", "causaPrincipal",
            "evidencias", "recomendacao", "confianca",
        ],
        "properties": {
            "refrigeradorId": {"bsonType": "int", "minimum": 1},
            "alertaId": {"bsonType": "int", "minimum": 1},
            "dataHora": {"bsonType": "date"},
            "causas": {
                "bsonType": "array",
                "items": {
                    "bsonType": "object",
                    "required": ["causa", "probabilidade"],
                    "properties": {
                        "causa": {"bsonType": "string"},
                        "probabilidade": {"bsonType": ["double", "int", "long", "decimal"]},
                    },
                },
            },
            "causaPrincipal": {"bsonType": "string"},
            "evidencias": {"bsonType": "array", "items": {"bsonType": "string"}},
            "recomendacao": {"bsonType": "string"},
            "confianca": {"bsonType": ["double", "int", "long", "decimal"]},
        },
    }
}


validator_conversas = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["usuarioId", "inicio", "ultimaAtualizacao", "mensagens"],
        "properties": {
            "usuarioId": {"bsonType": "int", "minimum": 1},
            "inicio": {"bsonType": "date"},
            "ultimaAtualizacao": {"bsonType": "date"},
            "mensagens": {"bsonType": "array", "items": schema_mensagem},
        },
    }
}


validator_execucoes = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["agente", "inicio", "entrada", "status"],
        "properties": {
            "agente": {"bsonType": "string"},
            "inicio": {"bsonType": "date"},
            # termino permanece ausente enquanto a execução estiver em andamento.
            "termino": {"bsonType": "date"},
            "entrada": {"bsonType": "object"},
            "status": {"bsonType": "string"},
        },
    }
}


try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    db = client[DATABASE_NAME]
    print(f"Conexão com MongoDB realizada com sucesso! Banco: {DATABASE_NAME}")

    for nome in ("predicoes", "diagnosticos", "conversas", "execucoes_agentes"):
        criar_collection_se_necessario(db, nome)

    validadores = {
        "predicoes": validator_predicoes,
        "diagnosticos": validator_diagnosticos,
        "conversas": validator_conversas,
        "execucoes_agentes": validator_execucoes,
    }

    print("Aplicando validações...")
    for nome, validator in validadores.items():
        db.command(
            "collMod",
            nome,
            validator=validator,
            validationLevel="strict",
            validationAction="error",
        )
        print(f"Validação aplicada: {nome}")

    print("Criando/verificando índices...")
    criar_indice_se_nao_existir(
        db.predicoes,
        [("refrigeradorId", ASCENDING), ("dataHora", DESCENDING)],
        "idx_predicao_refrigerador_data",
    )
    criar_indice_se_nao_existir(
        db.diagnosticos,
        [("refrigeradorId", ASCENDING), ("dataHora", DESCENDING)],
        "idx_diagnostico_refrigerador_data",
    )
    criar_indice_se_nao_existir(
        db.diagnosticos,
        [("alertaId", ASCENDING)],
        "idx_diagnostico_alerta",
    )
    criar_indice_se_nao_existir(
        db.conversas,
        [("usuarioId", ASCENDING), ("ultimaAtualizacao", DESCENDING)],
        "idx_conversa_usuario_data",
    )
    criar_indice_se_nao_existir(
        db.execucoes_agentes,
        [("agente", ASCENDING), ("inicio", DESCENDING)],
        "idx_execucao_agente_data",
    )
    criar_indice_se_nao_existir(
        db.execucoes_agentes,
        [("status", ASCENDING)],
        "idx_execucao_status",
    )

    # O script não apaga collections antigas nem migra dados automaticamente.
    for nome_antigo in ("leituras_temperatura", "mensagens"):
        if nome_antigo in db.list_collection_names():
            print(f"Aviso: a collection antiga '{nome_antigo}' ainda existe e não foi alterada.")

    print("Modelo MongoDB configurado com sucesso!")

finally:
    if "client" in locals():
        client.close()
