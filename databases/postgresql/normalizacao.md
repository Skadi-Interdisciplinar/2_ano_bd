# Normalização e integridade do modelo atual

Análise do schema em `schemas.sql`, `audit.sql` e `catalogo-dados.sql`. A separação de entidades evita repetir descrições de categorias, CDs, usuários e equipamentos em cada evento. Uma PK artificial sozinha não comprova 3FN: é necessário verificar dependências entre os demais atributos.

Na tabela abaixo, `id → demais` significa que o identificador determina os atributos daquela linha. Chaves alternativas só são candidatas completas quando não admitem NULL. UNIQUE com NULL fornece unicidade condicional no PostgreSQL.

| Relação | Chaves e dependências funcionais relevantes | Cardinalidades implementadas |
| --- | --- | --- |
| tb_estado | id e estado são candidatos; cada um determina os demais atributos | Estado 1:N endereços |
| tb_cd | id e cnpj são candidatos; id → nome, cnpj | CD 1:N endereços, câmaras, relatórios e usuários operacionais |
| tb_endereco | id e cep são candidatos pelo UNIQUE atual; id → atributos do endereço e FKs | Cada endereço referencia um estado e um CD; cod_cd não é UNIQUE |
| tb_usuario | id, username e email são candidatos; cpf é UNIQUE anulável; id → dados e perfil | Gestor 1:N operadores, com mesmo CD; ADMIN N:M CD via associação |
| tb_admin_cd | PK (cod_admin, cod_cd); associação sem atributos não chave | ADMIN N:M CD, perfil validado por trigger |
| tb_termometro | id → modelo; modelo não é único | Termômetro 0..1 câmara, 1:N leituras |
| tb_categoria | id e nome são candidatos; id → limites e vida útil | Categoria 1:N lotes |
| tb_camara_frigorifica | id e cod_termometro são candidatos; id → localização, limites e CD | Cada câmara possui um CD e um termômetro |
| tb_lote | id e codigo_lote são candidatos; id → categoria, datas, status | Lote 1:N permanências em câmara |
| tb_lote_camara_frigorifica | id → lote, câmara e datas; o par lote/câmara não é UNIQUE | Histórico N:M entre lotes e câmaras; não há unicidade de permanência aberta |
| tb_leitura_temperatura | id → termômetro, alerta, temperatura e instante; id_evento_redis é UNIQUE anulável | Termômetro 1:N leituras, alerta opcional |
| tb_alerta | id → câmara, referência de vida útil, nível, tipo, gravidade, status e instante | Câmara 1:N alertas; referência temporal preservada como snapshot |
| tb_notificacao_alerta | id → alerta, usuário e instantes; par alerta/usuário não é UNIQUE | Alerta e usuário 1:N notificações |
| tb_atendimento | id → alerta, usuário, status e instantes; cod_alerta não é UNIQUE | Alerta 1:N atendimentos no schema, usuário opcional |
| tb_justificativa | id → atendimento, motivo, descrição, instante | Atendimento 1:N justificativas |
| tb_relatorio | id → autor, CD, período, conteúdo, hash, status e geração | Autor e CD 1:N relatórios |
| tb_assinatura | id → relatório e metadados criptográficos | Relatório 1:N assinaturas; número de série não é UNIQUE |
| tb_solicitacao_suporte | id → solicitante, responsável, categoria, textos, status e instantes | Usuários 1:N chamados em cada papel; responsável opcional |
| tb_controle_rpa | nome_carga → ultima_execucao_sucesso | Um checkpoint por nome de carga |
| tb_log_acesso | id → usuário, sucesso, origem, cliente, falha e instante | Usuário opcional, 1:N eventos |
| tb_log_auditoria | id → ator da aplicação, usuário BD, operação, entidade, snapshots e instante | Histórico independente; cod_usuario não tem FK para preservar referências históricas |
| tb_log_escalonamento | id → alerta, níveis, motivo e instante | Alerta 1:N mudanças |
| tb_catalogo_dados | id e (nome_tabela, nome_coluna) são candidatos; par → metadados | Uma entrada por coluna inventariada |

Os campos são atômicos para seus usos operacionais (1FN); snapshots JSONB são documentos históricos deliberados, sem uso como substituto de relações operacionais. A única PK composta operacional, tb_admin_cd, não contém atributos com dependência parcial (2FN). No catálogo, os metadados dependem do par completo tabela/coluna.

A separação entre cadastro, relacionamento e evento segue 3FN para as dependências identificadas, com ressalvas explícitas:

- Em operadores, `cod_gestor → cod_cd` cria uma dependência transitiva condicionada ao perfil. O CD é mantido no usuário para escopo e a FK composta garante a igualdade. É redundância controlada, não uma comprovação de 3FN estrita dessa relação. Removê-la exigiria alterar o contrato da aplicação, fora deste trabalho.
- Conteúdo/hash do relatório são persistidos juntos para integridade; a relação entre eles é derivada por função, não uma chave alternativa declarada. A vida útil no alerta é um snapshot do momento da ocorrência, não uma cópia que deva acompanhar alterações posteriores da categoria.
- Metadados de certificado podem se repetir entre assinaturas. O schema não declara chave de certificado nem verifica dependências entre emissor, série, titular e chave pública. Uma afirmação de 3FN estrita desse conjunto exige analisar essas dependências e eventual entidade própria de certificado; isso não foi imposto nesta entrega.
- O UNIQUE de CEP é uma restrição do projeto atual, não uma regra universal de endereços. Não se deduzem dependências CEP → rua/cidade nem um endereço único por CD além do que foi declarado.
- Os limites de temperatura de câmara e categoria descrevem entidades distintas e são validados por regras de compatibilidade; não são atributos intercambiáveis.

Não foi identificada uma dependência de junção que justifique exigir 5FN ou decompor novas relações nesta entrega. Outras dependências de negócio exigem confirmação antes de qualquer mudança estrutural.

Os testes isolados executam deploy e dataload com constraints e triggers ativas; isso comprova consistência da massa testada, não prova formalmente todas as dependências possíveis. Planos, volume e tempos reais estão em [evidencias/validacao-requisitos.md](evidencias/validacao-requisitos.md).
