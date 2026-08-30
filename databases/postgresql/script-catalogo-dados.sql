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
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('operador', 'gestor', 'admin'))
);

CREATE OR REPLACE VIEW vw_catalogo_completo AS
SELECT
	nome_tabela,
	nome_coluna,
	tipo_dado,
    obrigatorio,
    chave,
	descricao,
	regra_negocio,
	nivel_acesso_leitura,
	dado_sensivel
FROM tb_catalogo_dados
ORDER BY nome_tabela, nome_coluna;