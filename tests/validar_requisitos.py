"""Validação integrada exclusivamente em containers descartáveis identificados.

Requer os containers preparados conforme docs de validação e os drivers de rpa
e Neo4j. Não carrega .env nem aceita URLs de bancos reais como argumento.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime
from zoneinfo import ZoneInfo

import psycopg
from neo4j import GraphDatabase

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "databases/postgresql"
PG = "skadi-requisitos-pg-20261101"
NEO = "skadi-requisitos-neo-20261101"
EVIDENCIA = SQL / "evidencias/validacao-requisitos.json"


def comando(*args: str, entrada: str | None = None) -> str:
    resultado = subprocess.run(args, input=entrada, text=True, encoding="utf-8",
                               capture_output=True)
    if resultado.returncode:
        raise RuntimeError(f"Comando {args[0]} falhou: {resultado.stderr[-4000:]}")
    return resultado.stdout.strip()


def container_teste(nome: str, porta: str) -> str:
    dados = json.loads(comando("docker", "inspect", nome))[0]
    if dados["Config"].get("Labels", {}).get("skadi.validation") != "true":
        raise RuntimeError(f"Container {nome} não identificado como descartável.")
    bindings = dados["NetworkSettings"]["Ports"][porta]
    if len(bindings) != 1 or bindings[0]["HostIp"] != "127.0.0.1":
        raise RuntimeError("O teste exige publicação exclusiva em loopback.")
    return bindings[0]["HostPort"]


def psql(texto: str, banco: str = "skadi") -> str:
    return comando("docker", "exec", "-i", "-e", "PGCLIENTENCODING=UTF8", PG,
                   "psql", "-U", "postgres", "-d", banco, "-v", "ON_ERROR_STOP=1", "-q",
                   entrada=texto)


def escalar(c, query, args=None):
    return c.execute(query, args).fetchone()[0]


def resumo(c):
    tabelas = [r[0] for r in c.execute("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename")]
    return {
        "contagens": {t: escalar(c, psycopg.sql.SQL("SELECT count(*) FROM {}").format(psycopg.sql.Identifier(t))) for t in tabelas},
        "views": [r[0] for r in c.execute("SELECT viewname FROM pg_views WHERE schemaname='public' ORDER BY viewname")],
        "constraints": escalar(c, "SELECT count(*) FROM pg_constraint WHERE connamespace='public'::regnamespace"),
        "triggers": escalar(c, "SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE c.relnamespace='public'::regnamespace AND NOT t.tgisinternal"),
        "funcoes": escalar(c, "SELECT count(*) FROM pg_proc WHERE pronamespace='public'::regnamespace"),
    }


def main():
    port = container_teste(PG, "5432/tcp")
    neoport = container_teste(NEO, "7687/tcp")
    url = f"postgresql://postgres@127.0.0.1:{port}/skadi"
    resultado = {"gerado_em": datetime.now(ZoneInfo("America/Sao_Paulo")).isoformat(),
                 "ambiente": "PostgreSQL e Neo4j descartáveis; dados sintéticos; nenhum banco real",
                 "arquivos_sha256": {f: hashlib.sha256((SQL/f).read_bytes()).hexdigest()
                                     for f in ["audit.sql", "catalogo-dados.sql", "etl-transformacoes.sql", "deploy.sql", "atualizar-requisitos.sql"]}}

    # Confere que os scripts incorporados no deploy correspondem às fontes.
    deploy = (SQL / "deploy.sql").read_text(encoding="utf-8")
    for nome in ["audit.sql", "catalogo-dados.sql", "etl-transformacoes.sql", "indices.sql"]:
        assert (SQL/nome).read_text(encoding="utf-8").strip() in deploy, nome
    psql(deploy)
    psql((SQL / "dataload.sql").read_text(encoding="utf-8"))
    psql((SQL / "data-mart.sql").read_text(encoding="utf-8"))
    with psycopg.connect(url) as c:
        resultado["postgresql_versao"] = escalar(c, "SELECT version()")
        resultado["dataload"] = resumo(c)
        assert sum(resultado["dataload"]["contagens"].values()) >= 500
        esperado = escalar(c, "SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND left(table_name,3)='tb_'")
        assert escalar(c, "SELECT count(*) FROM tb_catalogo_dados") == esperado
        assert escalar(c, "SELECT count(*) FROM information_schema.columns c LEFT JOIN tb_catalogo_dados m ON m.nome_tabela=c.table_name AND m.nome_coluna=c.column_name WHERE c.table_schema='public' AND left(c.table_name,3)='tb_' AND m.id IS NULL") == 0
        assert escalar(c, "SELECT count(*) FROM tb_catalogo_dados m LEFT JOIN information_schema.columns c ON c.table_schema='public' AND c.table_name=m.nome_tabela AND c.column_name=m.nome_coluna WHERE c.column_name IS NULL") == 0
        resultado["catalogo"] = {"colunas": esperado, "faltantes": 0, "obsoletas": 0}
        assert escalar(c, "SELECT count(*) FROM tb_catalogo_dados m JOIN pg_class t ON t.relname=m.nome_tabela AND t.relnamespace='public'::regnamespace JOIN pg_attribute a ON a.attrelid=t.oid AND a.attname=m.nome_coluna WHERE m.tipo_dado<>format_type(a.atttypid,a.atttypmod) OR m.obrigatorio<>a.attnotnull") == 0
        assert escalar(c, "SELECT count(*) FROM pg_constraint k JOIN pg_class t ON t.oid=k.conrelid JOIN pg_attribute a ON a.attrelid=t.oid AND a.attnum=ANY(k.conkey) JOIN tb_catalogo_dados m ON m.nome_tabela=t.relname AND m.nome_coluna=a.attname WHERE t.relnamespace='public'::regnamespace AND position(k.conname || ': ' || pg_get_constraintdef(k.oid) in m.regra_negocio)=0") == 0
        assert escalar(c, "SELECT count(*) FROM tb_catalogo_dados m JOIN pg_class t ON t.relname=m.nome_tabela AND t.relnamespace='public'::regnamespace JOIN pg_attribute a ON a.attrelid=t.oid AND a.attname=m.nome_coluna WHERE m.chave IS DISTINCT FROM (CASE WHEN EXISTS(SELECT 1 FROM pg_constraint k WHERE k.conrelid=t.oid AND k.contype='p' AND a.attnum=ANY(k.conkey)) THEN 'PK' WHEN EXISTS(SELECT 1 FROM pg_constraint k WHERE k.conrelid=t.oid AND k.contype='f' AND a.attnum=ANY(k.conkey)) THEN 'FK' WHEN EXISTS(SELECT 1 FROM pg_constraint k WHERE k.conrelid=t.oid AND k.contype='u' AND a.attnum=ANY(k.conkey)) THEN 'NK' END)") == 0
        # Classificação existente e dados do catálogo sobrevivem à reaplicação.
        c.execute("UPDATE tb_catalogo_dados SET nivel_acesso_leitura='GESTOR' WHERE nome_tabela='tb_cd' AND nome_coluna='nome'")
        c.execute((SQL / "catalogo-dados.sql").read_text(encoding="utf-8"))
        assert escalar(c, "SELECT nivel_acesso_leitura FROM tb_catalogo_dados WHERE nome_tabela='tb_cd' AND nome_coluna='nome'") == "GESTOR"
        assert escalar(c, "SELECT max((length(regra_negocio)-length(replace(regra_negocio,'[SCHEMA]','')))/length('[SCHEMA]')) FROM tb_catalogo_dados") == 1
        c.rollback()

        # INSERT/UPDATE/DELETE em duas tabelas, sem omitir os filtros sensíveis.
        c.execute("SELECT set_config('app.usuario_atual','1000001',true)")
        c.execute("INSERT INTO tb_cd(id,nome,cnpj) VALUES (900001,'CD de teste','99999999999999')")
        c.execute("UPDATE tb_cd SET nome='CD atualizado' WHERE id=900001")
        c.execute("DELETE FROM tb_cd WHERE id=900001")
        c.execute("INSERT INTO tb_usuario(id,nome,username,cpf,email,senha,nivel_acesso) VALUES (900001,'Pessoa teste','teste_auditoria',NULL,'auditoria@example.test','HASH_SINTETICO','SUPER_ADMIN')")
        c.execute("UPDATE tb_usuario SET nome='Pessoa atualizada' WHERE id=900001")
        c.execute("DELETE FROM tb_usuario WHERE id=900001")
        logs = c.execute("SELECT entidade_afetada,acao,usuario_bd,dados_antigos,dados_novos FROM tb_log_auditoria WHERE entidade_id=900001 ORDER BY id").fetchall()
        assert len(logs) == 6
        for tabela, acao, usuario, antigo, novo in logs:
            assert usuario == escalar(c, "SELECT CURRENT_USER")
            assert (antigo is None) == (acao == "INSERT")
            assert (novo is None) == (acao == "DELETE")
            for snapshot in (antigo, novo):
                if snapshot and tabela == "tb_usuario":
                    assert not set(snapshot) & {"senha", "cpf", "email"}
        resultado["auditoria"] = {"tabelas": ["tb_cd", "tb_usuario"], "operacoes": 6, "current_user": "conferido", "snapshots_sanitizados": True}
        c.rollback()
        # A função específica da associação composta também registra a autoria.
        c.execute("INSERT INTO tb_admin_cd VALUES (1,2)")
        assert escalar(c, "SELECT usuario_bd = CURRENT_USER FROM tb_log_auditoria WHERE entidade_afetada='tb_admin_cd' ORDER BY id DESC LIMIT 1")
        c.rollback()

        # DAU: insere somente eventos sintéticos, posteriormente revertidos.
        base = escalar(c, "SELECT COALESCE((SELECT usuarios_ativos FROM vw_dau_diario WHERE data_acesso=DATE '2001-01-01'),0)")
        c.execute("INSERT INTO tb_log_acesso(cod_usuario,tentativa_sucesso,ip_origem,user_agent,data_hora) VALUES (1,true,'127.0.0.1','TESTE_DAU','2001-01-01 10:00'),(1,true,'127.0.0.1','TESTE_DAU','2001-01-01 11:00'),(2,true,'127.0.0.1','TESTE_DAU','2001-01-01 12:00'),(3,false,'127.0.0.1','TESTE_DAU','2001-01-01 13:00'),(1,true,'127.0.0.1','TESTE_DAU','2001-01-02 10:00')")
        assert escalar(c, "SELECT usuarios_ativos FROM vw_dau_diario WHERE data_acesso=DATE '2001-01-01'") == base+2
        assert escalar(c, "SELECT usuarios_ativos FROM vw_dau_diario WHERE data_acesso=DATE '2001-01-02'") == 1
        resultado["dau"] = {"eventos_sinteticos": 5, "usuarios_dia_1": 2, "usuarios_dia_2": 1, "rollback": True, "login_real_comprovado": False}
        c.rollback()

        # Verifica LAG, ROW_NUMBER e média acumulada por termômetro.
        c.execute("INSERT INTO tb_leitura_temperatura(cod_termometro,temperatura,data_hora) VALUES (1,-24,'2001-01-01 08:00'),(1,-22,'2001-01-01 09:00'),(2,1,'2001-01-01 08:00'),(2,3,'2001-01-01 09:00')")
        series = c.execute("SELECT cod_termometro,temperatura_anterior,variacao_desde_leitura_anterior,temperatura_media_acumulada FROM vw_bi_leituras_temperatura WHERE data_hora=TIMESTAMP '2001-01-01 09:00' ORDER BY cod_termometro").fetchall()
        assert [tuple(map(float,r)) for r in series] == [(1.0,-24.0,2.0,-23.0),(2.0,1.0,2.0,2.0)]
        assert escalar(c, "SELECT count(*) FROM (SELECT cod_camara_frigorifica FROM vw_bi_leituras_temperatura WHERE ordem_leitura_mais_recente=1 GROUP BY 1 HAVING count(*)<>1) x") == 0
        c.execute("INSERT INTO tb_lote_camara_frigorifica(cod_lote,cod_camara_frigorifica) VALUES (2,4)")
        lotes=c.execute("SELECT menor_vida_util_camara,total_lotes_ativos_camara FROM vw_bi_lotes_ativos_camara WHERE cod_camara_frigorifica=4").fetchall()
        assert len(lotes)==2 and all(r[1]==2 for r in lotes)
        assert lotes[0][0] == min(r[0] for r in c.execute("SELECT cat.vida_util_horas FROM tb_lote_camara_frigorifica lc JOIN tb_lote l ON l.id=lc.cod_lote JOIN tb_categoria cat ON cat.id=l.cod_categoria WHERE lc.cod_camara_frigorifica=4 AND lc.data_saida IS NULL AND l.status='ATIVO'"))
        alerta=escalar(c,"SELECT id FROM tb_alerta ORDER BY id LIMIT 1")
        c.execute("UPDATE tb_alerta SET nivel_atual='ADMIN' WHERE id=%s",(alerta,))
        assert c.execute("SELECT nivel,percentual_vida_util FROM vw_bi_etapas_escalonamento WHERE cod_alerta=%s ORDER BY ordem_etapa",(alerta,)).fetchall()==[("OPERADOR",0),("GESTOR",40),("ADMIN",70)]
        resultado["views"] = {"leituras": "LAG, media e ordenacao conferidos em dois termometros", "lotes": "dois lotes com minimo e contagem conferidos", "recursiva": [0,40,70]}
        c.rollback()

    # Migração: simula somente a estrutura antiga da autoria, dentro do container.
    psql("ALTER TABLE tb_log_auditoria DROP COLUMN usuario_bd;")
    with psycopg.connect(url) as c:
        quantidade = escalar(c,"SELECT count(*) FROM tb_log_auditoria")
        snapshot = resumo(c)
    psql((SQL / "atualizar-requisitos.sql").read_text(encoding="utf-8"))
    with psycopg.connect(url) as c:
        assert escalar(c,"SELECT count(*) FROM tb_log_auditoria WHERE usuario_bd IS NULL") == quantidade
        assert resumo(c)["contagens"] == snapshot["contagens"]
        c.execute("UPDATE tb_cd SET nome=nome WHERE id=1")
        assert escalar(c,"SELECT usuario_bd=CURRENT_USER FROM tb_log_auditoria ORDER BY id DESC LIMIT 1")
        c.rollback()
    psql((SQL / "atualizar-requisitos.sql").read_text(encoding="utf-8"))
    resultado["migracao"]={"historico_preservado": quantidade, "autoria_historica": None, "nova_autoria": "conferida", "reexecucao": "OK"}

    # Backup e recuperação: arquivo sintético fica apenas no container descartável.
    comando("docker","exec",PG,"pg_dump","-U","postgres","-d","skadi","-Fc","-f","/tmp/skadi-validacao.dump")
    dump_sha=comando("docker","exec",PG,"sha256sum","/tmp/skadi-validacao.dump").split()[0]
    with psycopg.connect(url,autocommit=True) as c:c.execute("CREATE DATABASE skadi_recuperacao")
    comando("docker","exec",PG,"pg_restore","-U","postgres","-d","skadi_recuperacao","--exit-on-error","--single-transaction","--no-owner","--no-privileges","/tmp/skadi-validacao.dump")
    with psycopg.connect(url) as a, psycopg.connect(url.rsplit('/',1)[0]+"/skadi_recuperacao") as b:
        assert resumo(a)==resumo(b)
        b.execute("INSERT INTO tb_cd(nome,cnpj) VALUES ('CD restaurado','99999999999998')")
        assert escalar(b,"SELECT usuario_bd=CURRENT_USER FROM tb_log_auditoria ORDER BY id DESC LIMIT 1")
        b.rollback()
        for tabela in ["tb_cd","tb_usuario","tb_leitura_temperatura"]:
            seq = escalar(b,"SELECT pg_get_serial_sequence(%s,'id')",(tabela,))
            assert escalar(b, psycopg.sql.SQL("SELECT last_value FROM {}").format(psycopg.sql.Identifier(seq.split('.')[1]))) >= escalar(b,psycopg.sql.SQL("SELECT max(id) FROM {}").format(psycopg.sql.Identifier(tabela)))
    resultado["recuperacao"]={"sha256_dump":dump_sha,"contagens_objetos_sequencias": "conferidos", "escrita_e_auditoria_apos_restore": "OK", "roles_globais": "mesmo servidor local; concessoes de producao nao homologadas"}

    # Neo4j: importa o carregador usando SOMENTE env do container local.
    os.environ.update(POSTGRES_HOST="127.0.0.1", POSTGRES_PORT=port, POSTGRES_DB="skadi", POSTGRES_USER="postgres", POSTGRES_PASSWORD="", POSTGRES_SSLMODE="disable", NEO4J_URI=f"bolt://127.0.0.1:{neoport}", NEO4J_USER="neo4j", NEO4J_PASSWORD="teste-isolado-2026", NEO4J_DATABASE="neo4j")
    os.environ["PYTHON_DOTENV_DISABLED"] = "1"
    spec=importlib.util.spec_from_file_location("grafo_teste",ROOT/"databases/neo4j/load_graph.py")
    modulo=importlib.util.module_from_spec(spec);spec.loader.exec_module(modulo)
    driver=GraphDatabase.driver(os.environ["NEO4J_URI"],auth=("neo4j",os.environ["NEO4J_PASSWORD"]))
    with driver.session() as session:
        for stmt in (ROOT/"databases/neo4j/setup.cypher").read_text(encoding="utf-8").split(';'):
            if stmt.strip():session.run(stmt).consume()
        session.run("MERGE (c:CamaraFrigorifica {id:1}) SET c.modelo='OBSOLETO'").consume()
        session.run("MERGE (c:Categoria {id:1}) SET c.temperatura_ideal=999").consume()
    modulo.sync()
    with driver.session() as session:
        antes=session.run("MATCH (n) RETURN count(n) AS n").single()["n"]
        assert session.run("MATCH (c:CamaraFrigorifica) WHERE c.modelo IS NOT NULL RETURN count(c) AS n").single()["n"]==0
        assert session.run("MATCH (c:Categoria) WHERE c.temperatura_ideal IS NOT NULL RETURN count(c) AS n").single()["n"]==0
    modulo.sync()
    with psycopg.connect(url) as c:
        categoria=escalar(c,"SELECT cat.nome FROM tb_categoria cat JOIN tb_lote l ON l.cod_categoria=cat.id JOIN tb_lote_camara_frigorifica lc ON lc.cod_lote=l.id JOIN tb_camara_frigorifica cam ON cam.id=lc.cod_camara_frigorifica JOIN tb_usuario u ON u.cod_cd=cam.cod_cd JOIN tb_alerta a ON a.cod_camara_frigorifica=cam.id JOIN tb_atendimento atd ON atd.cod_alerta=a.id WHERE atd.status IN ('PENDENTE','EM_ANDAMENTO') ORDER BY cat.id LIMIT 1")
    query=(ROOT/"databases/neo4j/queries/traversal.cypher").read_text(encoding="utf-8")
    with driver.session() as session:
        assert session.run("MATCH (n) RETURN count(n) AS n").single()["n"]==antes
        positivo=len(list(session.run(query,categoria_nome=categoria)));assert positivo>0
        tx=session.begin_transaction()
        tx.run("MATCH (a:Atendimento) SET a.status='RESOLVIDO'").consume()
        assert len(list(tx.run(query,categoria_nome=categoria)))==0
        tx.rollback()
        neo_version=session.run("CALL dbms.components() YIELD versions RETURN versions[0] AS v").single()["v"]
    driver.close()
    resultado["neo4j"]={"versao":neo_version,"nos":antes,"traversal_resultados":positivo,"resolvidos_excluidos":True,"reexecucao_sem_duplicacao":True,"propriedades_obsoletas_removidas":True}

    # Desempenho: réplica isolada, nunca remove índices da base funcional.
    with psycopg.connect(url,autocommit=True) as c:c.execute("CREATE DATABASE skadi_desempenho TEMPLATE skadi_recuperacao")
    perfurl=url.rsplit('/',1)[0]+"/skadi_desempenho"
    consultas={
      "ultima_leitura":"SELECT id,temperatura,data_hora FROM tb_leitura_temperatura WHERE cod_termometro=1 ORDER BY data_hora DESC,id DESC LIMIT 1",
      "escalonamento":"SELECT id,nivel_atual,data_hora FROM tb_alerta WHERE status='ATIVO' AND nivel_atual IN ('OPERADOR','GESTOR') ORDER BY data_hora",
      "lotes_ativos":"SELECT cod_lote,cod_camara_frigorifica FROM tb_lote_camara_frigorifica WHERE cod_camara_frigorifica=1 AND data_saida IS NULL"}
    indices=["idx_leitura_termometro_data","idx_alerta_escalonamento","idx_lote_camara_ativos","idx_solicitacao_suporte_usuario_abertura","idx_solicitacao_suporte_responsavel_status"]
    with psycopg.connect(perfurl) as c:
        c.execute("INSERT INTO tb_leitura_temperatura(cod_termometro,temperatura,data_hora) SELECT cam.cod_termometro,(cam.temperatura_min+cam.temperatura_max)/2, CURRENT_TIMESTAMP - ((50001-gs)*INTERVAL '1 second') FROM generate_series(1,50000) gs JOIN tb_camara_frigorifica cam ON cam.id=((gs-1)%45)+1")
        c.commit()
        for indice in indices:c.execute(psycopg.sql.SQL("DROP INDEX IF EXISTS {}").format(psycopg.sql.Identifier(indice)))
        c.execute("ANALYZE");c.commit()
        planos={"sem_indices":{},"com_indices":{}}
        for nome,query in consultas.items():planos["sem_indices"][nome]=escalar(c,"EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) "+query)[0]
        c.execute((SQL/"indices.sql").read_text(encoding="utf-8"));c.commit()
        for nome,query in consultas.items():planos["com_indices"][nome]=escalar(c,"EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) "+query)[0]
        resultado["desempenho"]={"leituras":escalar(c,"SELECT count(*) FROM tb_leitura_temperatura"),"consultas":consultas,"planos":planos,"limite":"execucoes locais pontuais, caches e pequenas tabelas afetam comparacao; nao e benchmark de producao"}

    resultado["resultado"]="Todos os testes acima passaram; integracao de login real fora do escopo."
    EVIDENCIA.parent.mkdir(parents=True,exist_ok=True)
    EVIDENCIA.write_text(json.dumps(resultado,ensure_ascii=False,indent=2),encoding="utf-8")
    print("Validacao concluida:",EVIDENCIA)


if __name__ == "__main__":
    main()
