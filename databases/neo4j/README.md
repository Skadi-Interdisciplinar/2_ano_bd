# Modelo em Grafo (Neo4j)

Este diretório contém a modelagem em grafo do Skadi, equivalente à camada
relacional do PostgreSQL. O Neo4j é usado para explorar relacionamentos e
responder uma pergunta de negócio por meio de traversal.

## Arquivos

| Arquivo | O que é |
|---|---|
| `setup.cypher` | Cria constraints e índices do grafo. |
| `load_graph.py` | Sincroniza os dados reais do PostgreSQL com o Neo4j Aura. |
| `queries/queries.cypher` | Consultas de visualização e exploração do grafo. |
| `queries/traversal.cypher` | Consultas de negócio que percorrem múltiplos relacionamentos. |
| `diagrams/` | Capturas PNG anteriores das respostas exibidas no Aura; não são evidência desta validação. |

## 1. Modelo de grafo

```text
(Usuario)-[:TRABALHA_NO_CD]->(CD)-[:POSSUI_CAMARA]->(CamaraFrigorifica)
(CamaraFrigorifica)-[:TEM_TERMOMETRO]->(Termometro)
(CamaraFrigorifica)-[:ARMAZENA_LOTE]->(Lote)-[:PERTENCE_A_CATEGORIA]->(Categoria)
(CamaraFrigorifica)-[:GEROU_ALERTA]->(Alerta)-[:POSSUI_ATENDIMENTO]->(Atendimento)
(Atendimento)-[:ATENDIDO_POR]->(Usuario)
(Atendimento)-[:TEM_JUSTIFICATIVA]->(Justificativa)
```

### Entidades principais

| Nó | Representação |
|---|---|
| `CD` | Centro de distribuição. |
| `CamaraFrigorifica` | Câmara que armazena os lotes. |
| `Termometro` | Termômetro associado à câmara. |
| `Lote` | Lote armazenado na câmara. |
| `Categoria` | Categoria do lote e seus parâmetros de temperatura. |
| `Alerta` | Ocorrência de temperatura fora do padrão. |
| `Atendimento` | Tratamento operacional do alerta. |
| `Usuario` | Funcionário relacionado ao CD ou atendimento. |
| `Justificativa` | Justificativa registrada no atendimento. |

## 2. Fonte dos dados

O PostgreSQL continua sendo a fonte oficial e transacional. O arquivo
`load_graph.py` consulta as tabelas principais e replica os dados no Aura.

A origem depende das credenciais configuradas: a validação desta entrega usou
somente uma massa sintética em PostgreSQL e Neo4j locais descartáveis. Não foi
executada carga no Aura nem verificado o conteúdo de um ambiente real.

A câmara contém localização, limites e relacionamentos, sem `modelo`.
O modelo do termômetro permanece em `Termometro.modelo`. Categorias usam
`temperatura_min` e `temperatura_max`, sem `temperatura_ideal`. A sincronização
remove explicitamente as duas propriedades obsoletas dos nós atualizados.
O carregador faz MERGE: não é um mecanismo de exclusão geral de entidades
que já desapareceram da origem.

## 3. Como executar

1. Preencha as variáveis `POSTGRES_*` e `NEO4J_*` no `.env` da raiz do repositório (copiado de `.env.example`).
2. No Aura, execute cada comando de `setup.cypher` separadamente.
3. Instale as dependências:

   ```powershell
   py -m pip install -r databases/neo4j/requirements.txt
   ```

4. Execute a sincronização:

   ```powershell
   py databases/neo4j/load_graph.py
   ```

5. Execute uma consulta por vez dos arquivos em `queries/`.

## 4. Pergunta de negócio com traversal

> Quais usuários trabalham no mesmo CD de uma câmara que armazena lotes de
> determinada categoria e possui um atendimento aberto?

O caminho percorrido é:

```text
Usuario → CD → CamaraFrigorifica → Lote → Categoria
                                  ↓
                                Alerta → Atendimento
```

A consulta em `queries/traversal.cypher` cruza usuários, CDs, câmaras, lotes,
categorias, alertas e atendimentos. Portanto, a resposta depende da travessia
de vários relacionamentos e atende ao requisito de traversal.

Informe o parâmetro `categoria_nome` com um nome existente em Categoria (no
Neo4j Browser, `:param categoria_nome => 'nome existente'`). O filtro considera
apenas atendimentos `PENDENTE` ou `EM_ANDAMENTO`, em maiúsculo conforme o banco.
Os caminhos e relacionamentos permanecem os mesmos. `TRABALHA_NO_CD` representa
o cod_cd operacional do usuário; não representa os CDs administrados por ADMIN
via tb_admin_cd. O traversal mantém a pergunta original, sem expandir esse escopo.

O teste isolado carrega duas vezes, verifica ausência das propriedades antigas,
obtém resultados positivos e testa que atendimentos RESOLVIDO não retornam.
Ver [resultado](../postgresql/evidencias/validacao-requisitos.md) e
[execução reproduzível](../../tests/README.md).

## 5. Estrutura do diretório

```text
neo4j/
├── setup.cypher
├── load_graph.py
├── README.md
├── queries/
│   ├── queries.cypher
│   └── traversal.cypher
└── diagrams/
    ├── query1.png
    ├── query2.png
    └── traversal.png
```
