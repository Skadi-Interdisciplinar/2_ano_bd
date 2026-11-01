# Data Mart PostgreSQL

Execute `data-mart.sql` depois de `deploy.sql`, no banco novo. Para um banco já criado, execute somente `data-mart.sql`: ele cria ou atualiza views sem apagar dados. Reexecutar `deploy.sql` recria tabelas e remove dados e views dependentes.

## Modelagem dimensional

A dimensão câmara não possui `modelo`; o modelo do termômetro permanece no cadastro operacional. A definição atual está em `data-mart.sql`. Em banco existente, mudanças de colunas exigem revisar previamente as dependências e preservar ou reaplicar as concessões de leitura da view, caso ela precise ser recriada.

São duas estrelas virtuais no schema `public`, construídas sobre as tabelas operacionais existentes.

| Fato e grão | Dimensões e ligações |
| --- | --- |
| `vw_fato_chamado`: um registro por chamado | `solicitante_id` e `responsavel_id` → `vw_dim_usuario.usuario_id`; `categoria_id` → `vw_dim_categoria_suporte.categoria_id`; `status_id` → `vw_dim_status_suporte.status_id`; datas de abertura/encerramento → `vw_dim_data.data_id` |
| `vw_fato_alerta`: um registro por alerta | `camara_id` → `vw_dim_camara.camara_id`; `gravidade_id` → `vw_dim_gravidade_alerta.gravidade_id`; `status_id` → `vw_dim_status_alerta.status_id`; `data_id` → `vw_dim_data.data_id` |

No BI, use relações muitos-para-um da fato para dimensão. A dimensão câmara inclui CD e nome do CD, mantendo a estrela sem outra dimensão dependente. Use duas cópias lógicas de usuário e de data para os papéis de solicitante/responsável e abertura/encerramento. Responsável e encerramento podem ser nulos: preserve esses chamados com relacionamentos opcionais ou `LEFT JOIN`.

## Métricas e filtros

- Total de chamados/alertas: soma de `quantidade` na respectiva fato.
- Chamados abertos/finalizados: soma de `quantidade_aberta`/`quantidade_finalizada`.
- Tempo médio de resolução: média de `tempo_resolucao_horas`; nulos são excluídos. Apenas chamados `ATENDIDO` com encerramento válido possuem duração.
- Alertas abertos/resolvidos: soma de `quantidade_aberta`/`quantidade_resolvida`.
- Usuários por perfil: contagem direta de `vw_dim_usuario`, agrupada por `nivel_acesso`. Não contar depois de unir com chamados, pois isso duplica usuários.
- Filtros: data, categoria, status, responsável, perfil, câmara, CD e gravidade conforme a estrela utilizada.
- Evolução de chamados: abertura pela `data_abertura_id`; finalizações pela `data_encerramento_id`, filtrando `ATENDIDO`. As datas são filtros distintos.

As views consultam os dados atuais, sem ETL ou refresh. Atualizar a ferramenta de BI refaz a consulta. Perfis, status e gravidades refletem os valores atuais; não permitem reconstruir estados passados. A dimensão data contém somente dias presentes nas fontes; configure um calendário na ferramenta se precisar exibir dias sem eventos. Datas `TIMESTAMP` são mantidas conforme armazenadas pelo sistema em `America/Sao_Paulo`, sem conversão adicional.

Não há CPF, senha, email, descrição ou resposta dos chamados nas views. IDs ainda permitem associação com pessoas: conceda acesso somente à conta de BI autorizada e aplique os filtros de acesso definidos no backend. As views não implementam autorização por usuário/CD. Não conceder acesso público nem usar a conta administrativa na ferramenta.

## Validação antes de disponibilizar

Compare `COUNT(*)` de cada fato com sua tabela fonte, confira a unicidade das chaves das dimensões e compare totais agrupados por status com as fontes. Confira que os joins muitos-para-um preservam a quantidade de fatos e que chamados sem responsável continuam presentes. Compare a média de resolução com uma amostra de chamados encerrados. Verifique também se há `ATENDIDO` sem encerramento; eles contam como finalizados pelo status, mas não entram na média.
