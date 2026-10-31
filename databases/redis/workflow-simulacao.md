# Simulação agendada de temperaturas

O workflow `.github/workflows/simulacao-temperaturas.yml` executa um lote a cada cinco minutos e permite execução manual. Cada lote consulta os termômetros associados a câmaras usando uma conexão PostgreSQL, fecha a conexão, gera uma temperatura por termômetro e envia por MQTT. O coletor confirma a gravação no Redis antes de terminar. Não inicia processos infinitos nem executa RPA ou o worker de alertas.

Em Settings → Secrets and variables → Actions do repositório, cadastrar:

- Secret `SKADI_DATABASE_URL`: URL PostgreSQL do banco novo, no formato `postgresql://usuario:senha@host:porta/banco?sslmode=require` (sem prefixo JDBC).
- Secret `REDIS_URL`: URL Redis real, incluindo autenticação e TLS quando aplicável.
- Variáveis opcionais `MQTT_BROKER`, `MQTT_PORT` e `MQTT_TOPIC`: mesmos valores do ambiente de simulação. Os padrões são os já usados pelo simulador local.

O broker padrão é público; usar somente dados sintéticos nessa simulação. O lote usa um subtópico MQTT exclusivo, abaixo do tópico configurado, para evitar que coletores externos registrem as mesmas mensagens. O próprio ciclo assina esse subtópico e utiliza `mqtt_to_redis.py` para gravar no mesmo Stream e chave Redis do projeto. A curva sintética permanece entre -20 °C e -15 °C; não representa temperaturas reais nem foi adaptada aos limites de cada câmara.

Depois de publicar os arquivos na branch padrão, abrir Actions → Simulacao - Temperaturas MQTT e Redis → Run workflow para testar. O agendamento do GitHub pode atrasar; não é monitoramento em tempo real. A configuração de concorrência impede duas execuções simultâneas deste workflow, mas não controla simuladores locais.

O worker precisa permanecer ativo em ambiente separado para processar o Stream e executar escalonamentos. Este workflow gera e coleta leituras; sozinho não processa alertas no PostgreSQL. Falhas parciais deixam as leituras já gravadas no Redis; a execução falha sem apagá-las, e uma nova execução gera um novo lote. O limite de conexões do PostgreSQL continua precisando ser tratado no worker/backend.
