# Backup e recuperação do PostgreSQL novo

## Recuperação testada em ambiente descartável

Em 01/11/2026, o runner `tests/validar_requisitos.py` executou pg_dump custom e pg_restore com transação única em outro banco local. Comparou contagens de todas as tabelas públicas, nomes das views, quantidades de constraints, triggers e funções, além de sequências selecionadas e uma gravação com auditoria após a restauração. Resultados e hash do dump estão em [evidencias/validacao-requisitos.md](evidencias/validacao-requisitos.md) e no JSON vinculado.

São dados sintéticos em containers descartáveis. O teste usa `--no-owner --no-privileges` no mesmo servidor local; não comprova restauração de roles globais, grants, conectividade ou acessos em produção. Não foi feito backup nem alteração de banco real. Frequência, retenção, responsável, RPO e RTO continuam pendentes de definição operacional.

## Escopo e preparação

O backup lógico deve incluir todas as tabelas, dados, sequences, funções, triggers e views do banco `skadi`, incluindo auditoria e `tb_controle_rpa`. Ele não inclui Redis nem MongoDB. Os scripts Git permitem reconstruir a estrutura, mas não substituem um backup dos dados.

O responsável operacional, frequência, retenção, perda máxima tolerável (RPO) e tempo máximo de recuperação (RTO) precisam ser definidos pela equipe. Este documento não comprova que existe agendamento ou recuperação automática. Antes de qualquer migração destrutiva, gerar e validar uma cópia. Para falhas entre cópias, a recuperação fica limitada ao último backup válido; recuperação para um instante específico depende de backups/WAL e dos recursos contratados no provedor.

Instalar ferramentas cliente PostgreSQL compatíveis com o servidor. Usar `pg_dump` da mesma versão principal do servidor ou mais recente que o servidor; para restauração, preferir a mesma versão de ferramentas usada no dump e destino compatível. Preparar uma conta autorizada a ler todos os objetos necessários. RLS/permissões insuficientes não podem deixar dados de fora silenciosamente: conferir o resultado e os logs.

Guardar credenciais fora dos comandos e do Git, usando o arquivo de senhas do PostgreSQL (`%APPDATA%\postgresql\pgpass.conf` no Windows) protegido por permissões do sistema. Informar nele host, porta, banco, usuário e senha reais. Não registrar senhas em logs. Configurar `PGSSLMODE` conforme a conexão aprovada e, se exigido, certificado CA.

## Gerar e armazenar a cópia

1. Avisar o responsável e registrar banco, versão do servidor, início e motivo do backup.
2. Definir no terminal `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` e `PGSSLMODE` do banco novo. Os exemplos abaixo pressupõem essas variáveis e o arquivo de senhas configurados.
3. Executar em PowerShell, substituindo o caminho por uma pasta de backup existente e o nome por um identificador único:

```powershell
pg_dump --format=custom --file="D:\backups\skadi_DATA_HORA.dump" --verbose
if ($LASTEXITCODE -ne 0) { throw "Backup falhou; não considerar esta cópia válida." }
pg_restore --list "D:\backups\skadi_DATA_HORA.dump"
if ($LASTEXITCODE -ne 0) { throw "Arquivo de backup inválido." }
Get-FileHash -Algorithm SHA256 -LiteralPath "D:\backups\skadi_DATA_HORA.dump"
```

4. Registrar tamanho, hash SHA-256, horário e resultado. Listar o arquivo confirma sua leitura, mas somente uma restauração de teste confirma sua utilidade.
5. Armazenar a cópia e seu hash em local separado do banco e da máquina de origem, com criptografia e acesso restrito. O dump contém dados pessoais e credenciais da aplicação presentes no banco.
6. Aplicar a retenção aprovada somente depois de conferir novas cópias válidas.

`pg_dump` produz uma visão consistente dos dados durante a cópia, mas mudanças de estrutura devem ser evitadas durante sua execução. Roles globais não fazem parte do dump do banco: documentar/recriar contas e concessões com os scripts de roles revisados; em serviço gerenciado, respeitar os privilégios permitidos pelo provedor. Testar os acessos após restaurar.

## Recuperação de falha

1. Identificar a falha e suspender gravações da API, worker e RPA. Registrar o último evento processado e preservar logs e o banco afetado para diagnóstico.
2. Escolher a última cópia válida e conferir o hash com o registro. Documentar a janela de dados que poderá ser perdida.
3. Criar um banco vazio separado para restauração. Configurar host, porta, SSL e credenciais do destino de recuperação; conferir explicitamente que não é o banco operacional.
4. Restaurar usando o nome real desse banco:

```powershell
pg_restore --dbname=skadi_recuperacao --no-owner --no-privileges --exit-on-error --single-transaction --verbose "D:\backups\skadi_DATA_HORA.dump"
if ($LASTEXITCODE -ne 0) { throw "Restauração falhou; não liberar o banco." }
```

5. Reaplicar no banco recuperado as permissões revisadas para as contas da aplicação, worker e BI. O exemplo omite donos e concessões de propósito para permitir recuperação em ambiente separado. Não executar `deploy.sql` sobre dados restaurados: ele contém exclusões de tabelas.
6. Validar contagens das tabelas contra o registro do backup, constraints, sequences, views dimensionais e consultas básicas. Em ambiente de teste, verificar inserção, auditoria e triggers com rollback, evitando envio real de notificações.
7. Conferir o controle do RPA e reconciliar os dados posteriores ao backup com o legado. Não avançar manualmente o marcador de sucesso para ignorar perdas. Conferir também mensagens Redis pendentes e já confirmadas: registros posteriores à cópia podem ter sido confirmados no Redis e precisar de recuperação pela fonte. A restrição de `id_evento_redis` ajuda a evitar duplicações, mas não recupera eventos perdidos.
8. Após validação e autorização do responsável operacional, apontar os consumidores ao banco recuperado e retomar primeiro os serviços necessários, acompanhando logs, filas e integridade. Preservar o banco anterior até encerrar a análise.
9. Registrar início/fim, cópia utilizada, dados perdidos ou reprocessados, testes e responsável. Confirmar RPO/RTO efetivos e ajustar o procedimento com a equipe.

## Teste periódico

Executar esse fluxo em banco isolado na periodicidade definida pela equipe e após mudanças relevantes no schema. Uma cópia sem restauração testada não deve ser tratada como garantia de recuperação. O agendamento, retenção e testes reais ainda dependem de configuração operacional.
