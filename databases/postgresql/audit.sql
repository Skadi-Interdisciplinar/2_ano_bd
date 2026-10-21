DROP VIEW IF EXISTS vw_dau_diario;
DROP TABLE IF EXISTS tb_log_acesso;
DROP TABLE IF EXISTS tb_log_auditoria;
DROP TABLE IF EXISTS tb_log_escalonamento;
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
	cod_usuario INTEGER,
	acao VARCHAR(150) NOT NULL,
	entidade_afetada VARCHAR(50) NOT NULL,
	entidade_id INTEGER NOT NULL,
	dados_antigos JSONB,
	dados_novos JSONB,
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_auditoria PRIMARY KEY (id)
);

CREATE TABLE tb_log_escalonamento (
	id SERIAL,
	cod_alerta INTEGER NOT NULL,
	nivel_anterior VARCHAR(8),
	nivel_novo VARCHAR(8) NOT NULL,
	motivo VARCHAR(50) NOT NULL DEFAULT 'TEMPO_LIMITE_EXCEDIDO',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_log_escalonamento PRIMARY KEY (id),
	CONSTRAINT fk_log_escalonamento_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id)
);

-- =============================================
-- TRIGGERS DE AUDITORIA
-- =============================================
CREATE OR REPLACE FUNCTION fn_log_auditoria()
RETURNS TRIGGER AS $$
DECLARE
	v_entidade_id INTEGER;
	v_dados_antigos JSONB;
	v_dados_novos JSONB;
	v_campos_sensiveis TEXT[] := ARRAY[
		'senha', 'cpf', 'email', 'hash_conteudo',
		'conteudo', 'numero_serie', 'carimbo_tempo', 'ip_origem'
	];
BEGIN
	IF TG_OP = 'DELETE' THEN
		v_entidade_id := OLD.id;
		v_dados_antigos := to_jsonb(OLD);
	ELSIF TG_OP = 'UPDATE' THEN
		v_entidade_id := NEW.id;
		v_dados_antigos := to_jsonb(OLD);
		v_dados_novos := to_jsonb(NEW);
	ELSE
		v_entidade_id := NEW.id;
		v_dados_novos := to_jsonb(NEW);
	END IF;

	IF v_dados_antigos IS NOT NULL THEN
		v_dados_antigos := v_dados_antigos - v_campos_sensiveis;
	END IF;

	IF v_dados_novos IS NOT NULL THEN
		v_dados_novos := v_dados_novos - v_campos_sensiveis;
	END IF;

	INSERT INTO tb_log_auditoria (
		cod_usuario, acao, entidade_afetada, entidade_id,
		dados_antigos, dados_novos
	)
	VALUES (
		NULLIF(current_setting('app.usuario_atual', TRUE), '')::INTEGER,
		TG_OP,
		TG_TABLE_NAME,
		v_entidade_id,
		v_dados_antigos,
		v_dados_novos
	);

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cadastros e estrutura dos CDs
DROP TRIGGER IF EXISTS trg_auditoria_cd ON tb_cd;
CREATE TRIGGER trg_auditoria_cd
AFTER INSERT OR UPDATE OR DELETE ON tb_cd
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_endereco ON tb_endereco;
CREATE TRIGGER trg_auditoria_endereco
AFTER INSERT OR UPDATE OR DELETE ON tb_endereco
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_usuario ON tb_usuario;
CREATE TRIGGER trg_auditoria_usuario
AFTER INSERT OR UPDATE OR DELETE ON tb_usuario
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

CREATE OR REPLACE FUNCTION fn_log_admin_cd_auditoria()
RETURNS TRIGGER AS $$
DECLARE
	v_cod_admin INTEGER;
	v_dados_antigos JSONB;
	v_dados_novos JSONB;
BEGIN
	IF TG_OP = 'DELETE' THEN
		v_cod_admin := OLD.cod_admin;
		v_dados_antigos := to_jsonb(OLD);
	ELSIF TG_OP = 'UPDATE' THEN
		v_cod_admin := NEW.cod_admin;
		v_dados_antigos := to_jsonb(OLD);
		v_dados_novos := to_jsonb(NEW);
	ELSE
		v_cod_admin := NEW.cod_admin;
		v_dados_novos := to_jsonb(NEW);
	END IF;

	INSERT INTO tb_log_auditoria (
		cod_usuario, acao, entidade_afetada, entidade_id,
		dados_antigos, dados_novos
	)
	VALUES (
		NULLIF(current_setting('app.usuario_atual', TRUE), '')::INTEGER,
		TG_OP,
		TG_TABLE_NAME,
		v_cod_admin,
		v_dados_antigos,
		v_dados_novos
	);

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditoria_admin_cd ON tb_admin_cd;
CREATE TRIGGER trg_auditoria_admin_cd
AFTER INSERT OR UPDATE OR DELETE ON tb_admin_cd
FOR EACH ROW EXECUTE FUNCTION fn_log_admin_cd_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_solicitacao_suporte ON tb_solicitacao_suporte;
CREATE TRIGGER trg_auditoria_solicitacao_suporte
AFTER INSERT OR UPDATE OR DELETE ON tb_solicitacao_suporte
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

-- Equipamentos, categorias, câmaras e lotes
DROP TRIGGER IF EXISTS trg_auditoria_termometro ON tb_termometro;
CREATE TRIGGER trg_auditoria_termometro
AFTER INSERT OR UPDATE OR DELETE ON tb_termometro
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_categoria ON tb_categoria;
CREATE TRIGGER trg_auditoria_categoria
AFTER INSERT OR UPDATE OR DELETE ON tb_categoria
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_camara_frigorifica ON tb_camara_frigorifica;
CREATE TRIGGER trg_auditoria_camara_frigorifica
AFTER INSERT OR UPDATE OR DELETE ON tb_camara_frigorifica
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_lote ON tb_lote;
CREATE TRIGGER trg_auditoria_lote
AFTER INSERT OR UPDATE OR DELETE ON tb_lote
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_lote_camara_frigorifica ON tb_lote_camara_frigorifica;
CREATE TRIGGER trg_auditoria_lote_camara_frigorifica
AFTER INSERT OR UPDATE OR DELETE ON tb_lote_camara_frigorifica
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

-- Leituras, alertas e notificações
DROP TRIGGER IF EXISTS trg_auditoria_alerta ON tb_alerta;
CREATE TRIGGER trg_auditoria_alerta
AFTER INSERT OR UPDATE OR DELETE ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_notificacao_alerta ON tb_notificacao_alerta;
CREATE TRIGGER trg_auditoria_notificacao_alerta
AFTER INSERT OR UPDATE OR DELETE ON tb_notificacao_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_leitura_temperatura ON tb_leitura_temperatura;
CREATE TRIGGER trg_auditoria_leitura_temperatura
AFTER INSERT OR UPDATE OR DELETE ON tb_leitura_temperatura
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

-- Atendimentos e justificativas
DROP TRIGGER IF EXISTS trg_auditoria_atendimento ON tb_atendimento;
CREATE TRIGGER trg_auditoria_atendimento
AFTER INSERT OR UPDATE OR DELETE ON tb_atendimento
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_justificativa ON tb_justificativa;
CREATE TRIGGER trg_auditoria_justificativa
AFTER INSERT OR UPDATE OR DELETE ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

-- Relatórios e assinaturas
DROP TRIGGER IF EXISTS trg_auditoria_relatorio ON tb_relatorio;
CREATE TRIGGER trg_auditoria_relatorio
AFTER INSERT OR UPDATE OR DELETE ON tb_relatorio
FOR EACH ROW EXECUTE FUNCTION fn_log_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_assinatura ON tb_assinatura;
CREATE TRIGGER trg_auditoria_assinatura
AFTER INSERT OR UPDATE OR DELETE ON tb_assinatura
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
