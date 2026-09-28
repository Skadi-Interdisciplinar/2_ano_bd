# Worker Redis/PostgreSQL

O worker integra o Redis ao fluxo de monitoramento do PostgreSQL.

## Fluxo

1. O produtor publica leituras no Stream `skadi:leituras:temperatura`.
2. O worker consome o Stream usando um consumer group.
3. Leituras fora da faixa da câmara são inseridas em `tb_leitura_temperatura`.
   Leituras normais são inseridas apenas quando representam a recuperação de
   uma câmara com alerta aberto.
4. A inserção no PostgreSQL aciona as triggers existentes: geração do alerta,
   criação do atendimento e registro da notificação inicial.
5. A trigger de novo alerta envia um `NOTIFY` no canal `novo_alerta`.
6. O worker chama `fn_calcular_prazo_escalonamento` para calcular os prazos
   de 40% e 70% e os salva na sorted set `skadi:escalonamentos`.
7. Quando um prazo vence, o worker chama
   `sp_escalonar_alertas_pendentes()`. A procedure atualiza o nível e insere
   as notificações dos usuários correspondentes.
8. As notificações novas são publicadas no Stream
   `skadi:notificacoes:push`, que pode ser consumido pelo serviço de push do
   aplicativo.

## Formato da leitura

O produtor deve publicar estes campos no Stream de temperatura:

```text
id_evento_redis=evt-2026-000001
cod_termometro=1
temperatura=-12.50
data_hora=2026-09-27T10:30:00-03:00
```

`id_evento_redis` garante idempotência. Se a mensagem for reprocessada, a
constraint `uq_leitura_evento_redis` impede uma segunda inserção.

## Execução

1. Copie `.env.example` para `.env` e informe a URL real do PostgreSQL e do
   Redis.
2. Instale as dependências de `requirements.txt`.
3. Execute `python worker.py`.

O usuário PostgreSQL do worker deve ter as permissões definidas em
`databases/postgresql/roles.sql`.

## Responsabilidades

O worker não recria as regras de alerta. A decisão de gerar o alerta,
calcular a gravidade, criar o atendimento e registrar a notificação continua
no PostgreSQL. O Redis fornece fila, temporização e transporte das
notificações para o serviço de push.
