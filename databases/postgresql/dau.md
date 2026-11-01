# DAU e integração de acessos

`vw_dau_diario`, definida em `dau.sql`, conta usuários distintos com pelo menos um evento de sucesso em `tb_log_acesso` no dia. Repetições no mesmo dia contam uma vez; falhas e usuários não identificados não contam. O dia é calculado sobre o TIMESTAMP armazenado, conforme a convenção do banco (`America/Sao_Paulo`); não há conversão retrospectiva de fuso na view.

O backend Java ainda precisa inserir esses eventos reais. Após autenticar, deve registrar uma linha por tentativa com comando parametrizado e campos existentes:

| Campo | Origem esperada |
| --- | --- |
| cod_usuario | ID resolvido pelo servidor; NULL se a identidade não for conhecida |
| tentativa_sucesso | Resultado efetivo da autenticação, não informado pelo cliente |
| ip_origem | IP obtido da conexão ou proxy confiável, válido para INET; obrigatório |
| user_agent | Identificação do cliente HTTP; obrigatório |
| motivo_falha | Motivo operacional da falha, sem senha/token; NULL no sucesso |
| data_hora | Omitir do INSERT para usar DEFAULT CURRENT_TIMESTAMP do banco |

A implementação deve garantir persistência do evento de falha mesmo quando a transação de autenticação for revertida e não registrar sucesso antes da autenticação concluída. Eventos do dataload são demonstração: não podem ser apresentados como tráfego real. A view e o banco não capturam logins sozinhos.

O teste em `tests/validar_requisitos.py` insere cinco eventos sintéticos em duas datas: dois sucessos do mesmo usuário, um de outro, uma falha e um sucesso no dia seguinte. Confere DAU 2 e 1 e reverte os eventos. A captura automática no Java e sua comprovação com logins reais continuam pendentes, fora do escopo desta entrega.
