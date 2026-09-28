# PostgreSQL — Skadi

Camada relacional do **Skadi**, responsável pelo armazenamento e gerenciamento dos dados de monitoramento de câmaras frigoríficas, geração e atendimento de alertas, auditoria e emissão de relatórios assinados digitalmente.

## Sumário

* [Estrutura de arquivos](#estrutura-de-arquivos)
* [Execução](#execução)
* [Modelo de dados](#modelo-de-dados)
* [Automações](#automações)
* [Decisões de design](#decisões-de-design)
* [Triggers](#triggers)
* [Funções e Procedures](#funções-e-procedures)
* [Auditoria](#auditoria)
* [Pendências conhecidas](#pendências-conhecidas)

---

## Estrutura de arquivos

| Arquivo                       | Responsabilidade                      |
| ----------------------------- | ------------------------------------- |
| `schemas.sql`                 | Criação das tabelas do sistema        |
| `catalogo-dados.sql`          | Catálogo de dados e colunas sensíveis |
| `functions.sql`               | Funções de cálculo                    |
| `procedures.sql`              | Procedures de operação                |
| `triggers.sql`                | Triggers das regras de negócio        |
| `audit.sql`                   | Auditoria, escalonamento e logs       |
| `dataload.sql`                | Massa de dados para testes de volume  |
| `deploy.sql`                  | Execução completa do banco            |

---

## Execução

O `deploy.sql` é o ponto de entrada para a configuração do banco de dados PostgreSQL e executa os demais scripts necessários.

Para configurar o banco, execute:

```text
deploy.sql
```

---

## Modelo de dados

### Cadastro

`tb_estado` · `tb_cd` · `tb_endereco` · `tb_usuario` · `tb_termometro` · `tb_categoria` · `tb_camara_frigorifica` · `tb_lote` · `tb_lote_camara_frigorifica`

### Monitoramento e alertas

`tb_leitura_temperatura` · `tb_alerta` · `tb_notificacao_alerta` · `tb_atendimento` · `tb_justificativa`

### Compliance

`tb_relatorio` · `tb_assinatura` · `tb_catalogo_dados`

### Auditoria

`tb_log_auditoria` · `tb_log_escalonamento` · `tb_log_acesso` · `tb_log_acesso_relatorio` · `tb_log_sensor`

---

## Automações

### Geração e atendimento de alertas

Quando uma nova leitura de temperatura chega pelo Redis e é confirmada no PostgreSQL, o banco verifica se ela está fora da faixa permitida para a câmara frigorífica.

Caso esteja fora do padrão, o fluxo é executado automaticamente:

```text id="9egb2m"
leitura inserida
  → verifica temperatura
  → calcula gravidade
  → cria alerta
  → vincula a leitura
  → cria atendimento 'pendente'
  → notifica usuários 'operador'
```

A gravidade é calculada pela diferença absoluta entre a temperatura registrada e a temperatura ideal comum aos lotes ativos da câmara frigorífica.

### Resolução

A inserção de uma justificativa também dispara um fluxo automático:

```text id="x9amso"
justificativa inserida
  → valida se o atendimento está 'em_andamento'
  → verifica se a última temperatura está normalizada
  → atendimento é marcado como 'resolvido' somente se a câmara estiver normalizada
  → registra data de resolução
  → alerta correspondente é marcado como 'resolvido'
```

---

## Decisões de design

### `nivel_atual` x `status`

Os campos possuem responsabilidades diferentes:

* **`nivel_atual`** indica o nível responsável pelo alerta: `operador`, `gestor` ou `admin`.
* **`status`** representa a situação do atendimento: `ativo`, `reconhecido` ou `resolvido`.

O `nivel_atual` pode mudar durante o escalonamento sem alterar o status do alerta. A procedure `sp_escalonar_alertas_pendentes`, chamada pelo worker, realiza essa mudança; o trigger de auditoria apenas registra a alteração.

### Lotes e categorias

Cada lote pertence a uma única categoria. A tabela `tb_lote_camara_frigorifica` registra a localização atual e o histórico de movimentações do lote entre câmaras frigoríficas.

`tb_categoria` concentra os parâmetros comuns aos lotes: temperatura ideal e vida útil em horas. A validade real fica registrada diretamente em cada lote, e a vida útil da categoria é usada no prazo de escalonamento dos alertas.

O trigger `trg_validar_temperatura_categoria_camara` impede que um lote seja colocado em uma câmara frigorífica cuja faixa não comporte a temperatura ideal da categoria. Categorias diferentes podem compartilhar a câmara quando possuem a mesma temperatura ideal; a vida útil usada no risco é a menor entre os lotes ativos.

### Atendimento pendente

`tb_atendimento.cod_usuario` é opcional, pois o atendimento pode ser criado como `pendente` antes de um usuário assumir o alerta.

### Escopo do usuário

O usuário pertence diretamente a um CD por meio de `tb_usuario.cod_cd`. Como cada câmara frigorífica também pertence a um CD, o acesso e as notificações são resolvidos por esse vínculo, sem uma tabela adicional de cliente ou de atribuição usuário–câmara.

### Tipo de alerta

`tb_alerta.tipo` possui como padrão `temperatura_fora_padrao` e permite a inclusão de novos tipos futuramente.

### Gravidade

A gravidade é definida pela diferença absoluta entre a temperatura medida e a temperatura ideal:

| Diferença | Gravidade |
| --------: | --------- |
|    ≤ 1 °C | Estável   |
|    ≤ 3 °C | Atenção   |
|    ≤ 5 °C | Crítica   |
|    > 5 °C | Urgente   |

---

## Triggers

Os triggers são responsáveis por automatizar regras importantes do fluxo de negócio.

### Geração de alerta

O trigger relacionado às leituras de temperatura verifica automaticamente se a leitura está fora dos parâmetros definidos. Quando necessário, ele aciona a geração do alerta e o fluxo de atendimento.

### Validação de lotes

`trg_validar_temperatura_categoria_camara` valida a compatibilidade entre a categoria do lote e a faixa de temperatura da câmara frigorífica.

### Resolução

Quando uma justificativa é inserida, o trigger verifica se o atendimento está `em_andamento` e se a última temperatura da câmara está dentro da faixa normal. Somente nessas condições o atendimento e o alerta correspondente são atualizados para `resolvido`.

### Auditoria e escalonamento

Triggers específicos registram alterações importantes no banco, incluindo operações sobre usuários e alertas e alterações no `nivel_atual` dos alertas.

---

## Funções e Procedures

### Funções

* **`fn_calcular_gravidade_alerta`** — calcula a gravidade do alerta com base na diferença entre a temperatura medida e a temperatura ideal.
* **`fn_calcular_vida_util_camara`** — identifica a menor vida útil entre os lotes ativos de uma câmara frigorífica.
* **`fn_calcular_prazo_escalonamento`** — calcula o prazo necessário para o escalonamento do alerta.
* **`fn_camara_temperatura_normal`** — verifica se a última leitura da câmara está dentro da faixa permitida.

### Procedures

* **`sp_reconhecer_alerta`** — atribui o usuário ao atendimento pendente e altera o atendimento para `em_andamento`.
* **`sp_notificar_nivel_acesso`** — realiza a notificação dos usuários de determinado nível de acesso.
* **`sp_escalonar_alertas_pendentes`** — avança o alerta de `operador` para `gestor` ou `admin` quando o prazo definido é atingido.

---

## Auditoria

Operações de `INSERT`, `UPDATE` e `DELETE` em `tb_usuario` e `tb_alerta` são registradas em `tb_log_auditoria`.

Alterações em `tb_alerta.nivel_atual` são registradas em `tb_log_escalonamento`.

Dessa forma, o banco mantém o histórico das principais alterações relacionadas a usuários, alertas e escalonamentos.

---

## Pendências conhecidas

* **Escalonamento automático:** a procedure `sp_escalonar_alertas_pendentes` aplica os prazos fixos de 40% e 70% da menor vida útil dos lotes ativos. Ela deve ser chamada por um scheduler da aplicação.
* **Leituras em Redis:** Redis mantém a fila quente no Stream `skadi:leituras:temperatura`. O worker confirma a mensagem somente depois de inserir no PostgreSQL. A tabela `tb_leitura_temperatura` permanece como histórico das leituras anormais e das leituras normais de recuperação, além de ser o ponto de execução dos triggers, atendendo RN22, RN39 e RN40.
* **Fórmula de impacto de sobrevivência:** a planilha deixa RN42 e RN43 como provisórias; o banco usa a vida útil configurada para escalonamento, mas não inventa uma fórmula de impacto enquanto ela não for definida pelo grupo.
