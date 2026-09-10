DROP TABLE IF EXISTS tb_log_acesso;
DROP TABLE IF EXISTS tb_log_auditoria;
DROP TABLE IF EXISTS tb_log_acesso_relatorio;
DROP TABLE IF EXISTS tb_log_escalonamento;
DROP TABLE IF EXISTS tb_log_sensor;
DROP TRIGGER IF EXISTS trg_auditoria_usuario ON tb_usuario;
DROP TRIGGER IF EXISTS trg_auditoria_alerta ON tb_alerta;
DROP TRIGGER IF EXISTS trg_log_escalonamento ON tb_alerta;


-- =============================================
-- TABELAS DE LOG
-- =============================================
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


-- =============================================
-- TRIGGERS DE AUDITORIA
-- =============================================
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