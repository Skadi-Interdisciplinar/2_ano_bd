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
| `deploy.sql`                  | Criação da estrutura do banco         |
| `data-mart.sql`               | Views dimensionais para BI (alertas e chamados) |
| `data-mart.md`                | Grãos, dimensões, métricas e validação do Data Mart |
| `backup-recuperacao.md`       | Procedimentos de backup lógico e recuperação de falhas |

---

## Execução

O `deploy.sql` cria a estrutura do banco, incluindo tabelas e objetos do sistema. Ele não insere dados de teste.

Para configurar o banco, execute `deploy.sql`. Para carregar os dados de teste, execute `dataload.sql` em seguida, uma única vez, em um banco recém-criado.

```text
deploy.sql
data-mart.sql (camada analítica, após o deploy)
dataload.sql (opcional, depois do deploy)
```

A camada analítica está descrita em [data-mart.md](data-mart.md). Em banco existente, execute apenas `data-mart.sql` para adicionar as views; não reexecute o deploy destrutivo.

Os procedimentos de backup e recuperação de falhas estão em [backup-recuperacao.md](backup-recuperacao.md).

### Massa de dados

A função `fn_gerar_alerta_por_leitura`, mantida em `triggers.sql` e `deploy.sql`, serializa leituras da mesma câmara e só cria alerta se não existir outro `ATIVO` ou `RECONHECIDO`. Em banco existente, atualize apenas a definição da função necessária; não reexecute o deploy destrutivo. Mensagens Redis que falharam anteriormente permanecem pendentes: o loop atual do worker lê apenas mensagens novas (`>`), portanto reiniciá-lo não reprocessa essas pendências automaticamente.

O `dataload.sql` destina-se a um banco recém-criado. Nas tabelas sincronizadas, utiliza o texto do dataload legado fornecido em 31/10/2026, preservando os IDs e adaptando as colunas ao modelo normalizado:

* 27 estados de referência;
* 45 CDs, 45 endereços, 45 termômetros, 45 câmaras, 45 categorias, 45 lotes e 45 vínculos lote/câmara: IDs `1` a `45` do legado;
* 45 usuários do legado: 10 ADMIN, 10 GESTOR e 25 OPERADOR; níveis em maiúsculo. ADMIN fica com `cod_cd` nulo, conforme o schema novo, e os 45 vínculos disponíveis no texto são mantidos em `tb_admin_cd`;
* conta técnica `skadi_worker` no ID `1000001` e os seis SUPER_ADMIN locais nos IDs `1000002` a `1000007`, preservando nomes, usernames, e-mails e hashes anteriores;
* 60 solicitações de suporte: 20 `REGISTRADO`, 20 `EM_ATENDIMENTO` e 20 `ATENDIDO`, usando os usuários presentes;
* amostras operacionais preservadas, com referências aos novos usuários. Leituras anormais de demonstração só são inseridas para câmaras com lote `ATIVO` ainda presente, pois a trigger exige essa referência. Relatórios e logs usam os usernames do legado.

### Registros reservados para testar o RPA

Os IDs `46` a `50` foram omitidos nas oito tabelas sincronizadas. O legado contém esses registros e a carga deve inseri-los, incluindo suas dependências. Os vínculos ADMIN/CD desses CDs também não são criados no dataload, para não gerar referências inexistentes. O RPA atual não sincroniza `admin_cd`.

Depois de uma carga completa compatível com as regras do destino, as oito tabelas devem ter os IDs `1` a `50`; usuários devem totalizar 57, incluindo as sete contas locais. As sequências são ajustadas após os IDs explícitos. A faixa alta de usuários evita colisão com esta massa de 50 registros; não substitui uma estratégia de identidade para crescimento futuro das duas origens.

O RPA converte `Usuario.id_cd` de ADMIN em vínculo em `tb_admin_cd` e grava `tb_usuario.cod_cd` nulo. Vínculos adicionais do destino são preservados; a tabela completa `admin_cd` do legado não é sincronizada.

O Worker usa `WORKER_USER_ID=1000001` como padrão. Caso `.env` ou o ambiente já defina `WORKER_USER_ID`, atualize-o para o ID da conta técnica efetivamente existente. Essa alteração não migra o usuário de um banco em uso.

Validação em PostgreSQL 17 descartável, com deploy, constraints e triggers ativos: dataload concluído; 52 usuários e nenhum operador com gestor inválido; 60 chamados; 117 leituras; 22 alertas; 3 atendimentos reconhecidos e resolvidos; 23 relatórios; 15 assinaturas; 605 eventos de acesso. Esses volumes operacionais dependem dos vínculos e status da massa.

As 45 contas importadas com nível ADMIN, GESTOR ou OPERADOR usam hashes BCrypt válidos da senha `senha123`. As contas SUPER_ADMIN, incluindo a conta técnica do worker, mantêm seus hashes próprios. As assinaturas RSA continuam sendo demonstrações e não usam certificados ICP-Brasil. O `dataload.sql` não limpa nem migra registros existentes: execute-o uma única vez em banco recém-criado. Para testar registros omitidos em destino preparado, use `python rpa/carga_delta.py --completa`; um checkpoint delta existente pode deixar de selecionar registros antigos.

---

## Modelo de dados

### Cadastro

`tb_estado` · `tb_cd` · `tb_endereco` · `tb_usuario` · `tb_admin_cd` · `tb_termometro` · `tb_categoria` · `tb_camara_frigorifica` · `tb_lote` · `tb_lote_camara_frigorifica`

`tb_admin_cd` relaciona ADMINs e CDs. O campo `tb_usuario.cod_cd` fica nulo para ADMIN e SUPER_ADMIN; GESTOR e OPERADOR precisam ter um CD direto. Cada relatório também guarda `cod_cd` próprio, pois o ADMIN que o gera pode administrar vários centros.

### Monitoramento e alertas

`tb_leitura_temperatura` · `tb_alerta` · `tb_notificacao_alerta` · `tb_atendimento` · `tb_justificativa`

### Compliance

`tb_relatorio` · `tb_assinatura` · `tb_catalogo_dados`

### Auditoria

`tb_log_auditoria` · `tb_log_escalonamento` · `tb_log_acesso`

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

Quando uma leitura normal mais recente é inserida para uma câmara com alerta `ATIVO` ainda não reconhecido, o banco resolve automaticamente o alerta e o atendimento pendente, registrando `data_hora_resolucao`. Se o alerta já estiver `RECONHECIDO`, ele permanece aberto para atendimento e justificativa.

A justificativa continua sendo um fluxo separado para registrar a causa e a ação realizada. Ao inserir uma justificativa, o banco:

```text id="x9amso"
justificativa inserida
  → valida se o atendimento está 'em_andamento'
  → verifica se a última temperatura está normalizada
  → se estiver normalizada, marca atendimento e alerta como 'resolvido'
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

### Notificações lidas

`tb_notificacao_alerta` mantém um registro por usuário notificado. `data_hora_envio` registra o envio e `data_hora_leitura` registra quando aquele usuário leu a notificação; `data_hora_leitura` permanece `NULL` enquanto não houver leitura.

### Relatórios e assinaturas

`tb_relatorio.conteudo` guarda o texto integral do relatório e `hash_conteudo` guarda seu hash SHA-256. `tb_assinatura.certificado_publico` guarda a chave pública em Base64 (DER/X.509) usada pela aplicação para verificar a assinatura.

As chaves e assinaturas RSA da massa foram geradas para os relatórios de teste e podem ser usadas para testar a verificação criptográfica da API. Não são certificados ICP-Brasil.

### Escopo do usuário

O usuário pertence diretamente a um CD por meio de `tb_usuario.cod_cd`. Como cada câmara frigorífica também pertence a um CD, o acesso e as notificações são resolvidos por esse vínculo, sem uma tabela adicional de cliente ou de atribuição usuário–câmara.

### Tipo de alerta

`tb_alerta.tipo` possui como padrão `temperatura_fora_padrao` e permite a inclusão de novos tipos futuramente.

### Gravidade

A gravidade é definida pela diferença absoluta entre a temperatura medida e a temperatura ideal:

| Diferença | Gravidade |
| --------: | --------- |
|    ≤ 1 °C | BAIXO    |
|    ≤ 3 °C | ATENCAO  |
|    > 3 °C | CRITICO  |

---

## Triggers

Os triggers são responsáveis por automatizar regras importantes do fluxo de negócio.

### Geração de alerta

O trigger relacionado às leituras de temperatura verifica automaticamente se a leitura está fora dos parâmetros definidos. Quando necessário, ele aciona a geração do alerta e o fluxo de atendimento.

### Validação de lotes

`trg_validar_temperatura_categoria_camara` valida a compatibilidade entre a categoria do lote e a faixa de temperatura da câmara frigorífica.

### Resolução

Uma leitura normal mais recente resolve automaticamente somente alertas `ATIVO` ainda não reconhecidos e seus atendimentos `PENDENTE`. Alertas `RECONHECIDO` permanecem para atendimento; o trigger de justificativa pode resolver um atendimento em andamento quando a câmara está normalizada, além de registrar o motivo e a descrição fornecidos.

### Auditoria e escalonamento

Triggers específicos registram alterações importantes no banco, incluindo operações sobre usuários e alertas e alterações no `nivel_atual` dos alertas.

---

## Funções e Procedures

### Funções

* **`fn_calcular_gravidade_alerta`** — calcula a gravidade do alerta com base na diferença entre a temperatura medida e a temperatura ideal.
* **`fn_calcular_vida_util_camara`** — identifica a menor vida útil entre os lotes ativos de uma câmara frigorífica.
* **`fn_calcular_prazo_escalonamento`** — calcula o prazo necessário para o escalonamento do alerta.

As vidas úteis de categorias e alertas são armazenadas como `INTERVAL HOUR TO MINUTE`; os prazos calculados pelas funções também são intervalos, não números de horas.

* **`fn_camara_temperatura_normal`** — verifica se a última leitura da câmara está dentro da faixa permitida.

### Procedures

* **`sp_reconhecer_alerta`** — atribui o usuário ao atendimento pendente e altera o atendimento para `em_andamento`.
* **`sp_notificar_nivel_acesso`** — realiza a notificação dos usuários de determinado nível de acesso.
* **`sp_escalonar_alertas_pendentes`** — avança o alerta de `operador` para `gestor` ou `admin` quando o prazo definido é atingido.

---

## Auditoria

Operações de `INSERT`, `UPDATE` e `DELETE` nas tabelas de negócio são registradas em `tb_log_auditoria`: CDs, endereços, usuários, vínculos ADMIN–CD, solicitações de suporte, termômetros, categorias, câmaras, lotes, leituras, alertas, notificações, atendimentos, justificativas, relatórios e assinaturas. A tabela de referência `tb_estado`, o controle técnico de cargas RPA, os logs e o catálogo não são auditados.

Cada registro guarda a operação, a tabela, o ID da entidade, o usuário da aplicação (`cod_usuario`, quando informado), o horário e snapshots anterior/novo conforme a operação.

Os snapshots mantêm `username` para facilitar a identificação das alterações e omitem `cpf`, `email`, `senha`, `hash_conteudo`, `conteudo`, `numero_serie`, `carimbo_tempo` e `ip_origem`.

Alterações em `tb_alerta.nivel_atual` continuam sendo registradas em `tb_log_escalonamento`, que mantém o nível anterior, o novo nível e o motivo do escalonamento.

---

## Pendências conhecidas

* **Escalonamento automático:** a procedure `sp_escalonar_alertas_pendentes` aplica os prazos fixos de 40% e 70% da menor vida útil dos lotes ativos. Ela deve ser chamada por um scheduler da aplicação.
* **Leituras em Redis:** Redis mantém a fila quente no Stream `skadi:leituras:temperatura`. O worker confirma a mensagem somente depois de inserir no PostgreSQL. A tabela `tb_leitura_temperatura` permanece como histórico das leituras anormais e das leituras normais de recuperação, além de ser o ponto de execução dos triggers, atendendo RN22, RN39 e RN40.
* **Fórmula de impacto de sobrevivência:** a planilha deixa RN42 e RN43 como provisórias; o banco usa a vida útil configurada para escalonamento, mas não inventa uma fórmula de impacto enquanto ela não for definida pelo grupo.
