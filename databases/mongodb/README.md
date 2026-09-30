# MongoDB — Skadi

Camada documental do **Skadi**, destinada exclusivamente aos dados gerados e
necessários para o funcionamento da Inteligência Artificial.

## Estrutura de arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `criar_mongodb.py` | Cria as collections, aplica validações e cria índices. |
| `.env.example` | Modelo das variáveis de conexão, sem credenciais reais. |
| `requirements.txt` | Dependências necessárias para executar o script. |

## Responsabilidades

O MongoDB armazena:

- predições produzidas pela IA;
- diagnósticos produzidos pela IA;
- contexto das conversas do assistente;
- registro técnico das execuções dos agentes.

O MongoDB não armazena leituras de temperatura. O Redis recebe e transporta
as leituras pela fila de processamento; o PostgreSQL mantém o histórico
operacional necessário ao fluxo de alertas. Usuários, permissões, câmaras
frigoríficas, alertas e demais dados operacionais pertencem ao PostgreSQL.

## Collections

| Collection | Finalidade |
| --- | --- |
| `predicoes` | Registra temperatura atual, temperatura prevista, horizonte e gravidade de uma predição. |
| `diagnosticos` | Registra hipóteses de causa, evidências, recomendação e confiança associadas a um alerta. |
| `conversas` | Mantém o contexto de cada usuário e suas mensagens incorporadas no mesmo documento. |
| `execucoes_agentes` | Registra agente, início, término, entrada e status de uma execução. |

## Gravidade

O MongoDB não calcula gravidade. Ele armazena o resultado retornado pela
função `fn_calcular_gravidade_alerta` do PostgreSQL, que considera a diferença
absoluta entre a temperatura atual e a temperatura ideal.

| Diferença absoluta | Gravidade armazenada |
| --- | --- |
| até 1 °C | `baixa` |
| até 3 °C | `atenção` |
| até 5 °C | `urgente` |
| acima de 5 °C | `crítica` |

## Integração entre bancos

As connections entre os bancos são responsabilidade das tools e serviços da
IA, não do script de criação das collections:

1. A tool consulta o PostgreSQL para validar o usuário, permissões, alerta e
   demais referências operacionais permitidas.
2. Quando necessário, a tool consulta o Redis para obter leituras de
   temperatura.
3. A IA grava no MongoDB somente o resultado de predição, diagnóstico,
   conversa ou execução de agente.

MongoDB não cria chaves estrangeiras para PostgreSQL ou Redis. A validação de
referências deve ocorrer antes da gravação, na camada da aplicação.

## Execução

1. Copie `.env.example` para `.env` e informe a URL real do MongoDB.
2. Instale as dependências de `requirements.txt`.
3. Execute `python criar_mongodb.py` dentro desta pasta.

O script pode ser executado novamente: ele mantém collections existentes,
reaplica as validações e evita duplicar índices. Ele não apaga collections nem
migra dados automaticamente.

## Validação

O script aplica `validationLevel="strict"` e `validationAction="error"`.
Assim, documentos novos ou alterados que não possuírem os campos obrigatórios
ou tipos esperados são rejeitados pelo MongoDB.

## Segurança

O arquivo `.env` contém credenciais e não deve ser versionado. Use somente o
`.env.example` como modelo compartilhado no repositório.
