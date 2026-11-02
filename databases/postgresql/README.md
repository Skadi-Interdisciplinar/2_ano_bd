# PostgreSQL — Skadi

Camada relacional do **Skadi**, responsável pelo armazenamento e gerenciamento dos dados de monitoramento de câmaras frigoríficas, geração e atendimento de alertas, auditoria e emissão de relatórios assinados digitalmente.

## Sumário

* [Estrutura de arquivos](#estrutura-de-arquivos)
* [Execução](#execução)
* [Modelo de dados](#modelo-de-dados)
* [Automações](#automações)
* [Decisões de design](#decisões-de-design)
* [Validações automáticas](#validações-automáticas)
* [Funções e Procedures](#funções-e-procedures)
* [Auditoria](#auditoria)

---

## Estrutura de arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `schemas.sql` | Definição das tabelas, chaves e constraints. |
| `functions.sql` | Funções de cálculo e consulta usadas pelas regras. |
| `procedures.sql` | Procedures de alertas, notificações e cadastro de usuários. |
| `triggers.sql` | Triggers de negócio e validação. |
| `audit.sql` | Estruturas e funções de auditoria. |
| `catalogo-dados.sql` | Metadados das tabelas e colunas. |
| `dau.sql` | View de usuários ativos por dia a partir de `tb_log_acesso`. |
| `etl-transformacoes.sql` | Views com CTEs, funções de janela e CTE recursiva. |
| `indices.sql` | Índices de apoio às consultas do sistema. |
| [`indices.md`](indices.md) | Procedimento e resultados da comparação dos planos com e sem índices. |
| `roles.sql` | Roles técnicas e privilégios do banco. |
| `deploy.sql` | Script consolidado e destrutivo para recriar a estrutura inicial. |
| `dataload.sql` | Massa de dados de demonstração para banco recém-criado. |
| `data-mart.sql` | Views dimensionais de BI para alertas e chamados. |
| [`data-mart.md`](data-mart.md) | Grãos, dimensões, métricas e validação do Data Mart. |
| [`backup-recuperacao.md`](backup-recuperacao.md) | Procedimentos documentados de backup e recuperação. |

---

## Execução

### Banco novo

`deploy.sql` recria as tabelas e os objetos consolidados do PostgreSQL. Ele contém operações `DROP` e deve ser usado somente para inicializar ou reconstruir um banco descartável.

1. Execute `deploy.sql`.
2. Execute `dataload.sql` uma única vez se precisar da massa de demonstração.
3. Execute `data-mart.sql` para criar as views dimensionais de BI.

O `deploy.sql` já inclui as funções, procedures, triggers, auditoria, catálogo, view DAU, views de transformação, índices e privilégios técnicos definidos nos arquivos individuais. Os arquivos individuais documentam esses componentes; não é necessário executá-los novamente depois do deploy.

### Banco existente

Não execute `deploy.sql` nem `dataload.sql` em um banco com dados que devam ser preservados. O repositório não fornece uma migração para atualizar bancos existentes; qualquer mudança de schema precisa de um script revisado e backup prévio. Para criar ou atualizar somente as views dimensionais, execute `data-mart.sql`.

Consulte [data-mart.md](data-mart.md), [backup-recuperacao.md](backup-recuperacao.md) e [indices.md](indices.md) para os documentos de apoio.

### Massa de dados

`dataload.sql` carrega uma massa de demonstração em um banco recém-criado; execute-o uma única vez. Ele não limpa nem migra dados existentes.

| Tabela ou conjunto | Registros após a carga |
| --- | ---: |
| `tb_estado` | 27 |
| `tb_cd`, `tb_endereco`, `tb_termometro`, `tb_camara_frigorifica`, `tb_categoria`, `tb_lote`, `tb_lote_camara_frigorifica` | 45 em cada tabela |
| `tb_admin_cd` | 45 |
| `tb_usuario` | 52 |
| `tb_solicitacao_suporte` | 60 |
| `tb_leitura_temperatura` | 117 |
| `tb_alerta` | 22 |
| `tb_relatorio` | 23 |
| `tb_assinatura` | 15 |
| `tb_log_acesso` | 605 |

As contas de demonstração `ADMIN`, `GESTOR` e `OPERADOR` usam hashes BCrypt da senha `senha123`. As contas `SUPER_ADMIN` e `skadi_worker` mantêm hashes próprios. As assinaturas RSA são dados de teste, sem certificados ICP-Brasil. Leituras anormais são carregadas apenas para câmaras com lote ativo, conforme exigido pela regra de geração de alertas.

### Integração com RPA e worker

Os IDs `46` a `50` das tabelas sincronizadas ficam reservados para testes do RPA e não são inseridos pelo dataload. Na importação, o RPA deriva os vínculos ADMIN–CD de `Usuario.id_cd` e os grava em `tb_admin_cd`; não copia a tabela legada `admin_cd`. A conta do worker usa o ID `1000001`, configurado por padrão em `WORKER_USER_ID`; ajuste essa variável se o banco de teste usar outro ID.

---

## Modelo de dados

### Cadastro e integração

`tb_estado` · `tb_cd` · `tb_endereco` · `tb_usuario` · `tb_admin_cd` · `tb_termometro` · `tb_categoria` · `tb_camara_frigorifica` · `tb_lote` · `tb_lote_camara_frigorifica` · `tb_controle_rpa`

### Suporte

`tb_solicitacao_suporte`

### Monitoramento e alertas

`tb_leitura_temperatura` · `tb_alerta` · `tb_notificacao_alerta` · `tb_atendimento` · `tb_justificativa`

### Compliance

`tb_relatorio` · `tb_assinatura` · `tb_catalogo_dados`

### Auditoria

`tb_log_auditoria` · `tb_log_escalonamento` · `tb_log_acesso`

---

## Automações

### Alertas e notificações

Quando uma leitura é inserida em `tb_leitura_temperatura` — normalmente pelo worker após consumir uma mensagem Redis — o banco verifica se ela está fora da faixa permitida para a câmara frigorífica.

Caso esteja fora do padrão, o fluxo é executado automaticamente:

```text
leitura inserida
  → verifica temperatura
  → calcula gravidade e vida útil de referência
  → cria alerta ATIVO
  → vincula a leitura e cria atendimento PENDENTE
  → cria notificações para OPERADOR do CD
  → publica o prazo de escalonamento via pg_notify
```

O worker acompanha o prazo publicado no canal `VOVO_ALERTA`. Ao atingir os limites de 40% e 70% da vida útil de referência, `sp_escalonar_alertas_pendentes` avança o nível do alerta e notifica o próximo nível.

### Resolução

Quando uma leitura normal mais recente é inserida para uma câmara com alerta `ATIVO` ainda não reconhecido, o banco resolve automaticamente o alerta e o atendimento `PENDENTE`, registrando `data_hora_resolucao`. Se o alerta já estiver `RECONHECIDO`, ele permanece aberto para atendimento e justificativa.

A justificativa continua sendo um fluxo separado para registrar a causa e a ação realizada. Ao inserir uma justificativa, o banco:

```text
justificativa inserida
  → valida se o atendimento está EM_ANDAMENTO
  → verifica se a última temperatura está normalizada
  → se estiver normalizada, marca atendimento e alerta como RESOLVIDO
```

---

## Decisões de design

### `nivel_atual` x `status`

Os campos possuem responsabilidades diferentes:

* **`nivel_atual`** indica o nível responsável pelo alerta: `OPERADOR`, `GESTOR` ou `ADMIN`.
* **`status`** representa a situação do alerta: `ATIVO`, `RECONHECIDO` ou `RESOLVIDO`.

O `nivel_atual` pode mudar durante o escalonamento sem alterar o status do alerta. A procedure `sp_escalonar_alertas_pendentes`, chamada pelo worker, realiza essa mudança; o trigger de auditoria apenas registra a alteração.

### Lotes e categorias

Cada lote pertence a uma única categoria. A tabela `tb_lote_camara_frigorifica` registra a localização atual e o histórico de movimentações do lote entre câmaras frigoríficas.

`tb_categoria` concentra a faixa de temperatura (`temperatura_min` e `temperatura_max`) e a vida útil dos lotes. A validade real fica registrada diretamente em cada lote, e a vida útil da categoria é usada no prazo de escalonamento dos alertas.

O trigger `trg_validar_temperatura_categoria_camara` impede que um lote seja colocado em uma câmara frigorífica cuja faixa não comporte a faixa da categoria. Categorias diferentes podem compartilhar a câmara quando suas faixas são compatíveis; a vida útil usada no risco é a menor entre os lotes ativos.

### Atendimento pendente

`tb_atendimento.cod_usuario` é opcional, pois o atendimento pode ser criado como `PENDENTE` antes de um usuário assumir o alerta.

### Notificações lidas

`tb_notificacao_alerta` mantém um registro por usuário notificado. `data_hora_envio` registra o envio e `data_hora_leitura` registra quando aquele usuário leu a notificação; `data_hora_leitura` permanece `NULL` enquanto não houver leitura.

### Relatórios e assinaturas

`tb_relatorio.conteudo` guarda o texto integral do relatório e `hash_conteudo` guarda seu hash SHA-256. `tb_assinatura.certificado_publico` guarda a chave pública em Base64 (DER/X.509) usada pela aplicação para verificar a assinatura.

As chaves e assinaturas RSA da massa foram geradas para os relatórios de teste e podem ser usadas para testar a verificação criptográfica da API. Não são certificados ICP-Brasil.

### Escopo do usuário

GESTOR e OPERADOR possuem vínculo direto com um CD em `tb_usuario.cod_cd`. ADMIN pode administrar vários CDs por meio de `tb_admin_cd`, e seu `cod_cd` fica nulo. SUPER_ADMIN também não possui CD. Cada câmara pertence a um CD; relatórios guardam seu próprio `cod_cd` para preservar o escopo do centro ao qual pertencem.

### Perfis de acesso

`sys_database_admin` e `skadi_worker` são roles técnicas do PostgreSQL, definidas em `roles.sql`. `SUPER_ADMIN`, `ADMIN`, `GESTOR` e `OPERADOR` são níveis da aplicação, armazenados em `tb_usuario.nivel_acesso`.

### Tipo de alerta

`tb_alerta.tipo` possui como padrão `TEMPERATURA_FORA_PADRAO`.

### Gravidade

A gravidade é definida pelo quanto a temperatura medida ultrapassa o limite permitido da câmara:

| Desvio além do limite | Gravidade |
| --------: | --------- |
|    ≤ 1 °C | BAIXO    |
|    ≤ 3 °C | ATENCAO  |
|    > 3 °C | CRITICO  |

---

## Validações automáticas

* Usuários: exige CPF para níveis diferentes de `SUPER_ADMIN`; `OPERADOR` precisa de um `GESTOR` do mesmo CD.
* Vínculo ADMIN–CD: só aceita usuário `ADMIN` sem CD direto.
* Solicitações de suporte: valida o responsável `SUPER_ADMIN`, os campos exigidos por status e a ordem das transições.
* Lotes: valida a compatibilidade entre a faixa de temperatura da categoria e a da câmara; detalhes em [Lotes e categorias](#lotes-e-categorias).

Os triggers de auditoria estão descritos em [Auditoria](#auditoria).

---

## Funções e Procedures

### Funções

* **`fn_calcular_gravidade_alerta`** — calcula a gravidade conforme o desvio da leitura além do limite permitido para a câmara.
* **`fn_calcular_vida_util_camara`** — identifica a menor vida útil entre os lotes ativos de uma câmara frigorífica.
* **`fn_calcular_prazo_escalonamento`** — calcula o prazo necessário para o escalonamento do alerta.

As vidas úteis de categorias e alertas são armazenadas como `INTERVAL HOUR TO MINUTE`; os prazos calculados pelas funções também são intervalos, não números de horas.

* **`fn_camara_temperatura_normal`** — verifica se a última leitura da câmara está dentro da faixa permitida.

### Procedures

* **`sp_reconhecer_alerta`** — atribui o usuário ao atendimento pendente e altera o atendimento para `EM_ANDAMENTO`.
* **`sp_notificar_nivel_acesso`** — realiza a notificação dos usuários de determinado nível de acesso.
* **`sp_escalonar_alertas_pendentes`** — avança o alerta de `OPERADOR` para `GESTOR` ou `ADMIN` quando o prazo definido é atingido.
* **`sp_cadastrar_usuario`** — valida o nível e o CD do executor antes de cadastrar um usuário.

---

## Auditoria

Operações de `INSERT`, `UPDATE` e `DELETE` nas tabelas de negócio são registradas em `tb_log_auditoria`: CDs, endereços, usuários, vínculos ADMIN–CD, solicitações de suporte, termômetros, categorias, câmaras, lotes, leituras, alertas, notificações, atendimentos, justificativas, relatórios e assinaturas. A tabela de referência `tb_estado`, o controle técnico de cargas RPA, os logs e o catálogo não são auditados.

`tb_log_acesso` armazena os acessos registrados pela aplicação. `vw_dau_diario`, definida em `dau.sql`, calcula a quantidade diária de usuários distintos com acesso bem-sucedido.

Cada registro guarda a operação, a tabela, o ID da entidade, o usuário da aplicação (`cod_usuario`, quando informado), a role da conexão (`usuario_bd`, CURRENT_USER), o horário e snapshots anterior/novo conforme a operação. Na atualização de banco existente, usuario_bd permanece NULL nos registros históricos.

Os snapshots mantêm `username` para facilitar a identificação das alterações e omitem `cpf`, `email`, `senha`, `hash_conteudo`, `conteudo`, `numero_serie`, `carimbo_tempo` e `ip_origem`.

Alterações em `tb_alerta.nivel_atual` continuam sendo registradas em `tb_log_escalonamento`, que mantém o nível anterior, o novo nível e o motivo do escalonamento.
