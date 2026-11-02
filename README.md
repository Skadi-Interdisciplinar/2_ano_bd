# Skadi — repositório de bancos de dados

Este repositório reúne os bancos, integrações, scripts e documentação usados pelo projeto Skadi.

## Navegação

| Pasta ou arquivo | Conteúdo |
| --- | --- |
| [`databases/postgresql/`](databases/postgresql/README.md) | Banco relacional, schema, regras, auditoria, BI e massa de dados. |
| [`databases/redis/`](databases/redis/README.md) | Worker, simulador de leituras e fluxo de notificações. |
| [`rpa/`](rpa/README.md) | Carga delta entre o banco legado e o PostgreSQL do Skadi. |
| [`databases/neo4j/`](databases/neo4j/README.md) | Modelo em grafo e sincronização com o PostgreSQL. |
| [`databases/mongodb/`](databases/mongodb/README.md) | Collections usadas pela camada de IA. |
| [`.github/workflows/`](.github/workflows/README.md) | Workflows de automação do GitHub Actions. |
| [`.env.example`](.env.example) | Nomes das variáveis necessárias para configuração local. |

## Começar

1. Copie `.env.example` para `.env` na raiz e preencha somente as variáveis dos serviços que serão utilizados.
2. Para criar um banco PostgreSQL novo, siga a ordem descrita em [`databases/postgresql/README.md`](databases/postgresql/README.md).
3. Para iniciar o fluxo de leituras, configure Redis e execute o worker conforme [`databases/redis/README.md`](databases/redis/README.md).
4. Consulte o README de cada integração antes de executar seus scripts.

Arquivos `.env` contêm credenciais locais e não devem ser versionados. `.env.example` não contém valores secretos.
