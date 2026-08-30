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
DROP TABLE IF EXISTS tb_estado CASCADE;
DROP TABLE IF EXISTS tb_cd CASCADE;


CREATE TABLE tb_cd (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	cnpj VARCHAR(14) NOT NULL,

	CONSTRAINT pk_cd PRIMARY KEY (id),
	CONSTRAINT uq_cd_cnpj UNIQUE (cnpj)
);

CREATE TABLE tb_estado (
	id SERIAL,
	estado CHAR(2) NOT NULL,

	CONSTRAINT pk_estado PRIMARY KEY (id),
	CONSTRAINT uq_estado_sigla UNIQUE (estado)
);

CREATE TABLE tb_endereco (
	id SERIAL,
	cep VARCHAR(9) NOT NULL,
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
	cod_cd INTEGER NOT NULL,

	CONSTRAINT pk_usuario PRIMARY KEY (id),
	CONSTRAINT uq_usuario_cpf UNIQUE (cpf),
	CONSTRAINT uq_usuario_email UNIQUE (email),
	CONSTRAINT fk_usuario_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id),
	CONSTRAINT ck_usuario_nivel_acesso CHECK (nivel_acesso IN ('admin', 'gestor', 'operador'))
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
	tipo VARCHAR(100) NOT NULL,
	nivel_gravidade VARCHAR(100) NOT NULL,
	status VARCHAR(100) NOT NULL,
	canal VARCHAR(100) NOT NULL,

	CONSTRAINT pk_alerta PRIMARY KEY (id),
	CONSTRAINT fk_alerta_refrigerador FOREIGN KEY (cod_refrigerador) REFERENCES tb_refrigerador(id),
	CONSTRAINT ck_alerta_nivel_atual CHECK (nivel_atual IN ('operador', 'gestor', 'admin')),
	CONSTRAINT ck_alerta_nivel_gravidade CHECK (nivel_gravidade IN ('baixa', 'media', 'alta', 'critica')),
	CONSTRAINT ck_alerta_status CHECK (status IN ('ativo', 'reconhecido', 'resolvido')),
	CONSTRAINT ck_alerta_canal CHECK (canal IN ('SMS', 'Whatsapp', 'E-mail'))
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