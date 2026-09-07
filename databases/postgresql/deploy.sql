-- =====================================================================
-- 1. LIMPEZA
-- =====================================================================

DROP TABLE IF EXISTS tb_log_acesso_relatorio CASCADE;
DROP TABLE IF EXISTS tb_log_escalonamento CASCADE;
DROP TABLE IF EXISTS tb_log_sensor CASCADE;
DROP TABLE IF EXISTS tb_log_auditoria CASCADE;
DROP TABLE IF EXISTS tb_log_acesso CASCADE;
DROP TABLE IF EXISTS tb_catalogo_dados CASCADE;
DROP TABLE IF EXISTS tb_assinatura CASCADE;
DROP TABLE IF EXISTS tb_relatorio CASCADE;
DROP TABLE IF EXISTS tb_justificativa CASCADE;
DROP TABLE IF EXISTS tb_atendimento CASCADE;
DROP TABLE IF EXISTS tb_leitura_temperatura CASCADE;
DROP TABLE IF EXISTS tb_notificacao_alerta CASCADE;
DROP TABLE IF EXISTS tb_alerta CASCADE;
DROP TABLE IF EXISTS tb_produto_refrigerador CASCADE;
DROP TABLE IF EXISTS tb_refrigerador CASCADE;
DROP TABLE IF EXISTS tb_produto CASCADE;
DROP TABLE IF EXISTS tb_termometro CASCADE;
DROP TABLE IF EXISTS tb_usuario CASCADE;
DROP TABLE IF EXISTS tb_endereco CASCADE;
DROP TABLE IF EXISTS tb_cd CASCADE;
DROP TABLE IF EXISTS tb_estado CASCADE;

-- =====================================================================
-- 2. SCHEMAS
-- =====================================================================

ALTER DATABASE skadi SET timezone TO 'America/Sao_Paulo';

CREATE TABLE tb_estado (
	id SERIAL,
	estado CHAR(2) NOT NULL,

	CONSTRAINT pk_estado PRIMARY KEY (id),
	CONSTRAINT uq_estado_sigla UNIQUE (estado)
);

CREATE TABLE tb_cd (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	cnpj VARCHAR(14) NOT NULL,

	CONSTRAINT pk_cd PRIMARY KEY (id),
	CONSTRAINT uq_cd_cnpj UNIQUE (cnpj)
);

CREATE TABLE tb_endereco (
	id SERIAL,
	cep VARCHAR(8) NOT NULL,
	rua VARCHAR(150) NOT NULL,
	numero INTEGER NOT NULL,
	cidade VARCHAR(60) NOT NULL,
	bairro VARCHAR(70) NOT NULL,
	complemento VARCHAR(50),
	cod_estado INTEGER NOT NULL,
	cod_cd INTEGER NOT NULL,

	CONSTRAINT pk_endereco PRIMARY KEY (id),
	CONSTRAINT fk_endereco_estado FOREIGN KEY (cod_estado) REFERENCES tb_estado(id),
	CONSTRAINT fk_endereco_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id) ON DELETE CASCADE,
	CONSTRAINT ck_endereco_numero CHECK (numero >= 0)
);

CREATE TABLE tb_usuario (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	cpf VARCHAR(11) NOT NULL,
	email VARCHAR(255) NOT NULL,
	senha VARCHAR(255) NOT NULL,
	nivel_acesso VARCHAR(8) NOT NULL DEFAULT 'operador',
	cod_cd INTEGER,

	CONSTRAINT pk_usuario PRIMARY KEY (id),
	CONSTRAINT uq_usuario_cpf UNIQUE (cpf),
	CONSTRAINT uq_usuario_email UNIQUE (email),
	CONSTRAINT fk_usuario_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id),
	CONSTRAINT ck_usuario_nivel_acesso CHECK (nivel_acesso IN ('admin', 'gestor', 'operador', 'sistema'))
);

CREATE TABLE tb_termometro (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,

	CONSTRAINT pk_termometro PRIMARY KEY (id)
);

CREATE TABLE tb_produto (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	temperatura_ideal DECIMAL(5,2) NOT NULL,
	tempo_sobrevivencia DECIMAL(5,2) NOT NULL,
	validade DATE NOT NULL,

	CONSTRAINT pk_produto PRIMARY KEY (id),
	CONSTRAINT uq_produto_nome UNIQUE (nome)
);

CREATE TABLE tb_refrigerador (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,
	localizacao VARCHAR(100) NOT NULL,
	temperatura_min DECIMAL(5,2) NOT NULL,
	temperatura_max DECIMAL(5,2) NOT NULL,
	cod_cd INTEGER NOT NULL,
	cod_termometro INTEGER NOT NULL,

	CONSTRAINT pk_refrigerador PRIMARY KEY (id),
	CONSTRAINT fk_refrigerador_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id) ON DELETE RESTRICT,
	CONSTRAINT fk_refrigerador_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT uq_refrigerador_termometro UNIQUE (cod_termometro)
);

CREATE TABLE tb_produto_refrigerador (
	id SERIAL,
	cod_produto INTEGER NOT NULL,
	cod_refrigerador INTEGER NOT NULL,

	CONSTRAINT pk_produto_refrigerador PRIMARY KEY (id),
	CONSTRAINT fk_produtoref_produto FOREIGN KEY (cod_produto) REFERENCES tb_produto(id),
	CONSTRAINT fk_produtoref_refrigerador FOREIGN KEY (cod_refrigerador) REFERENCES tb_refrigerador(id),
	CONSTRAINT uq_produto_refrigerador UNIQUE (cod_produto, cod_refrigerador)
);

CREATE TABLE tb_alerta (
	id SERIAL,
	cod_refrigerador INTEGER NOT NULL,
	nivel_atual VARCHAR(8) NOT NULL DEFAULT 'operador',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	tipo VARCHAR(100) NOT NULL DEFAULT 'temperatura_fora_padrao',
	nivel_gravidade VARCHAR(100) NOT NULL,
	status VARCHAR(100) NOT NULL,
	canal VARCHAR(100) NOT NULL,

	CONSTRAINT pk_alerta PRIMARY KEY (id),
	CONSTRAINT fk_alerta_refrigerador FOREIGN KEY (cod_refrigerador) REFERENCES tb_refrigerador(id),
	CONSTRAINT ck_alerta_nivel_atual CHECK (nivel_atual IN ('operador', 'gestor', 'admin')),
	CONSTRAINT ck_alerta_nivel_gravidade CHECK (nivel_gravidade IN ('baixa', 'media', 'alta', 'critica')),
	CONSTRAINT ck_alerta_status CHECK (status IN ('ativo', 'reconhecido', 'resolvido')),
	CONSTRAINT ck_alerta_canal CHECK (canal IN ('SMS', 'Whatsapp', 'E-mail')),
	CONSTRAINT ck_alerta_tipo CHECK (tipo IN ('temperatura_fora_padrao'))
);

CREATE TABLE tb_notificacao_alerta (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	cod_usuario INTEGER NOT NULL,
	data_hora_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_notificacao_alerta PRIMARY KEY (id),
	CONSTRAINT fk_notificacao_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT fk_notificacao_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_leitura_temperatura (
	id SERIAL,
	cod_termometro INTEGER NOT NULL,
	cod_alerta INTEGER,
	temperatura DECIMAL(5,2) NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_leitura_temperatura PRIMARY KEY (id),
	CONSTRAINT fk_leitura_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT fk_leitura_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id)
);

CREATE TABLE tb_atendimento (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	cod_usuario INTEGER,
	data_hora_reconhecimento TIMESTAMP,
	data_hora_resolucao TIMESTAMP,
	status VARCHAR(50) NOT NULL,

	CONSTRAINT pk_atendimento PRIMARY KEY (id),
	CONSTRAINT fk_atendimento_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT fk_atendimento_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id),
	CONSTRAINT ck_atendimento_status CHECK (status IN ('pendente', 'em_andamento', 'resolvido'))
);

CREATE TABLE tb_justificativa (
	id SERIAL,
	cod_atendimento INTEGER NOT NULL,
	motivo VARCHAR(255) NOT NULL,
	descricao TEXT NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_justificativa PRIMARY KEY (id),
	CONSTRAINT fk_justificativa_atendimento FOREIGN KEY (cod_atendimento) REFERENCES tb_atendimento(id)
);

CREATE TABLE tb_relatorio (
	id SERIAL,
	cod_usuario_gerador INTEGER NOT NULL,
	data_hora_geracao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	hash_conteudo VARCHAR(64) NOT NULL,
	periodo_inicio DATE NOT NULL,
	periodo_fim DATE NOT NULL,
	status VARCHAR(50) NOT NULL,

	CONSTRAINT pk_relatorio PRIMARY KEY (id),
	CONSTRAINT fk_relatorio_usuario FOREIGN KEY (cod_usuario_gerador) REFERENCES tb_usuario(id),
	CONSTRAINT ck_relatorio_status CHECK (status IN ('gerado', 'assinado', 'arquivado'))
);

CREATE TABLE tb_assinatura (
	id SERIAL,
	cod_relatorio INTEGER NOT NULL,
	certificado_titular VARCHAR(255) NOT NULL,
	numero_serie VARCHAR(64) NOT NULL,
	autoridade_certificadora VARCHAR(255) NOT NULL,
	algoritmo_assinatura VARCHAR(50) NOT NULL,
	assinatura TEXT NOT NULL,
	data_assinatura DATE NOT NULL DEFAULT CURRENT_DATE,
	carimbo_tempo TEXT NOT NULL,

	CONSTRAINT pk_assinatura PRIMARY KEY (id),
	CONSTRAINT fk_assinatura_relatorio FOREIGN KEY (cod_relatorio) REFERENCES tb_relatorio(id)
);

-- =====================================================================
-- 3. AUDITORIA E LOGS
-- =====================================================================

CREATE TABLE tb_log_acesso (
	id SERIAL,
	cod_usuario INTEGER,
	tentativa_sucesso BOOLEAN NOT NULL,
	ip_origem INET NOT NULL,
	user_agent TEXT NOT NULL,
	motivo_falha VARCHAR(50),
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_acesso PRIMARY KEY (id),
	CONSTRAINT fk_log_acesso_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_log_auditoria (
	id SERIAL,
	cod_usuario INTEGER NOT NULL,
	usuario_bd VARCHAR(100) NOT NULL,
	acao VARCHAR(150) NOT NULL,
	entidade_afetada VARCHAR(50) NOT NULL,
	entidade_id INTEGER NOT NULL,
	dados_antigos JSONB,      
	dados_novos JSONB,  
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_auditoria PRIMARY KEY (id),
	CONSTRAINT fk_log_auditoria_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id)
);

CREATE TABLE tb_log_acesso_relatorio (
	id SERIAL,
	cod_relatorio INTEGER NOT NULL,
	cod_usuario INTEGER NOT NULL,
	acao VARCHAR(20) NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_acesso_relatorio PRIMARY KEY (id),
	CONSTRAINT fk_log_acesso_relatorio_relatorio FOREIGN KEY (cod_relatorio) REFERENCES tb_relatorio(id),
	CONSTRAINT fk_log_acesso_relatorio_usuario FOREIGN KEY (cod_usuario) REFERENCES tb_usuario(id),
	CONSTRAINT ck_log_acesso_relatorio_acao CHECK (acao IN ('visualizou', 'baixou'))
);

CREATE TABLE tb_log_escalonamento (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	nivel_anterior VARCHAR(8),
	nivel_novo VARCHAR(8) NOT NULL,
	motivo VARCHAR(50) NOT NULL DEFAULT 'tempo_limite_excedido',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_escalonamento PRIMARY KEY (id),
	CONSTRAINT fk_log_escalonamento_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id)
);

CREATE TABLE tb_log_sensor (
	id SERIAL,
	cod_termometro INTEGER NOT NULL,
	tipo_evento VARCHAR(50) NOT NULL,
	detalhes TEXT NOT NULL,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_sensor PRIMARY KEY (id),
	CONSTRAINT fk_log_sensor_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id)
);

CREATE OR REPLACE FUNCTION fn_log_auditoria() 
RETURNS TRIGGER AS $$
DECLARE
	v_entidade_id INTEGER;
BEGIN
	IF TG_OP = 'DELETE' THEN
		v_entidade_id := OLD.id;
	ELSE
		v_entidade_id := NEW.id;
	END IF;

	INSERT INTO tb_log_auditoria (cod_usuario, usuario_bd, acao, entidade_afetada, entidade_id, dados_antigos, dados_novos)
	VALUES (
		current_setting('app.usuario_atual')::INTEGER,
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		v_entidade_id,
		CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
		CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
	);

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_usuario
AFTER INSERT OR UPDATE OR DELETE ON tb_usuario
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

CREATE TRIGGER trg_auditoria_alerta
AFTER INSERT OR UPDATE OR DELETE ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

CREATE OR REPLACE FUNCTION fn_log_escalonamento() 
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.nivel_atual IS DISTINCT FROM OLD.nivel_atual THEN
		INSERT INTO tb_log_escalonamento (cod_alerta, nivel_anterior, nivel_novo)
		VALUES (NEW.id, OLD.nivel_atual, NEW.nivel_atual);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_escalonamento
AFTER UPDATE OF nivel_atual ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_escalonamento();

-- =====================================================================
-- 4. CATALOGO DE DADOS
-- =====================================================================

CREATE TABLE tb_catalogo_dados (
	id SERIAL,
	nome_tabela VARCHAR(100) NOT NULL,
	nome_coluna VARCHAR(100) NOT NULL,
	tipo_dado VARCHAR(50) NOT NULL,
	obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
	chave VARCHAR(2),
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

('tb_estado', 'estado', 'CHAR(2)', TRUE, 'NK', 'Sigla da unidade federativa', 'Única no sistema; armazenada no padrão de duas letras', 'operador', FALSE),

('tb_cd', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do centro de distribuição', NULL, 'operador', FALSE),
('tb_cd', 'cnpj', 'VARCHAR(14)', TRUE, 'NK', 'CNPJ do centro de distribuição', 'Único no sistema, sem formatação (apenas dígitos)', 'gestor', FALSE),

('tb_usuario', 'id', 'SERIAL', TRUE, 'PK', 'Identificador único do funcionário', NULL, 'operador', FALSE),
('tb_usuario', 'cpf', 'VARCHAR(11)', TRUE, 'NK', 'CPF do funcionário', 'Único no sistema; dado pessoal protegido por LGPD', 'admin', TRUE),
('tb_usuario', 'email', 'VARCHAR(255)', TRUE, 'NK', 'E-mail do funcionário', 'Único no sistema; usado para login e notificações', 'admin', TRUE),
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, NULL, 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'admin', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(8)', TRUE, NULL, 'Cargo do funcionário no sistema', 'Define permissões e para onde alertas escalam (operador -> gestor -> admin)', 'gestor', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o funcionário pertence', 'Referencia tb_cd(id)', 'operador', FALSE),

('tb_produto', 'nome', 'VARCHAR(150)', TRUE, 'NK', 'Nome do produto', 'Único no sistema', 'operador', FALSE),
('tb_produto', 'tempo_sobrevivencia', 'DECIMAL(5,2)', TRUE, NULL, 'Tempo (em horas) que o produto resiste fora da temperatura ideal', 'Base do cálculo de escalonamento (40% do valor escala para gestor, 70% para admin). Quando um refrigerador tem múltiplos produtos, usa-se o MENOR valor entre eles', 'operador', FALSE),
('tb_produto', 'temperatura_ideal', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura ideal de conservação do produto', 'Produtos no mesmo refrigerador devem ter a mesma temperatura ideal (validado por trigger)', 'operador', FALSE),

('tb_produto_refrigerador', 'cod_produto', 'INTEGER', TRUE, 'FK', 'Produto associado ao refrigerador', 'Relação N:N — um refrigerador pode ter vários produtos, desde que com a mesma temperatura ideal', 'operador', FALSE),
('tb_produto_refrigerador', 'cod_refrigerador', 'INTEGER', TRUE, 'FK', 'Refrigerador associado ao produto', 'Par (cod_produto, cod_refrigerador) é único — não permite duplicata', 'operador', FALSE),

('tb_refrigerador', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado no refrigerador', 'Relação 1:1 — cada termômetro pertence a exatamente um refrigerador (UNIQUE)', 'operador', FALSE),

('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, NULL, 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'operador', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, NULL, 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ativo/reconhecido/resolvido), nivel_atual é sobre o cargo responsável', 'operador', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, NULL, 'Gravidade do alerta', 'Calculado via fn_calcular_gravidade_alerta, com base na diferença entre temperatura lida e ideal', 'operador', FALSE),

('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce pendente (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'operador', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do atendimento', 'pendente -> em_andamento -> resolvido; transições controladas por sp_registrar_atendimento e trigger de justificativa', 'operador', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, NULL, 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'operador', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, NULL, 'Momento em que o atendimento foi finalizado', 'Métrica de HACCP: mede quanto tempo o produto ficou de fato em risco, não só sem monitoramento', 'operador', FALSE),

('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Ao ser inserida, dispara trigger que marca o atendimento como resolvido automaticamente', 'operador', FALSE),

('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, NULL, 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'admin', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do relatório', 'gerado -> assinado -> arquivado', 'gestor', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, NULL, 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'gestor', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, NULL, 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'gestor', FALSE),

('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, NULL, 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'admin', TRUE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, NULL, 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'admin', TRUE),

('tb_log_auditoria', 'usuario_bd', 'VARCHAR(100)', TRUE, NULL, 'Login de conexão do Postgres (CURRENT_USER) que executou a ação', 'Diferente de cod_usuario: detecta alterações feitas fora da aplicação', 'admin', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, NULL, 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, NULL, 'Estado da linha depois da alteração (NEW)', 'Preenchido apenas em INSERT/UPDATE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
 
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, NULL, 'Cargo que tinha o alerta antes da escalada', 'NULL na primeira escalada (alerta nasce sem "nível anterior")', 'operador', FALSE),

('tb_log_acesso', 'ip_origem', 'INET', TRUE, NULL, 'Endereço IP de onde partiu a tentativa de acesso', 'Considerado dado pessoal pela LGPD (permite identificação indireta do usuário)', 'admin', TRUE);

-- =====================================================================
-- 5. FUNCOES
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_calcular_prazo_escalonamento(
    p_cod_alerta INTEGER,
    p_percentual INTEGER
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_tempo_sobrevivencia DECIMAL(5,2);
    v_resultado DECIMAL(5,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
    ) THEN
        RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
    END IF;

    IF p_percentual < 0 OR p_percentual > 100 THEN
        RAISE EXCEPTION 'Percentual de escalonamento inválido. O valor deve estar entre 0 e 100.';
    END IF;

    SELECT MIN(p.tempo_sobrevivencia)
    INTO v_tempo_sobrevivencia
    FROM tb_produto p
    JOIN tb_produto_refrigerador pr 
        ON p.id = pr.cod_produto
    JOIN tb_refrigerador r 
        ON pr.cod_refrigerador = r.id
    JOIN tb_alerta a 
        ON r.id = a.cod_refrigerador
    WHERE a.id = p_cod_alerta;

    IF v_tempo_sobrevivencia IS NULL THEN
        RAISE EXCEPTION 'Nenhum produto associado ao refrigerador do alerta %.', p_cod_alerta;
    END IF;

    v_resultado := v_tempo_sobrevivencia * p_percentual / 100;

    RETURN v_resultado;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_gravidade_alerta(
    p_cod_leitura INTEGER
)
RETURNS VARCHAR AS $$
DECLARE
    v_temperatura_atual DECIMAL(5,2);
    v_temperatura_ideal DECIMAL(5,2);
    v_diferenca DECIMAL(5,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tb_leitura_temperatura
        WHERE id = p_cod_leitura
    ) THEN
        RAISE EXCEPTION 'Leitura de temperatura % não encontrada.', p_cod_leitura;
    END IF;

    SELECT lt.temperatura, MIN(p.temperatura_ideal)
    INTO v_temperatura_atual, v_temperatura_ideal
    FROM tb_produto p
    JOIN tb_produto_refrigerador pr 
        ON p.id = pr.cod_produto
    JOIN tb_refrigerador r 
        ON pr.cod_refrigerador = r.id
    JOIN tb_leitura_temperatura lt 
        ON r.cod_termometro = lt.cod_termometro
    WHERE lt.id = p_cod_leitura
    GROUP BY lt.temperatura;

    IF v_temperatura_ideal IS NULL THEN
        RAISE EXCEPTION 'Nenhum produto associado ao refrigerador da leitura %.', p_cod_leitura;
    END IF;

    v_diferenca := ABS(v_temperatura_atual - v_temperatura_ideal);

    IF v_diferenca <= 1 THEN
        RETURN 'baixa';
    ELSIF v_diferenca <= 3 THEN
        RETURN 'media';
    ELSIF v_diferenca <= 5 THEN
        RETURN 'alta';
    ELSE
        RETURN 'critica';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 6. PROCEDURES
-- =====================================================================

CREATE OR REPLACE PROCEDURE sp_registrar_atendimento(
	p_cod_alerta INTEGER,
	p_cod_usuario INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
	) THEN
		RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
	END IF;

	IF NOT EXISTS (
		SELECT 1
        FROM tb_usuario
        WHERE id = p_cod_usuario
	) THEN
		RAISE EXCEPTION 'Usuário % não encontrado.', p_cod_usuario;
	END IF;

	IF EXISTS (
        SELECT 1 FROM tb_atendimento
        WHERE cod_alerta = p_cod_alerta AND status != 'pendente'
    ) THEN
        RAISE EXCEPTION 'Alerta % já está sendo atendido ou foi resolvido.', p_cod_alerta;
    END IF;

	UPDATE tb_atendimento
    SET cod_usuario = p_cod_usuario, data_hora_reconhecimento = CURRENT_TIMESTAMP, status = 'em_andamento'
    WHERE cod_alerta = p_cod_alerta AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nenhum atendimento pendente encontrado para o alerta %.', p_cod_alerta;
    END IF;

	UPDATE tb_alerta SET status = 'reconhecido' WHERE id = p_cod_alerta;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_notificar_nivel_acesso(
	p_cod_alerta INTEGER,
	p_nivel VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
        FROM tb_alerta
        WHERE id = p_cod_alerta
	) THEN
		RAISE EXCEPTION 'Alerta % não encontrado.', p_cod_alerta;
	END IF;

	IF p_nivel NOT IN ('operador', 'gestor', 'admin') THEN
		RAISE EXCEPTION 'Nível de acesso inválido: %.', p_nivel;
	END IF;

	INSERT INTO tb_notificacao_alerta (cod_alerta, cod_usuario)
	SELECT p_cod_alerta, u.id
	FROM tb_usuario u
	JOIN tb_refrigerador r
        ON r.cod_cd = u.cod_cd
	JOIN tb_alerta a
        ON a.cod_refrigerador = r.id
	WHERE a.id = p_cod_alerta AND u.nivel_acesso = p_nivel;
END;
$$;

-- =====================================================================
-- 7. TRIGGERS E AUTOMACOES
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_criar_atendimento_pendente() 
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO tb_atendimento (cod_alerta, status)
	VALUES (NEW.id, 'pendente');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_criar_atendimento_pendente
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_criar_atendimento_pendente();

CREATE OR REPLACE FUNCTION fn_resolver_atendimento_por_justificativa() 
RETURNS TRIGGER AS $$
DECLARE
	v_cod_alerta INTEGER;
BEGIN
	SELECT cod_alerta
	INTO v_cod_alerta
	FROM tb_atendimento
	WHERE id = NEW.cod_atendimento;

	UPDATE tb_atendimento
	SET status = 'resolvido', data_hora_resolucao = CURRENT_TIMESTAMP
	WHERE id = NEW.cod_atendimento;

	UPDATE tb_alerta
	SET status = 'resolvido'
	WHERE id = v_cod_alerta;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resolver_atendimento_por_justificativa
AFTER INSERT ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_resolver_atendimento_por_justificativa();

CREATE OR REPLACE FUNCTION fn_validar_temperatura_produto_refrigerador() 
RETURNS TRIGGER AS $$
DECLARE
	v_temp_novo DECIMAL(5,2);
	v_temp_existente DECIMAL(5,2);
BEGIN
	SELECT temperatura_ideal 
	INTO v_temp_novo 
	FROM tb_produto 
	WHERE id = NEW.cod_produto;

	SELECT p.temperatura_ideal 
	INTO v_temp_existente
	FROM tb_produto p
	JOIN tb_produto_refrigerador pr 
		ON pr.cod_produto = p.id
	WHERE pr.cod_refrigerador = NEW.cod_refrigerador
	LIMIT 1;

	IF v_temp_existente IS NOT NULL AND v_temp_existente != v_temp_novo THEN
		RAISE EXCEPTION 'Produto com temperatura ideal % incompatível com refrigerador (já há produto com temperatura %).', v_temp_novo, v_temp_existente;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_produto_refrigerador
BEFORE INSERT ON tb_produto_refrigerador
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_produto_refrigerador();

CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_refrigerador INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_canal VARCHAR(100);
    v_alerta INTEGER;
BEGIN
    SELECT
        r.id,
        r.temperatura_min,
        r.temperatura_max
    INTO
        v_refrigerador,
        v_temperatura_min,
        v_temperatura_max
    FROM tb_refrigerador r
    WHERE r.cod_termometro = NEW.cod_termometro;

	IF v_refrigerador IS NULL THEN
        RAISE EXCEPTION 'Termômetro % não está associado a nenhum refrigerador.', NEW.cod_termometro;
    END IF;

    IF NEW.temperatura < v_temperatura_min
       OR NEW.temperatura > v_temperatura_max THEN

        v_gravidade := fn_calcular_gravidade_alerta(NEW.id);

        CASE v_gravidade
            WHEN 'baixa' THEN
                v_canal := 'E-mail';

            WHEN 'media' THEN
                v_canal := 'E-mail';

            WHEN 'alta' THEN
                v_canal := 'Whatsapp';

            WHEN 'critica' THEN
                v_canal := 'SMS';
        END CASE;

        INSERT INTO tb_alerta (
            cod_refrigerador,
            nivel_atual,
            data_hora,
            nivel_gravidade,
            status,
            canal
        )
        VALUES (
            v_refrigerador,
            'operador',
            NEW.data_hora,
            v_gravidade,
            'ativo',
            v_canal
        )
        RETURNING id INTO v_alerta;

        UPDATE tb_leitura_temperatura
        SET cod_alerta = v_alerta
        WHERE id = NEW.id;

        CALL sp_notificar_nivel_acesso(
            v_alerta,
            'operador'
        );

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_alerta_por_leitura
AFTER INSERT ON tb_leitura_temperatura
FOR EACH ROW
EXECUTE FUNCTION fn_gerar_alerta_por_leitura();

CREATE OR REPLACE FUNCTION fn_notificar_novo_alerta()
RETURNS TRIGGER AS $$
DECLARE
	v_horas_prazo DECIMAL(5,2);
BEGIN
	v_horas_prazo := fn_calcular_prazo_escalonamento(NEW.id, 40);

	PERFORM pg_notify('novo_alerta', json_build_object(
		'id_alerta', NEW.id,
		'prazo_epoch', EXTRACT(EPOCH FROM (NEW.data_hora + v_horas_prazo * INTERVAL '1 hour') AT TIME ZONE 'America/Sao_Paulo')
	)::text);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_novo_alerta
AFTER INSERT ON tb_alerta
FOR EACH ROW
EXECUTE FUNCTION fn_notificar_novo_alerta();

-- =====================================================================
-- 8. MASSA DE DADOS PARA TESTE
-- =====================================================================

BEGIN;

INSERT INTO tb_estado (estado) VALUES
('AC'), ('AL'), ('AP'), ('AM'), ('BA'), ('CE'), ('DF'), ('ES'), ('GO'), 
('MA'), ('MT'), ('MS'), ('MG'), ('PA'), ('PB'), ('PR'), ('PE'), ('PI'),
('RJ'), ('RN'), ('RS'), ('RO'), ('RR'), ('SC'), ('SP'), ('SE'), ('TO');

INSERT INTO tb_cd (nome, cnpj) VALUES
('CD São Paulo', '12345678000101'),
('CD Rio de Janeiro', '23456789000102'),
('CD Minas Gerais', '34567890000103'),
('CD Paraná', '45678901000104'),
('CD Santa Catarina', '56789012000105');

INSERT INTO tb_endereco
    (cep, rua, numero, cidade, bairro, complemento, cod_estado, cod_cd)
SELECT
    (10000000 + gs)::VARCHAR(8),
    'Rua Industrial ' || gs,
    100 + gs,

    CASE ((gs - 1) % 5)
        WHEN 0 THEN 'São Paulo'
        WHEN 1 THEN 'Rio de Janeiro'
        WHEN 2 THEN 'Belo Horizonte'
        WHEN 3 THEN 'Curitiba'
        ELSE 'Florianópolis'
    END,

    'Centro Industrial',

    CASE
        WHEN gs % 3 = 0 THEN 'Galpão ' || gs
        ELSE NULL
    END,

    CASE ((gs - 1) % 5)
        WHEN 0 THEN (SELECT id FROM tb_estado WHERE estado = 'SP')
        WHEN 1 THEN (SELECT id FROM tb_estado WHERE estado = 'RJ')
        WHEN 2 THEN (SELECT id FROM tb_estado WHERE estado = 'MG')
        WHEN 3 THEN (SELECT id FROM tb_estado WHERE estado = 'PR')
        ELSE (SELECT id FROM tb_estado WHERE estado = 'SC')
    END,

    ((gs - 1) % 5) + 1

FROM generate_series(1, 100) AS gs;

ALTER TABLE tb_usuario
DISABLE TRIGGER trg_auditoria_usuario;

INSERT INTO tb_usuario (
    nome, cpf, email, senha, nivel_acesso
)
VALUES 
('Sistema Worker', '00000000000', 'sistema@skadi.local', '$2b$12$3wu4y3is8.AuPIIvwioO1eCs8ErbMEWRcmCEgONkpZwBufwtHYC7K', 'sistema');

INSERT INTO tb_usuario (
    nome, cpf, email, senha, nivel_acesso, cod_cd
)
SELECT
    'Funcionário ' || gs,
    LPAD(gs::TEXT, 11, '0'),
    'funcionario' || gs || '@coldchain.com.br',
    '$2a$12$V/BiuqbeOeEWxbeUfBMgy..ESFzLoz0c4Z5zAy4ArSFuZksxXyNKC',
    CASE
        WHEN gs <= 10 THEN 'admin'
        WHEN gs <= 30 THEN 'gestor'
        ELSE 'operador'
    END,
    ((gs - 1) % 5) + 1
FROM generate_series(1, 100) AS gs;

ALTER TABLE tb_usuario
ENABLE TRIGGER trg_auditoria_usuario;

SELECT set_config('app.usuario_atual', '1', false);

INSERT INTO tb_termometro (modelo)
SELECT
	CASE
		WHEN gs % 3 = 0 THEN 'ThermoTrack T-300'
		WHEN gs % 3 = 1 THEN 'SensorTemp ST-200'
		ELSE 'ColdMonitor CM-100'
	END
	|| '-' || LPAD(gs::TEXT, 3, '0')
FROM generate_series(1, 50) AS gs;

INSERT INTO tb_produto
    (nome, temperatura_ideal, tempo_sobrevivencia, validade)
VALUES

('Carne bovina - Acém', 4.00, 8.00, '2027-03-15'),
('Carne bovina - Alcatra', 4.00, 8.00, '2027-03-20'),
('Carne bovina - Contrafilé', 4.00, 8.00, '2027-04-10'),
('Carne bovina - Costela', 4.00, 7.00, '2027-04-15'),
('Carne bovina - Patinho', 4.00, 8.00, '2027-05-05'),

('Carne suína - Lombo', 4.00, 7.00, '2027-03-25'),
('Carne suína - Pernil', 4.00, 7.00, '2027-04-05'),
('Carne suína - Costela', 4.00, 6.00, '2027-04-20'),
('Carne suína - Paleta', 4.00, 7.00, '2027-05-10'),

('Frango inteiro', 4.00, 6.00, '2027-02-15'),
('Peito de frango', 4.00, 6.00, '2027-02-20'),
('Coxa de frango', 4.00, 6.00, '2027-03-01'),
('Asa de frango', 4.00, 5.00, '2027-03-10'),
('Frango desossado', 4.00, 6.00, '2027-03-20'),

('Linguiça fresca', 4.00, 5.00, '2027-02-28'),
('Hambúrguer bovino resfriado', 4.00, 5.00, '2027-03-15'),
('Carne moída bovina', 4.00, 4.00, '2027-03-05'),

('Tilápia fresca', 0.00, 4.00, '2027-02-10'),
('Salmão fresco', 0.00, 4.00, '2027-02-15'),
('Filé de peixe', 0.00, 4.00, '2027-03-01'),
('Camarão fresco', 0.00, 3.00, '2027-03-10'),
('Atum fresco', 0.00, 4.00, '2027-03-20'),

('Carne bovina congelada', -18.00, 4.00, '2028-01-15'),
('Carne suína congelada', -18.00, 4.00, '2028-02-10'),
('Frango congelado', -18.00, 4.00, '2028-02-20'),
('Peixe congelado', -18.00, 3.00, '2028-03-05'),
('Costela bovina congelada', -18.00, 4.00, '2028-03-15');

INSERT INTO tb_refrigerador
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
VALUES

('ColdStorage CS-500', 'Setor Carnes - Câmara 01', 3.00, 4.50, 1, 1),
('ColdStorage CS-500', 'Setor Carnes - Câmara 02', 2.00, 6.00, 1, 2),
('FrioMaster FM-400', 'Setor Carnes - Câmara 03', 2.00, 6.00, 2, 3),
('FrioMaster FM-400', 'Setor Carnes - Câmara 04', 2.00, 6.00, 2, 4),
('RefrigPro RP-300', 'Setor Carnes - Câmara 05', 2.00, 6.00, 3, 5),
('RefrigPro RP-300', 'Setor Carnes - Câmara 06', 2.00, 6.00, 3, 6),

('ColdStorage CS-500', 'Setor Pescados - Câmara 01', -2.00, 2.00, 4, 7),
('FrioMaster FM-400', 'Setor Pescados - Câmara 02', -2.00, 2.00, 4, 8),
('RefrigPro RP-300', 'Setor Pescados - Câmara 03', -2.00, 2.00, 5, 9),

('ColdStorage CS-500', 'Setor Congelados - Câmara 01', -22.00, -16.00, 1, 10),
('FrioMaster FM-400', 'Setor Congelados - Câmara 02', -22.00, -16.00, 2, 11),
('RefrigPro RP-300', 'Setor Congelados - Câmara 03', -22.00, -16.00, 3, 12);

INSERT INTO tb_produto_refrigerador
    (cod_produto, cod_refrigerador)
VALUES

(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),

(6, 2),
(7, 2),
(8, 2),
(9, 2),
(10, 2),

(11, 3),
(12, 3),
(13, 3),
(14, 3),

(15, 4),
(16, 4),
(17, 4),

(1, 5),
(6, 5),
(11, 5),
(15, 5),

(2, 6),
(7, 6),
(12, 6),
(16, 6),

(18, 7),
(19, 7),

(20, 8),
(21, 8),

(22, 9),

(23, 10),
(24, 10),

(25, 11),
(26, 11),

(27, 12);

INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
(1, 4.00, '2026-08-30 08:00:00'),
(1, 4.50, '2026-08-30 20:00:00'),
(1, 3.80, '2026-08-31 08:00:00'),
(1, 4.20, '2026-08-31 20:00:00'),
(1, 4.10, '2026-09-01 08:00:00'),
(1, 3.90, '2026-09-01 20:00:00'),

(2, 3.50, '2026-08-30 08:00:00'),
(2, 4.00, '2026-08-30 20:00:00'),
(2, 4.30, '2026-08-31 08:00:00'),
(2, 3.70, '2026-08-31 20:00:00'),
(2, 4.20, '2026-09-01 08:00:00'),
(2, 3.80, '2026-09-01 20:00:00'),

(3, 4.20, '2026-08-30 08:00:00'),
(3, 3.80, '2026-08-30 20:00:00'),
(3, 4.50, '2026-08-31 08:00:00'),
(3, 4.00, '2026-08-31 20:00:00'),
(3, 3.60, '2026-09-01 08:00:00'),
(3, 4.40, '2026-09-01 20:00:00'),

(4, 3.90, '2026-08-30 08:00:00'),
(4, 4.10, '2026-08-30 20:00:00'),
(4, 4.40, '2026-08-31 08:00:00'),
(4, 3.60, '2026-08-31 20:00:00'),
(4, 4.00, '2026-09-01 08:00:00'),
(4, 4.30, '2026-09-01 20:00:00'),

(5, 4.00, '2026-08-30 08:00:00'),
(5, 4.30, '2026-08-30 20:00:00'),
(5, 3.70, '2026-08-31 08:00:00'),
(5, 4.20, '2026-08-31 20:00:00'),
(5, 3.90, '2026-09-01 08:00:00'),
(5, 4.10, '2026-09-01 20:00:00'),

(6, 3.80, '2026-08-30 08:00:00'),
(6, 4.10, '2026-08-30 20:00:00'),
(6, 4.50, '2026-08-31 08:00:00'),
(6, 3.90, '2026-08-31 20:00:00'),
(6, 4.20, '2026-09-01 08:00:00'),
(6, 3.70, '2026-09-01 20:00:00'),

(7, 0.00, '2026-08-30 08:00:00'),
(7, -0.50, '2026-08-30 20:00:00'),
(7, 0.50, '2026-08-31 08:00:00'),
(7, -1.00, '2026-08-31 20:00:00'),
(7, 0.20, '2026-09-01 08:00:00'),
(7, -0.30, '2026-09-01 20:00:00'),

(8, 0.50, '2026-08-30 08:00:00'),
(8, -0.20, '2026-08-30 20:00:00'),
(8, 0.80, '2026-08-31 08:00:00'),
(8, -0.70, '2026-08-31 20:00:00'),
(8, 0.30, '2026-09-01 08:00:00'),
(8, -0.40, '2026-09-01 20:00:00'),

(9, -0.50, '2026-08-30 08:00:00'),
(9, 0.00, '2026-08-30 20:00:00'),
(9, 0.70, '2026-08-31 08:00:00'),
(9, -0.30, '2026-08-31 20:00:00'),
(9, 0.40, '2026-09-01 08:00:00'),
(9, -0.80, '2026-09-01 20:00:00'),

(10, -18.00, '2026-08-30 08:00:00'),
(10, -19.00, '2026-08-30 20:00:00'),
(10, -17.50, '2026-08-31 08:00:00'),
(10, -18.50, '2026-08-31 20:00:00'),
(10, -20.00, '2026-09-01 08:00:00'),
(10, -17.00, '2026-09-01 20:00:00'),

(11, -18.50, '2026-08-30 08:00:00'),
(11, -19.50, '2026-08-30 20:00:00'),
(11, -17.00, '2026-08-31 08:00:00'),
(11, -18.00, '2026-08-31 20:00:00'),
(11, -20.50, '2026-09-01 08:00:00'),
(11, -17.50, '2026-09-01 20:00:00'),

(12, -19.00, '2026-08-30 08:00:00'),
(12, -18.00, '2026-08-30 20:00:00'),
(12, -17.50, '2026-08-31 08:00:00'),
(12, -20.00, '2026-08-31 20:00:00'),
(12, -18.50, '2026-09-01 08:00:00'),
(12, -17.00, '2026-09-01 20:00:00');

INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
(1, 4.80, '2026-09-02 08:00:00'),

(2, 6.80, '2026-09-02 08:30:00'),

(7, 5.00, '2026-09-02 09:00:00'),

(10, -8.00, '2026-09-02 09:30:00');

INSERT INTO tb_leitura_temperatura (cod_termometro, temperatura, data_hora)
SELECT
    r.cod_termometro,
    round(
        (
            r.temperatura_min
            + (r.temperatura_max - r.temperatura_min)
            * (0.3 + 0.4 * random())
        )::numeric,
        2
    ),
    TIMESTAMP '2026-08-20 08:00:00'
        + ((gs / 3) || ' days')::interval
        + (((gs % 3) * 8) || ' hours')::interval
FROM tb_refrigerador r,
     generate_series(0, 29) AS gs;

DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_refrigerador = 1
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_registrar_atendimento(v_cod_alerta, 62);
END $$;

INSERT INTO tb_justificativa (
    cod_atendimento, motivo, descricao
)
VALUES (
    (SELECT a.id
     FROM tb_atendimento a
     JOIN tb_alerta al ON al.id = a.cod_alerta
     WHERE al.cod_refrigerador = 1
     ORDER BY a.id DESC LIMIT 1),
    'Porta aberta para reposição',
    'Alerta gerado durante reposição manual de estoque; temperatura normalizada após fechamento da câmara.'
);

DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_refrigerador = 10
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_registrar_atendimento(v_cod_alerta, 42);
END $$;

INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status
)
VALUES
(2, 'a1b2c3d4e5f67890123456789012345678901234567890123456789012345678', '2026-08-01', '2026-08-31', 'gerado'),
(3, 'b2c3d4e5f678901234567890123456789012345678901234567890123456789', '2026-08-01', '2026-08-31', 'assinado'),
(4, 'c3d4e5f6789012345678901234567890123456789012345678901234567890', '2026-07-01', '2026-07-31', 'arquivado');

INSERT INTO tb_assinatura (
    cod_relatorio, certificado_titular, numero_serie, 
    autoridade_certificadora, algoritmo_assinatura,
    assinatura, carimbo_tempo
)
VALUES
(2, 'Sistema ColdChain', 'CERT-2026-0001', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_2', '2026-09-02 10:00:00'),
(3, 'Sistema ColdChain', 'CERT-2026-0002', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_3', '2026-09-02 10:05:00');

INSERT INTO tb_log_acesso_relatorio (
    cod_relatorio, cod_usuario, acao
)
VALUES
    (1, 32, 'visualizou'),
    (1, 33, 'baixou'),
    (2, 33, 'visualizou'),
    (3, 52, 'baixou');

UPDATE tb_alerta
SET nivel_atual = 'gestor'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'critica'
    ORDER BY id DESC
    LIMIT 1
);

INSERT INTO tb_log_sensor (
    cod_termometro, tipo_evento, detalhes
)
VALUES
(1, 'manutencao', 'Sensor calibrado'),
(2, 'falha', 'Leitura fora do comportamento esperado'),
(7, 'manutencao', 'Sensor verificado'),
(10, 'bateria', 'Bateria do sensor substituída');

INSERT INTO tb_log_acesso (
    cod_usuario, tentativa_sucesso, ip_origem, user_agent, motivo_falha
)
VALUES
	(2, TRUE, '192.168.1.10', 'Mozilla/5.0', NULL),
	(32, TRUE, '192.168.1.11', 'Mozilla/5.0', NULL),
	(33, TRUE, '192.168.1.12', 'Mozilla/5.0', NULL),
	(52, TRUE, '192.168.1.13', 'Mozilla/5.0', NULL),
	(42, FALSE, '192.168.1.14', 'Mozilla/5.0', 'Senha incorreta');

COMMIT;
