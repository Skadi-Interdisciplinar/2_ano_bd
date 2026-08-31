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
	chave VARCHAR(3),
	descricao TEXT NOT NULL,
	regra_negocio TEXT,
	nivel_acesso_leitura VARCHAR(8) NOT NULL DEFAULT 'operador',
	dado_sensivel BOOLEAN NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_catalogo_dados PRIMARY KEY (id),
	CONSTRAINT uq_catalogo_tabela_coluna UNIQUE (nome_tabela, nome_coluna),
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK','NK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('operador', 'gestor', 'admin'))
);


-- ====================================================================
-- CARGA DE DADOS DO CATÁLOGO
-- ====================================================================
INSERT INTO tb_catalogo_dados (nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave, descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel) VALUES
 
-- ==============================================
-- tb_cd
-- ==============================================
('tb_cd', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do centro de distribuição', NULL, 'operador', FALSE),
('tb_cd', 'cnpj', 'VARCHAR(14)', TRUE, 'NK', 'CNPJ do centro de distribuição', 'Único no sistema, sem formatação (apenas dígitos)', 'gestor', FALSE),
 
-- ==============================================
-- tb_usuario
-- ==============================================
('tb_usuario', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do funcionário', NULL, 'operador', FALSE),
('tb_usuario', 'cpf', 'VARCHAR(11)', TRUE, 'NK', 'CPF do funcionário', 'Único no sistema; dado pessoal protegido por LGPD', 'admin', TRUE),
('tb_usuario', 'email', 'VARCHAR(255)', TRUE, 'NK', 'E-mail do funcionário', 'Único no sistema; usado para login e notificações', 'admin', TRUE),
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, 'NK', 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'admin', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(8)', TRUE, 'NK', 'Cargo do funcionário no sistema', 'Define permissões e para onde alertas escalam (operador -> gestor -> admin)', 'gestor', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o funcionário pertence', 'Referencia tb_cd(id)', 'operador', FALSE),
 
-- ==============================================
-- tb_produto
-- ==============================================
('tb_produto', 'tempo_sobrevivencia', 'DECIMAL(5,2)', TRUE, 'NK', 'Tempo (em horas) que o produto resiste fora da temperatura ideal', 'Base do cálculo de escalonamento (40% do valor escala para gestor, 70% para admin). Quando um refrigerador tem múltiplos produtos, usa-se o MENOR valor entre eles', 'operador', FALSE),
('tb_produto', 'temperatura_ideal', 'DECIMAL(5,2)', TRUE, 'NK', 'Temperatura ideal de conservação do produto', 'Produtos no mesmo refrigerador devem ter a mesma temperatura ideal (validado por trigger)', 'operador', FALSE),
 
-- ==============================================
-- tb_produto_refrigerador
-- ==============================================
('tb_produto_refrigerador', 'cod_produto', 'INTEGER', TRUE, 'FK', 'Produto associado ao refrigerador', 'Relação N:N — um refrigerador pode ter vários produtos, desde que com a mesma temperatura ideal', 'operador', FALSE),
('tb_produto_refrigerador', 'cod_refrigerador', 'INTEGER', TRUE, 'FK', 'Refrigerador associado ao produto', 'Par (cod_produto, cod_refrigerador) é único — não permite duplicata', 'operador', FALSE),
 
-- ==============================================
-- tb_refrigerador
-- ==============================================
('tb_refrigerador', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado no refrigerador', 'Relação 1:1 — cada termômetro pertence a exatamente um refrigerador (UNIQUE)', 'operador', FALSE),
 
-- ==============================================
-- tb_alerta
-- ==============================================
('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, 'NK', 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'operador', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, 'NK', 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ativo/reconhecido/resolvido), nivel_atual é sobre o cargo responsável', 'operador', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, 'NK', 'Gravidade do alerta', 'Calculado via fn_calcular_gravidade_alerta, com base na diferença entre temperatura lida e ideal', 'operador', FALSE),
 
-- ==============================================
-- tb_atendimento
-- ==============================================
('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce pendente (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'operador', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, 'NK', 'Situação do atendimento', 'pendente -> em_andamento -> resolvido; transições controladas por sp_registrar_atendimento e trigger de justificativa', 'operador', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, 'NK', 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'operador', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, 'NK', 'Momento em que o atendimento foi finalizado', 'Métrica de HACCP: mede quanto tempo o produto ficou de fato em risco, não só sem monitoramento', 'operador', FALSE),
 
-- ==============================================
-- tb_justificativa
-- ==============================================
('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Ao ser inserida, dispara trigger que marca o atendimento como resolvido automaticamente', 'operador', FALSE),
 
-- ==============================================
-- tb_relatorio
-- ==============================================
('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, 'NK', 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'admin', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, 'NK', 'Situação do relatório', 'gerado -> assinado -> arquivado', 'gestor', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, 'NK', 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'gestor', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, 'NK', 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'gestor', FALSE),
 
-- ==============================================
-- tb_assinatura
-- ==============================================
('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, 'NK', 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'admin', TRUE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, 'NK', 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'admin', TRUE),
 
-- ==============================================
-- tb_log_auditoria
-- ==============================================
('tb_log_auditoria', 'usuario_bd', 'VARCHAR(100)', TRUE, 'NK', 'Login de conexão do Postgres (CURRENT_USER) que executou a ação', 'Diferente de cod_usuario: detecta alterações feitas fora da aplicação', 'admin', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, 'NK', 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, 'NK', 'Estado da linha depois da alteração (NEW)', 'Preenchido apenas em INSERT/UPDATE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
 
-- ==============================================
-- tb_log_escalonamento
-- ==============================================
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, 'NK', 'Cargo que tinha o alerta antes da escalada', 'NULL na primeira escalada (alerta nasce sem "nível anterior")', 'operador', FALSE),
 
-- ==============================================
-- tb_log_acesso
-- ==============================================
('tb_log_acesso', 'ip_origem', 'INET', TRUE, 'NK', 'Endereço IP de onde partiu a tentativa de acesso', 'Considerado dado pessoal pela LGPD (permite identificação indireta do usuário)', 'admin', TRUE);