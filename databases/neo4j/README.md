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
| `diagramas/` | Capturas PNG das respostas exibidas no Aura. |
| `.env.example` | Modelo das variáveis de conexão. |

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

Assim, o grafo usado nas consultas representa dados reais do projeto, e não
registros criados apenas para simulação.

## 3. Como executar

1. Preencha `databases/neo4j/.env` com a URL do PostgreSQL e as credenciais do
   Neo4j Aura.
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

## 5. Estrutura do diretório

```text
neo4j/
├── setup.cypher
├── load_graph.py
├── .env.example
├── README.md
├── queries/
│   ├── queries.cypher
│   └── traversal.cypher
└── diagrams/
    ├── query1.png
    ├── query2.png
    └── traversal.png
```
