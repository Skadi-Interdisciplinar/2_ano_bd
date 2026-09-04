# PostgreSQL — Skadi

Camada relacional do **Skadi**, responsável pelo armazenamento e gerenciamento dos dados de monitoramento de refrigeradores, geração e atendimento de alertas, auditoria e emissão de relatórios assinados digitalmente.

## Sumário

* [Estrutura de arquivos](#estrutura-de-arquivos)
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
| `script-schemas.sql`          | Criação das tabelas do sistema        |
| `script-catalogo-dados.sql`   | Catálogo de dados e colunas sensíveis |
| `script-functions.sql`        | Funções de cálculo                    |
| `script-procedures.sql`       | Procedures de operação                |
| `script-triggers-negocio.sql` | Triggers das regras de negócio        |
| `script-audit.sql`            | Auditoria, escalonamento e logs       |
| `script-dataload.sql`         | Massa de dados para testes de volume  |

---

## Modelo de dados

### Cadastro

`tb_estado` · `tb_cd` · `tb_endereco` · `tb_usuario` · `tb_termometro` · `tb_produto` · `tb_refrigerador` · `tb_produto_refrigerador`

### Monitoramento e alertas

`tb_leitura_temperatura` · `tb_alerta` · `tb_notificacao_alerta` · `tb_atendimento` · `tb_justificativa`

### Compliance

`tb_relatorio` · `tb_assinatura` · `tb_catalogo_dados`

### Auditoria

`tb_log_auditoria` · `tb_log_escalonamento` · `tb_log_acesso` · `tb_log_acesso_relatorio` · `tb_log_sensor`

---

## Automações

### Geração e atendimento de alertas

Quando uma nova leitura de temperatura é inserida, o banco verifica se ela está fora da faixa permitida para o refrigerador.

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

A gravidade é calculada pela diferença absoluta entre a temperatura registrada e a temperatura ideal do produto.

### Resolução

A inserção de uma justificativa também dispara um fluxo automático:

```text id="x9amso"
justificativa inserida
  → atendimento é marcado como 'resolvido'
  → registra data de resolução
  → alerta correspondente é marcado como 'resolvido'
```

---

## Decisões de design

### `nivel_atual` x `status`

Os campos possuem responsabilidades diferentes:

* **`nivel_atual`** indica o nível responsável pelo alerta: `operador`, `gestor` ou `admin`.
* **`status`** representa a situação do atendimento: `ativo`, `reconhecido` ou `resolvido`.

O `nivel_atual` pode mudar durante o escalonamento sem alterar o status do alerta.

### Múltiplos produtos

Quando um refrigerador possui vários produtos, `tb_produto.tempo_sobrevivencia` utiliza `MIN()`, considerando o menor tempo de sobrevivência.

### Temperatura ideal

Produtos associados ao mesmo refrigerador devem possuir a mesma `temperatura_ideal`.

Essa regra é validada pelo trigger `trg_validar_temperatura_produto_refrigerador`.

### Atendimento pendente

`tb_atendimento.cod_usuario` é opcional, pois o atendimento pode ser criado como `pendente` antes de um usuário assumir o alerta.

### Tipo de alerta

`tb_alerta.tipo` possui como padrão `temperatura_fora_padrao` e permite a inclusão de novos tipos futuramente.

### Gravidade

A gravidade é definida pela diferença absoluta entre a temperatura medida e a temperatura ideal:

| Diferença | Gravidade |
| --------: | --------- |
|    ≤ 1 °C | Baixa     |
|    ≤ 3 °C | Média     |
|    ≤ 5 °C | Alta      |
|    > 5 °C | Crítica   |

---

## Triggers

Os triggers são responsáveis por automatizar regras importantes do fluxo de negócio.

### Geração de alerta

O trigger relacionado às leituras de temperatura verifica automaticamente se a leitura está fora dos parâmetros definidos. Quando necessário, ele aciona a geração do alerta e o fluxo de atendimento.

### Validação de produtos

`trg_validar_temperatura_produto_refrigerador` garante que os produtos associados ao mesmo refrigerador possuam a mesma `temperatura_ideal`.

### Resolução

Quando uma justificativa é inserida, o trigger responsável atualiza automaticamente o atendimento e o alerta correspondente para `resolvido`.

### Auditoria e escalonamento

Triggers específicos registram alterações importantes no banco, incluindo operações sobre usuários e alertas e alterações no `nivel_atual` dos alertas.

---

## Funções e Procedures

### Funções

* **`fn_calcular_gravidade_alerta`** — calcula a gravidade do alerta com base na diferença entre a temperatura medida e a temperatura ideal.
* **`fn_calcular_prazo_escalonamento`** — calcula o prazo necessário para o escalonamento do alerta.

### Procedures

* **`sp_registrar_atendimento`** — realiza o registro de atendimento de um alerta.
* **`sp_notificar_nivel_acesso`** — realiza a notificação dos usuários de determinado nível de acesso.

---

## Auditoria

Operações de `INSERT`, `UPDATE` e `DELETE` em `tb_usuario` e `tb_alerta` são registradas em `tb_log_auditoria`.

Alterações em `tb_alerta.nivel_atual` são registradas em `tb_log_escalonamento`.

Dessa forma, o banco mantém o histórico das principais alterações relacionadas a usuários, alertas e escalonamentos.

---

## Pendências conhecidas

* **Escalonamento automático:** a promoção `operador → gestor → admin` por tempo excedido ainda não é executada diretamente pelo banco. A função `fn_calcular_prazo_escalonamento` fornece o prazo necessário para o mecanismo responsável pelo controle de tempo.
* **Termômetros sem refrigerador:** termômetros sem refrigerador associado não podem receber leituras. Essa situação é bloqueada por `fn_gerar_alerta_por_leitura`.
