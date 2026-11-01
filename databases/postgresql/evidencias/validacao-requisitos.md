# Evidência dos requisitos de Banco de Dados

Execução iniciada em **01/11/2026, 18:02:14 (-03:00)** por `tests/validar_requisitos.py`, concluída sem falhas. Ambiente: Windows com Docker, PostgreSQL **17.11** e Neo4j **5.26.32**, containers descartáveis e portas locais. Dados exclusivamente sintéticos. Nenhuma conexão ou implantação em banco real.

O [JSON completo](validacao-requisitos.json) registra contagens por tabela, versões, SHA-256 dos scripts executados, consultas e planos reais em `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`. A reprodução está em [tests/README.md](../../../tests/README.md). Os tempos abaixo são desta execução, não previsões para produção.

| Verificação executada | Resultado observado |
| --- | --- |
| Deploy + dataload + Data Mart | 23 tabelas, 2.225 linhas incluindo catálogo e logs, 13 views, 84 constraints, 28 triggers não internos e 21 rotinas; regras ativas |
| Auditoria geral | INSERT/UPDATE/DELETE em tb_cd e tb_usuario: seis eventos, operação e presença de OLD/NEW corretas, CURRENT_USER e remoção de senha/CPF/e-mail conferidos |
| Auditoria da associação | Inserção de tb_admin_cd registra CURRENT_USER pela função específica |
| Migração não destrutiva | 770 registros históricos mantidos sem autoria inventada; contagens preservadas, nova autoria preenchida e reaplicação concluída |
| Catálogo | 141 colunas inventariadas, nenhuma faltante ou obsoleta; tipos, NOT NULL, chaves e constraints conferidos; classificação existente preservada e bloco técnico sem duplicação |
| Views de BI | LAG, variação e média em dois termômetros; última leitura por câmara; dois lotes na mesma câmara com mínimo e contagem; etapas recursivas 0/40/70 |
| DAU | Cinco eventos sintéticos em dois dias produzem 2 e 1 usuários; repetição e falha tratadas; dados do teste revertidos |
| Neo4j | 321 nós após duas cargas sem duplicação de nós; propriedades antigas removidas; traversal retorna quatro caminhos e nenhum quando atendimentos são RESOLVIDO |
| Recuperação | Dump custom restaurado em outro banco; contagens e objetos verificados iguais; sequências selecionadas conferidas; gravação com auditoria após restore validada |

Hash SHA-256 do dump sintético: `c6f2e628045bbd9884f89aa27aba028ad7e01483b5e986f89c6c74a8ad1ff6c0`. O arquivo ficou apenas no container descartável, sem inclusão no Git.

## Desempenho medido

A réplica `skadi_desempenho` recebeu mais 50.000 leituras distribuídas entre 45 câmaras, totalizando **50.117 leituras**, com triggers ativas. Apenas nessa réplica foram removidos os cinco índices de `indices.sql`; PKs e demais índices permaneceram. Depois foram recriados, com ANALYZE nos dois cenários. As três consultas reproduzem as consultas de observação do arquivo, registradas integralmente no JSON.

| Consulta | Sem os cinco índices: execução (ms) | Com índices: execução (ms) |
| --- | ---: | ---: |
| Última leitura do termômetro 1 | 17,687 | 0,427 |
| Alertas ATIVO em OPERADOR/GESTOR | 0,173 | 0,152 |
| Vínculos abertos da câmara 1 | 0,076 | 0,081 |

A primeira consulta passou de varredura sequencial com ordenação para acesso pelo índice de termômetro/data. Alertas e vínculos continuam com varredura sequencial em tabelas pequenas (22 alertas e 45 vínculos). As diferenças de centésimos de milissegundo nessas duas consultas **não demonstram ganho consistente**; a consulta de vínculos ficou ligeiramente mais lenta nesta execução. Uma execução por cenário, cache aquecido e infraestrutura local limitam a comparação. Os dois índices de suporte foram recriados, mas não foram objeto de consulta medida nesta bateria.

## Limites e pendências

- A captura automática de eventos reais de autenticação continua dependente do backend Java; o teste de DAU não comprova login real.
- A análise em [normalizacao.md](../normalizacao.md) documenta dependências e ressalvas; não certifica 3FN estrita para relações com redundâncias identificadas nem exige 5FN sem justificativa.
- A restauração usa o mesmo servidor descartável e `--no-owner --no-privileges`. Não homologa roles globais, grants ou recuperação do serviço gerenciado.
- Frequência, retenção, responsável, RPO e RTO de backup continuam pendentes. Não foi criado agendamento operacional.
- Nenhum banco real ou backend Java foi alterado nos testes.
