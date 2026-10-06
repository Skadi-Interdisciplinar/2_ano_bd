-- ====================================================================
-- LIMPEZA E CRIAÇÃO DA TABELA
-- Tabela centralizadora do Catálogo de Dados corporativo.
-- Armazena o inventário de metadados, regras de negócio e mapeamento de segurança.
-- Serve para auditoria, controle de LGPD e documentação técnica unificada.
-- ====================================================================
DROP TABLE IF EXISTS tb_catalogo_dados;


CREATE TABLE tb_catalogo_dados (
	id SERIAL,
	nome_tabela VARCHAR(100) NOT NULL,
	nome_coluna VARCHAR(100) NOT NULL,
	tipo_dado VARCHAR(50) NOT NULL,
	obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
	chave VARCHAR(2),
	descricao TEXT NOT NULL,
	regra_negocio TEXT,
	nivel_acesso_leitura VARCHAR(8) NOT NULL DEFAULT 'OPERADOR',
	dado_sensivel BOOLEAN NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_catalogo_dados PRIMARY KEY (id),
	CONSTRAINT uq_catalogo_tabela_coluna UNIQUE (nome_tabela, nome_coluna),
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK','NK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('OPERADOR', 'GESTOR', 'ADMIN'))
);


-- ====================================================================
-- CARGA DE DADOS DO CATÁLOGO
-- ====================================================================
INSERT INTO tb_catalogo_dados (nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave, descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel) VALUES

-- ==============================================
-- tb_estado
-- ==============================================
('tb_estado', 'estado', 'CHAR(2)', TRUE, 'NK', 'Sigla da unidade federativa', 'Única no sistema; armazenada no padrão de duas letras', 'OPERADOR', FALSE),

-- ==============================================
-- tb_cd
-- ==============================================
('tb_cd', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do centro de distribuição', NULL, 'OPERADOR', FALSE),
('tb_cd', 'cnpj', 'VARCHAR(14)', TRUE, 'NK', 'CNPJ do centro de distribuição', 'Único no sistema, sem formatação (apenas dígitos)', 'GESTOR', FALSE),

-- ==============================================
-- tb_usuario
-- ==============================================
('tb_usuario', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do funcionário', NULL, 'OPERADOR', FALSE),
('tb_usuario', 'username', 'VARCHAR(50)', TRUE, 'NK', 'Nome de usuário para autenticação', 'Único no sistema; usado no login da aplicação', 'ADMIN', TRUE),
('tb_usuario', 'cpf', 'VARCHAR(11)', TRUE, 'NK', 'CPF do funcionário', 'Único no sistema; dado pessoal protegido por LGPD', 'ADMIN', TRUE),
('tb_usuario', 'email', 'VARCHAR(255)', TRUE, 'NK', 'E-mail do funcionário', 'Único no sistema; usado para login e notificações', 'ADMIN', TRUE),
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, NULL, 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'ADMIN', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(11)', TRUE, NULL, 'Cargo do funcionário no sistema', 'Níveis: OPERADOR, GESTOR, ADMIN e SUPER_ADMIN; acessos técnicos ao banco são controlados por roles PostgreSQL', 'GESTOR', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o funcionário pertence', 'Referencia tb_cd(id)', 'OPERADOR', FALSE),
('tb_usuario', 'cod_gestor', 'INTEGER', FALSE, 'FK', 'Gestor responsável pelo funcionário', 'Opcional; deve referenciar um usuário com nível gestor e do mesmo CD', 'GESTOR', FALSE),

-- ==============================================
-- tb_categoria
-- ==============================================
('tb_categoria', 'nome', 'VARCHAR(150)', TRUE, 'NK', 'Categoria de armazenamento', 'Única no sistema; concentra os parâmetros comuns aos lotes', 'OPERADOR', FALSE),
('tb_categoria', 'temperatura_min', 'DECIMAL(5,2)', TRUE, NULL, 'Limite mínimo de temperatura da categoria', 'Deve ser maior ou igual ao limite mínimo da câmara para que o lote possa ser armazenado nela', 'OPERADOR', FALSE),
('tb_categoria', 'temperatura_max', 'DECIMAL(5,2)', TRUE, NULL, 'Limite máximo de temperatura da categoria', 'Deve ser menor ou igual ao limite máximo da câmara para que o lote possa ser armazenado nela', 'OPERADOR', FALSE),
('tb_categoria', 'vida_util_horas', 'DECIMAL(7,2)', TRUE, NULL, 'Vida útil da categoria em horas', 'Base direta do escalonamento do alerta', 'OPERADOR', FALSE),

-- ==============================================
-- tb_lote
-- ==============================================
('tb_lote', 'codigo_lote', 'VARCHAR(50)', TRUE, 'NK', 'Identificador operacional do lote', 'Único no sistema', 'OPERADOR', FALSE),
('tb_lote', 'cod_categoria', 'INTEGER', TRUE, 'FK', 'Categoria do lote', 'Cada lote pertence a exatamente uma categoria', 'OPERADOR', FALSE),
('tb_lote', 'data_fabricacao', 'DATE', TRUE, NULL, 'Data de fabricação do lote', 'Usada para rastreabilidade', 'OPERADOR', FALSE),
('tb_lote', 'data_validade', 'DATE', TRUE, NULL, 'Data de validade do lote', 'Deve ser igual ou posterior à fabricação', 'OPERADOR', FALSE),

-- ==============================================
-- tb_lote_camara_frigorifica
-- ==============================================
('tb_lote_camara_frigorifica', 'cod_lote', 'INTEGER', TRUE, 'FK', 'Lote movimentado', 'Um lote pode passar por várias câmaras frigoríficas ao longo do tempo', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica do lote', 'Apenas uma localização atual pode ficar aberta por lote', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'data_entrada', 'TIMESTAMP', TRUE, NULL, 'Entrada do lote na câmara frigorífica', 'Início do período de armazenamento', 'OPERADOR', FALSE),
('tb_lote_camara_frigorifica', 'data_saida', 'TIMESTAMP', FALSE, NULL, 'Saída do lote da câmara frigorífica', 'NULL indica a localização atual', 'OPERADOR', FALSE),

-- ==============================================
-- tb_camara_frigorifica
-- ==============================================
('tb_camara_frigorifica', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado na câmara frigorífica', 'Relação 1:1 — cada termômetro pertence a exatamente uma câmara frigorífica (UNIQUE)', 'OPERADOR', FALSE),

-- ==============================================
-- tb_alerta
-- ==============================================
('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, NULL, 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'OPERADOR', FALSE),
('tb_alerta', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica que originou o alerta', 'Todo alerta pertence à câmara que originou a ocorrência', 'OPERADOR', FALSE),
('tb_alerta', 'vida_util_referencia_horas', 'DECIMAL(7,2)', FALSE, NULL, 'Menor vida útil entre os lotes ativos no momento do alerta', 'Base dos prazos fixos de escalonamento', 'GESTOR', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, NULL, 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ATIVO/RECONHECIDO/RESOLVIDO), nivel_atual é sobre o cargo responsável', 'OPERADOR', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, NULL, 'Gravidade do alerta', 'Calculada via fn_calcular_gravidade_alerta: BAIXA, ATENCAO, URGENTE ou CRITICA', 'OPERADOR', FALSE),
('tb_alerta', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento de criação do alerta', 'Usado como referência para o escalonamento', 'OPERADOR', FALSE),
('tb_alerta', 'tipo', 'VARCHAR(100)', TRUE, NULL, 'Tipo da ocorrência', 'Atualmente limitado a TEMPERATURA_FORA_PADRAO', 'OPERADOR', FALSE),

-- ==============================================
-- tb_notificacao_alerta
-- ==============================================
('tb_notificacao_alerta', 'cod_alerta', 'INTEGER', TRUE, 'FK', 'Alerta notificado', 'Relaciona a notificação ao alerta correspondente', 'OPERADOR', FALSE),
('tb_notificacao_alerta', 'cod_usuario', 'INTEGER', TRUE, 'FK', 'Usuário notificado', 'Usuário do mesmo CD e nível de acesso do escalonamento', 'OPERADOR', FALSE),
('tb_notificacao_alerta', 'data_hora_envio', 'TIMESTAMP', TRUE, NULL, 'Momento do registro da notificação', 'Usado para histórico de envio das notificações push', 'OPERADOR', FALSE),

-- ==============================================
-- tb_leitura_temperatura
-- ==============================================
('tb_leitura_temperatura', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro de origem da leitura', 'A câmara é identificada pelo termômetro associado', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'cod_alerta', 'INTEGER', FALSE, 'FK', 'Alerta gerado pela leitura', 'Preenchido quando a leitura está fora da faixa da câmara', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'temperatura', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura medida', 'Comparada com a faixa da câmara; os lotes armazenados nela possuem categorias compatíveis com essa faixa', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento da medição', 'Preservado no histórico do PostgreSQL após a fila Redis', 'OPERADOR', FALSE),
('tb_leitura_temperatura', 'id_evento_redis', 'VARCHAR(100)', FALSE, 'NK', 'Identificador da leitura no Redis', 'Evita duplicidade quando o consumidor reprocessa uma mensagem', 'ADMIN', FALSE),

-- ==============================================
-- tb_atendimento
-- ==============================================
('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce PENDENTE (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'OPERADOR', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do atendimento', 'PENDENTE -> EM_ANDAMENTO -> RESOLVIDO; transições controladas por sp_reconhecer_alerta e trigger de justificativa', 'OPERADOR', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, NULL, 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'OPERADOR', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, NULL, 'Momento em que o atendimento foi finalizado', 'Métrica de HACCP: mede quanto tempo o lote ficou de fato em risco, não só sem monitoramento', 'OPERADOR', FALSE),

-- ==============================================
-- tb_justificativa
-- ==============================================
('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Ao ser inserida, dispara trigger que valida a temperatura e resolve o atendimento somente se ele estiver em andamento e a câmara estiver normalizada', 'OPERADOR', FALSE),

-- ==============================================
-- tb_relatorio
-- ==============================================
('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, NULL, 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'ADMIN', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do relatório', 'GERADO -> ASSINADO -> ARQUIVADO', 'GESTOR', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, NULL, 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'GESTOR', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, NULL, 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'GESTOR', FALSE),

-- ==============================================
-- tb_assinatura
-- ==============================================
('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, NULL, 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'ADMIN', TRUE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, NULL, 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'ADMIN', TRUE),

-- ==============================================
-- tb_log_auditoria
-- ==============================================
('tb_log_auditoria', 'usuario_bd', 'VARCHAR(100)', TRUE, NULL, 'Login de conexão do Postgres (CURRENT_USER) que executou a ação', 'Diferente de cod_usuario: detecta alterações feitas fora da aplicação', 'ADMIN', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, NULL, 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; pode conter dados sensíveis das tabelas auditadas', 'ADMIN', TRUE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, NULL, 'Estado da linha depois da alteração (NEW)', 'Preenchido apenas em INSERT/UPDATE; pode conter dados sensíveis das tabelas auditadas', 'ADMIN', TRUE),

-- ==============================================
-- tb_log_escalonamento
-- ==============================================
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, NULL, 'Cargo que tinha o alerta antes da escalada', 'NULL na primeira escalada (alerta nasce sem "nível anterior")', 'OPERADOR', FALSE),

-- ==============================================
-- tb_log_acesso
-- ==============================================
('tb_log_acesso', 'ip_origem', 'INET', TRUE, NULL, 'Endereço IP de onde partiu a tentativa de acesso', 'Considerado dado pessoal pela LGPD (permite identificação indireta do usuário)', 'ADMIN', TRUE);
