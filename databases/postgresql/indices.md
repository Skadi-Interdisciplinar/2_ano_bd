# Comparação dos índices

## Objetivo

Comparar os planos de execução das consultas de `indices.sql` antes e depois da criação dos cinco índices operacionais. O resultado depende da versão do PostgreSQL, do volume e da distribuição dos dados; não se deve presumir que o otimizador escolherá um índice em tabelas pequenas.

## Como executar

Use somente um banco PostgreSQL descartável. `deploy.sql` apaga e recria tabelas; não o execute em um banco que contenha dados a preservar.

1. Crie um banco de teste vazio e execute `deploy.sql` e `dataload.sql` nele.
2. Registre a quantidade de registros das tabelas consultadas.

   ```sql
   SELECT 'tb_leitura_temperatura' AS tabela, COUNT(*) AS registros FROM tb_leitura_temperatura
   UNION ALL
   SELECT 'tb_alerta', COUNT(*) FROM tb_alerta
   UNION ALL
   SELECT 'tb_lote_camara_frigorifica', COUNT(*) FROM tb_lote_camara_frigorifica
   UNION ALL
   SELECT 'tb_solicitacao_suporte', COUNT(*) FROM tb_solicitacao_suporte;
   ```

3. **Cenário sem os índices:** no banco descartável, execute o bloco abaixo e depois rode somente os cinco comandos `EXPLAIN (ANALYZE, BUFFERS)` de `indices.sql`. Não execute ainda o restante desse arquivo, pois ele recria os índices.

   ```sql
   DROP INDEX IF EXISTS public.idx_leitura_termometro_data;
   DROP INDEX IF EXISTS public.idx_alerta_escalonamento;
   DROP INDEX IF EXISTS public.idx_lote_camara_ativos;
   DROP INDEX IF EXISTS public.idx_solicitacao_suporte_usuario_abertura;
   DROP INDEX IF EXISTS public.idx_solicitacao_suporte_responsavel_status;

   ANALYZE tb_leitura_temperatura;
   ANALYZE tb_alerta;
   ANALYZE tb_lote_camara_frigorifica;
   ANALYZE tb_solicitacao_suporte;
   ```

4. **Cenário com os índices:** execute `indices.sql`. Ele cria os cinco índices, atualiza as estatísticas das tabelas e executa as mesmas cinco consultas.

## Ambiente e volume

| Item | Resultado |
| --- | --- |
| Data da medição | 01/11/2026 |
| Origem da massa | `dataload.sql` |
| `tb_leitura_temperatura` | 117 |
| `tb_alerta` | 22 |
| `tb_lote_camara_frigorifica` | 45 |
| `tb_solicitacao_suporte` | 60 |

## Resultado por consulta

| Índice | Consulta | Plano sem índice | Plano com índice | Tempo sem/com índice | Observação |
| --- | --- | --- | --- | --- | --- |
| `idx_leitura_termometro_data` | 1: última leitura por termômetro | `Seq Scan` + `Sort` | `Index Scan` | 0,053 ms / 0,040 ms | O índice foi escolhido e evitou a ordenação explícita; diferença pequena nesta massa. |
| `idx_alerta_escalonamento` | 2: alertas ativos por nível | `Seq Scan` + `Sort` | `Seq Scan` + `Sort` | 0,111 ms / 0,086 ms | O índice não foi escolhido; 19 das 22 linhas satisfazem o filtro. |
| `idx_lote_camara_ativos` | 3: lotes ativos por câmara | `Seq Scan` | `Seq Scan` | 0,043 ms / 0,043 ms | O índice não foi escolhido; a tabela tem 45 linhas. |
| `idx_solicitacao_suporte_usuario_abertura` | 4: solicitações recentes por usuário | `Seq Scan` + `Sort` | `Index Scan` | 0,065 ms / 0,075 ms | O índice foi escolhido e evitou a ordenação; uma execução ficou 0,010 ms mais lenta. |
| `idx_solicitacao_suporte_responsavel_status` | 5: solicitações por responsável e status | `Seq Scan` | `Index Scan` | 0,074 ms / 0,151 ms | Mesmo filtro nos dois cenários. O índice foi escolhido, mas nesta execução levou 0,077 ms a mais. |

### Conclusão desta medição

A análise foi realizada em um banco de teste recém-criado, carregado com os dados de `dataload.sql`. Embora o dataload tenha mais de 500 registros no total, as tabelas usadas nestas consultas ainda têm poucas linhas: 117 leituras, 22 alertas, 45 vínculos de lote e 60 solicitações de suporte. Nesse cenário, o PostgreSQL preferiu `Seq Scan` para alertas e vínculos de lote, e os planos com índice nas consultas de suporte tiveram tempos medidos maiores. Com tabelas pequenas, esses tempos abaixo de 0,2 ms não demonstram ganho real; a diferença pode ser variação de execução, e a leitura sequencial pode ser mais econômica do que consultar um índice.

Em produção, com volume e frequência de consultas maiores, os índices adequados tendem a reduzir o trabalho de busca e podem melhorar o desempenho. O ganho depende da consulta, da quantidade e distribuição dos dados; deve ser confirmado com medições no ambiente real.

## Planos completos

### Sem índices

```text
Consulta 1 — última leitura por termômetro
Limit  (cost=2.48..2.48 rows=1 width=17) (actual time=0.032..0.033 rows=1.00 loops=1)
  Buffers: shared hit=1
  ->  Sort  (cost=2.48..2.49 rows=3 width=17) (actual time=0.031..0.032 rows=1.00 loops=1)
        Sort Key: data_hora DESC, id DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=1
        ->  Seq Scan on tb_leitura_temperatura lt  (cost=0.00..2.46 rows=3 width=17) (actual time=0.013..0.021 rows=3.00 loops=1)
              Filter: (cod_termometro = 1)
              Rows Removed by Filter: 114
              Buffers: shared hit=1
Planning:
  Buffers: shared hit=24
Planning Time: 0.184 ms
Execution Time: 0.053 ms

Consulta 2 — alertas ativos por nível
Sort  (cost=1.73..1.78 rows=19 width=20) (actual time=0.079..0.082 rows=19.00 loops=1)
  Sort Key: data_hora
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=1
  ->  Seq Scan on tb_alerta a  (cost=0.00..1.33 rows=19 width=20) (actual time=0.024..0.031 rows=19.00 loops=1)
        Filter: (((nivel_atual)::text = ANY ('{OPERADOR,GESTOR}'::text[])) AND ((status)::text = 'ATIVO'::text))
        Rows Removed by Filter: 3
        Buffers: shared hit=1
Planning:
  Buffers: shared hit=23
Planning Time: 0.219 ms
Execution Time: 0.111 ms

Consulta 3 — lotes ativos por câmara
Seq Scan on tb_lote_camara_frigorifica lc  (cost=0.00..1.56 rows=1 width=8) (actual time=0.015..0.021 rows=1.00 loops=1)
  Filter: ((data_saida IS NULL) AND (cod_camara_frigorifica = 1))
  Rows Removed by Filter: 44
  Buffers: shared hit=1
Planning:
  Buffers: shared hit=18
Planning Time: 0.153 ms
Execution Time: 0.043 ms

Consulta 4 — solicitações recentes por usuário
Limit  (cost=3.77..3.78 rows=3 width=23) (actual time=0.037..0.039 rows=3.00 loops=1)
  Buffers: shared hit=3
  ->  Sort  (cost=3.77..3.78 rows=3 width=23) (actual time=0.036..0.037 rows=3.00 loops=1)
        Sort Key: data_hora_abertura DESC
        Sort Method: quicksort  Memory: 25kB
        Buffers: shared hit=3
        ->  Seq Scan on tb_solicitacao_suporte ss  (cost=0.00..3.75 rows=3 width=23) (actual time=0.017..0.026 rows=3.00 loops=1)
              Filter: (cod_usuario_solicitante = 21)
              Rows Removed by Filter: 57
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=23
Planning Time: 0.191 ms
Execution Time: 0.065 ms

Consulta 5 — solicitações por responsável e status
Seq Scan on tb_solicitacao_suporte ss  (cost=0.00..3.90 rows=3 width=23) (actual time=0.021..0.037 rows=10.00 loops=1)
  Filter: ((cod_usuario_responsavel = 1000002) AND ((status)::text = 'EM_ATENDIMENTO'::text))
  Rows Removed by Filter: 50
  Buffers: shared hit=3
Planning:
  Buffers: shared hit=14
Planning Time: 0.209 ms
Execution Time: 0.074 ms
```

### Com índices

```text
Consulta 1 — última leitura por termômetro
Limit  (cost=0.14..0.83 rows=1 width=17) (actual time=0.015..0.016 rows=1.00 loops=1)
  Buffers: shared hit=1 read=1
  ->  Index Scan using idx_leitura_termometro_data on tb_leitura_temperatura lt  (cost=0.14..2.19 rows=3 width=17) (actual time=0.014..0.014 rows=1.00 loops=1)
        Index Cond: (cod_termometro = 1)
        Index Searches: 1
        Buffers: shared hit=1 read=1
Planning:
  Buffers: shared hit=62 read=1
Planning Time: 0.397 ms
Execution Time: 0.040 ms

Consulta 2 — alertas ativos por nível
Sort  (cost=1.73..1.78 rows=19 width=20) (actual time=0.046..0.048 rows=19.00 loops=1)
  Sort Key: data_hora
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=1
  ->  Seq Scan on tb_alerta a  (cost=0.00..1.33 rows=19 width=20) (actual time=0.023..0.029 rows=19.00 loops=1)
        Filter: (((nivel_atual)::text = ANY ('{OPERADOR,GESTOR}'::text[])) AND ((status)::text = 'ATIVO'::text))
        Rows Removed by Filter: 3
        Buffers: shared hit=1
Planning:
  Buffers: shared hit=33 read=1
Planning Time: 0.779 ms
Execution Time: 0.086 ms

Consulta 3 — lotes ativos por câmara
Seq Scan on tb_lote_camara_frigorifica lc  (cost=0.00..1.56 rows=1 width=8) (actual time=0.016..0.021 rows=1.00 loops=1)
  Filter: ((data_saida IS NULL) AND (cod_camara_frigorifica = 1))
  Rows Removed by Filter: 44
  Buffers: shared hit=1
Planning:
  Buffers: shared hit=27 read=1
Planning Time: 0.293 ms
Execution Time: 0.043 ms

Consulta 4 — solicitações recentes por usuário
Limit  (cost=0.14..3.18 rows=3 width=23) (actual time=0.034..0.041 rows=3.00 loops=1)
  Buffers: shared hit=3 read=1
  ->  Index Scan using idx_solicitacao_suporte_usuario_abertura on tb_solicitacao_suporte ss  (cost=0.14..3.18 rows=3 width=23) (actual time=0.032..0.038 rows=3.00 loops=1)
        Index Cond: (cod_usuario_solicitante = 21)
        Index Searches: 1
        Buffers: shared hit=3 read=1
Planning:
  Buffers: shared hit=45 read=2
Planning Time: 0.880 ms
Execution Time: 0.075 ms

Consulta 5 — solicitações por responsável e status
Index Scan using idx_solicitacao_suporte_responsavel_status on tb_solicitacao_suporte ss  (cost=0.14..3.13 rows=3 width=23) (actual time=0.118..0.127 rows=10.00 loops=1)
  Index Cond: ((cod_usuario_responsavel = 1000002) AND ((status)::text = 'EM_ATENDIMENTO'::text))
  Index Searches: 1
  Buffers: shared hit=3 read=1
Planning:
  Buffers: shared hit=3
Planning Time: 0.134 ms
Execution Time: 0.151 ms
```
