# Validação isolada dos requisitos

Requer Docker Desktop iniciado e Python com as dependências de `rpa/requirements.txt` e `databases/neo4j/requirements.txt`. Execute a partir da raiz deste repositório. Os nomes abaixo são reservados para bancos descartáveis desta validação; não reutilize containers com dados importantes.

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r rpa/requirements.txt -r databases/neo4j/requirements.txt
docker run -d --name skadi-requisitos-pg-20261101 --label skadi.validation=true -p 127.0.0.1::5432 -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=skadi postgres:17-alpine
docker run -d --name skadi-requisitos-neo-20261101 --label skadi.validation=true -p 127.0.0.1::7687 -e NEO4J_AUTH=neo4j/teste-isolado-2026 -e NEO4J_server_memory_heap_initial__size=256m -e NEO4J_server_memory_heap_max__size=512m -e NEO4J_server_memory_pagecache_size=128m neo4j:5-community
```

A senha acima é exclusivamente de teste local. Aguarde os dois servidores ficarem prontos (`docker logs NOME`). Depois:

```powershell
.venv\Scripts\python.exe tests/validar_requisitos.py
```

O runner exige label de descarte e portas publicadas exclusivamente em loopback. Não aceita URLs externas. Conexões do carregador são sobrescritas com os endpoints locais antes da importação. Nenhuma credencial do ambiente real é usada para conexão.

O teste executa deploy, dataload, Data Mart e migração, audita duas tabelas e a associação de ADMIN, verifica catálogo, views e DAU, restaura dump em `skadi_recuperacao`, carrega o grafo duas vezes e testa traversal positivo/negativo. Cria `skadi_desempenho` para medir EXPLAIN ANALYZE/BUFFERS antes e depois dos cinco índices: somente nesse banco de teste os índices são removidos. Todas as regras de negócio permanecem ativas.

O JSON de evidência só é escrito após todos os testes passarem. Para repetir desde zero, remova e recrie exclusivamente os dois containers descartáveis acima (os bancos auxiliares já existentes impedem repetição parcial):

```powershell
docker rm -f skadi-requisitos-pg-20261101 skadi-requisitos-neo-20261101
```

Esse comando também é a limpeza final. Não há volumes persistentes configurados. O dump fica no container e é descartado com ele; o JSON contém hash, contagens e planos, sem credenciais nem conteúdo pessoal. A validação não homologa configurações, privilégios ou logins de produção.
