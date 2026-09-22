-- ====================================================================
-- DEPLOY: schemas.sql
-- ====================================================================

DROP TABLE IF EXISTS tb_assinatura CASCADE;
DROP TABLE IF EXISTS tb_relatorio CASCADE;
DROP TABLE IF EXISTS tb_justificativa CASCADE;
DROP TABLE IF EXISTS tb_atendimento CASCADE;
DROP TABLE IF EXISTS tb_leitura_temperatura CASCADE;
DROP TABLE IF EXISTS tb_notificacao_alerta CASCADE;
DROP TABLE IF EXISTS tb_alerta CASCADE;
DROP TABLE IF EXISTS tb_lote_camara_frigorifica CASCADE;
DROP TABLE IF EXISTS tb_lote CASCADE;
DROP TABLE IF EXISTS tb_categoria CASCADE;
DROP TABLE IF EXISTS tb_camara_frigorifica CASCADE;
DROP TABLE IF EXISTS tb_termometro CASCADE;
DROP TABLE IF EXISTS tb_usuario CASCADE;
DROP TABLE IF EXISTS tb_endereco CASCADE;
DROP TABLE IF EXISTS tb_cd CASCADE;
DROP TABLE IF EXISTS tb_estado CASCADE;


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
	CONSTRAINT ck_usuario_nivel_acesso CHECK (nivel_acesso IN ('operador', 'gestor', 'admin', 'sistema'))
);

CREATE TABLE tb_termometro (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,

	CONSTRAINT pk_termometro PRIMARY KEY (id)
);

CREATE TABLE tb_categoria (
	id SERIAL,
	nome VARCHAR(150) NOT NULL,
	temperatura_ideal DECIMAL(5,2) NOT NULL,
	vida_util_horas DECIMAL(7,2) NOT NULL,

	CONSTRAINT pk_categoria PRIMARY KEY (id),
	CONSTRAINT uq_categoria_nome UNIQUE (nome),
	CONSTRAINT ck_categoria_vida_util CHECK (vida_util_horas > 0)
);

CREATE TABLE tb_camara_frigorifica (
	id SERIAL,
	modelo VARCHAR(150) NOT NULL,
	localizacao VARCHAR(100) NOT NULL,
	temperatura_min DECIMAL(5,2) NOT NULL,
	temperatura_max DECIMAL(5,2) NOT NULL,
	cod_cd INTEGER NOT NULL,
	cod_termometro INTEGER NOT NULL,

	CONSTRAINT pk_camara_frigorifica PRIMARY KEY (id),
	CONSTRAINT fk_camara_frigorifica_cd FOREIGN KEY (cod_cd) REFERENCES tb_cd(id) ON DELETE RESTRICT,
	CONSTRAINT fk_camara_frigorifica_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT uq_camara_frigorifica_termometro UNIQUE (cod_termometro),
	CONSTRAINT ck_camara_frigorifica_faixa_temperatura CHECK (temperatura_min < temperatura_max)
);

CREATE TABLE tb_lote (
	id SERIAL,
	codigo_lote VARCHAR(50) NOT NULL,
	cod_categoria INTEGER NOT NULL,
	data_fabricacao DATE NOT NULL,
	data_validade DATE NOT NULL,
	status VARCHAR(20) NOT NULL DEFAULT 'ativo',

	CONSTRAINT pk_lote PRIMARY KEY (id),
	CONSTRAINT uq_lote_codigo UNIQUE (codigo_lote),
	CONSTRAINT fk_lote_categoria FOREIGN KEY (cod_categoria) REFERENCES tb_categoria(id),
	CONSTRAINT ck_lote_datas CHECK (data_validade >= data_fabricacao),
	CONSTRAINT ck_lote_status CHECK (status IN ('ativo', 'bloqueado', 'expedido', 'vencido'))
);

CREATE TABLE tb_lote_camara_frigorifica (
	id SERIAL,
	cod_lote INTEGER NOT NULL,
	cod_camara_frigorifica INTEGER NOT NULL,
	data_entrada TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	data_saida TIMESTAMP,

	CONSTRAINT pk_lote_camara_frigorifica PRIMARY KEY (id),
	CONSTRAINT fk_loteref_lote FOREIGN KEY (cod_lote) REFERENCES tb_lote(id),
	CONSTRAINT fk_loteref_camara_frigorifica FOREIGN KEY (cod_camara_frigorifica) REFERENCES tb_camara_frigorifica(id),
	CONSTRAINT ck_loteref_periodo CHECK (data_saida IS NULL OR data_saida > data_entrada)
);

CREATE TABLE tb_alerta (
	id SERIAL,
	cod_camara_frigorifica INTEGER NOT NULL,
	vida_util_referencia_horas DECIMAL(7,2),
	nivel_atual VARCHAR(8) NOT NULL DEFAULT 'operador',
	data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	tipo VARCHAR(100) NOT NULL DEFAULT 'temperatura_fora_padrao',
	nivel_gravidade VARCHAR(100) NOT NULL,
	status VARCHAR(100) NOT NULL,

	CONSTRAINT pk_alerta PRIMARY KEY (id),
	CONSTRAINT fk_alerta_camara_frigorifica FOREIGN KEY (cod_camara_frigorifica) REFERENCES tb_camara_frigorifica(id),
	CONSTRAINT ck_alerta_nivel_atual CHECK (nivel_atual IN ('operador', 'gestor', 'admin')),
	CONSTRAINT ck_alerta_nivel_gravidade CHECK (nivel_gravidade IN ('estável', 'atenção', 'crítica', 'urgente')),
	CONSTRAINT ck_alerta_status CHECK (status IN ('ativo', 'reconhecido', 'resolvido')),
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
	id_evento_redis VARCHAR(100),

	CONSTRAINT pk_leitura_temperatura PRIMARY KEY (id),
	CONSTRAINT fk_leitura_termometro FOREIGN KEY (cod_termometro) REFERENCES tb_termometro(id),
	CONSTRAINT fk_leitura_alerta FOREIGN KEY (cod_alerta) REFERENCES tb_alerta(id),
	CONSTRAINT uq_leitura_evento_redis UNIQUE (id_evento_redis)
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


-- ====================================================================
-- DEPLOY: functions.sql
-- ====================================================================

CREATE OR REPLACE FUNCTION fn_calcular_vida_util_camara(
    p_cod_camara INTEGER
)
RETURNS DECIMAL(7,2) AS $$
DECLARE
    v_vida_util DECIMAL(7,2);
BEGIN
    SELECT MIN(c.vida_util_horas)
    INTO v_vida_util
    FROM tb_lote_camara_frigorifica lr
    JOIN tb_lote l 
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    JOIN tb_categoria c 
        ON c.id = l.cod_categoria
    WHERE lr.cod_camara_frigorifica = p_cod_camara AND lr.data_saida IS NULL;

    IF v_vida_util IS NULL THEN
        RAISE EXCEPTION 'A câmara frigorífica % não possui lote ativo.', p_cod_camara;
    END IF;

    RETURN v_vida_util;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_calcular_prazo_escalonamento(
    p_cod_alerta INTEGER,
    p_percentual INTEGER
)
RETURNS DECIMAL(7,2) AS $$
DECLARE
    v_vida_util DECIMAL(7,2);
BEGIN
    IF p_percentual < 0 OR p_percentual > 100 THEN
        RAISE EXCEPTION 'Percentual de escalonamento inválido. O valor deve estar entre 0 e 100.';
    END IF;

    SELECT COALESCE(a.vida_util_referencia_horas, fn_calcular_vida_util_camara(a.cod_camara_frigorifica))
    INTO v_vida_util
    FROM tb_alerta a
    WHERE a.id = p_cod_alerta;

    IF v_vida_util IS NULL THEN
        RAISE EXCEPTION 'Alerta % não possui vida útil de referência.', p_cod_alerta;
    END IF;

    RETURN v_vida_util * p_percentual / 100;
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

    SELECT lt.temperatura, MIN(c.temperatura_ideal)
    INTO v_temperatura_atual, v_temperatura_ideal
    FROM tb_camara_frigorifica r
    JOIN tb_lote_camara_frigorifica lr
        ON lr.cod_camara_frigorifica = r.id AND lr.data_saida IS NULL
    JOIN tb_lote l
        ON l.id = lr.cod_lote AND l.status = 'ativo'
    JOIN tb_categoria c
        ON c.id = l.cod_categoria
    JOIN tb_leitura_temperatura lt
        ON r.cod_termometro = lt.cod_termometro
    WHERE lt.id = p_cod_leitura
    GROUP BY lt.temperatura;

    IF v_temperatura_ideal IS NULL THEN
        RAISE EXCEPTION 'Nenhum lote ativo associado à câmara frigorífica da leitura %.', p_cod_leitura;
    END IF;

    v_diferenca := ABS(v_temperatura_atual - v_temperatura_ideal);

    IF v_diferenca <= 1 THEN
        RETURN 'estável';
    ELSIF v_diferenca <= 3 THEN
        RETURN 'atenção';
    ELSIF v_diferenca <= 5 THEN
        RETURN 'crítica';
    ELSE
        RETURN 'urgente';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_camara_temperatura_normal(
    p_cod_camara INTEGER,
    p_data_hora TIMESTAMP
)
RETURNS BOOLEAN AS $$
DECLARE
    v_temperatura DECIMAL(5,2);
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
BEGIN
    SELECT lt.temperatura, c.temperatura_min, c.temperatura_max
    INTO v_temperatura, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica c
    JOIN tb_leitura_temperatura lt
        ON c.cod_termometro = lt.cod_termometro
    WHERE c.id = p_cod_camara
       AND lt.data_hora <= p_data_hora
    ORDER BY lt.data_hora DESC, lt.id DESC
    LIMIT 1;

    RETURN v_temperatura IS NOT NULL
       AND v_temperatura BETWEEN v_temperatura_min AND v_temperatura_max;
END;
$$ LANGUAGE plpgsql;


-- ====================================================================
-- DEPLOY: procedures.sql
-- ====================================================================

CREATE OR REPLACE PROCEDURE sp_reconhecer_alerta(
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

    UPDATE tb_atendimento
    SET cod_usuario = p_cod_usuario,
        data_hora_reconhecimento = CURRENT_TIMESTAMP,
        status = 'em_andamento'
    WHERE cod_alerta = p_cod_alerta AND status = 'pendente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nenhum atendimento pendente encontrado para o alerta %.', p_cod_alerta;
    END IF;

    UPDATE tb_alerta
    SET status = 'reconhecido'
    WHERE id = p_cod_alerta AND status = 'ativo';
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
    SELECT a.id, u.id
    FROM tb_alerta a
    JOIN tb_camara_frigorifica c
        ON c.id = a.cod_camara_frigorifica
    JOIN tb_usuario u
        ON u.cod_cd = c.cod_cd AND u.nivel_acesso = p_nivel
    WHERE a.id = p_cod_alerta;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_escalonar_alertas_pendentes()
LANGUAGE plpgsql AS $$
DECLARE
    v_alerta RECORD;
    v_nivel_novo VARCHAR(8);
BEGIN
    FOR v_alerta IN
        SELECT id, nivel_atual, data_hora
        FROM tb_alerta
        WHERE status = 'ativo' AND nivel_atual IN ('operador', 'gestor')
    LOOP
        v_nivel_novo := NULL;

        IF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 70) * INTERVAL '1 hour' THEN
            v_nivel_novo := 'admin';
        ELSIF CURRENT_TIMESTAMP >= v_alerta.data_hora
            + fn_calcular_prazo_escalonamento(v_alerta.id, 40) * INTERVAL '1 hour'
            AND v_alerta.nivel_atual = 'operador' THEN
            v_nivel_novo := 'gestor';
        END IF;

        IF v_nivel_novo IS NOT NULL THEN
            UPDATE tb_alerta 
            SET nivel_atual = v_nivel_novo
            WHERE id = v_alerta.id;

            CALL sp_notificar_nivel_acesso(v_alerta.id, v_nivel_novo);
        END IF;
    END LOOP;
END;
$$;


-- ====================================================================
-- DEPLOY: triggers.sql
-- ====================================================================

DROP TRIGGER IF EXISTS trg_criar_atendimento_pendente ON tb_alerta;
DROP TRIGGER IF EXISTS trg_resolver_atendimento_por_justificativa ON tb_justificativa;
DROP TRIGGER IF EXISTS trg_validar_temperatura_categoria_camara ON tb_lote_camara_frigorifica;
DROP TRIGGER IF EXISTS trg_gerar_alerta_por_leitura ON tb_leitura_temperatura;
DROP TRIGGER IF EXISTS trg_notificar_novo_alerta ON tb_alerta;


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
    v_cod_camara INTEGER;
    v_data_alerta TIMESTAMP;
    v_status_atendimento VARCHAR(50);
BEGIN
    SELECT
        a.id,
        a.cod_camara_frigorifica,
        a.data_hora,
        atd.status
    INTO
        v_cod_alerta,
        v_cod_camara,
        v_data_alerta,
        v_status_atendimento
    FROM tb_atendimento atd
    JOIN tb_alerta a
        ON a.id = atd.cod_alerta
    WHERE atd.id = NEW.cod_atendimento;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Atendimento % não encontrado.',
            NEW.cod_atendimento;
    END IF;

    IF v_status_atendimento <> 'em_andamento' THEN
        RAISE EXCEPTION
            'O atendimento precisa estar em andamento para ser resolvido.';
    END IF;

    IF fn_camara_temperatura_normal(
        v_cod_camara,
        CURRENT_TIMESTAMP::TIMESTAMP
    ) THEN

        UPDATE tb_atendimento
           SET status = 'resolvido',
               data_hora_resolucao = CURRENT_TIMESTAMP
         WHERE id = NEW.cod_atendimento;

        UPDATE tb_alerta
           SET status = 'resolvido'
         WHERE id = v_cod_alerta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resolver_atendimento_por_justificativa
AFTER INSERT ON tb_justificativa
FOR EACH ROW EXECUTE FUNCTION fn_resolver_atendimento_por_justificativa();


CREATE OR REPLACE FUNCTION fn_validar_temperatura_categoria_camara()
RETURNS TRIGGER AS $$
DECLARE
    v_temp_ideal DECIMAL(5,2);
    v_temp_min DECIMAL(5,2);
    v_temp_max DECIMAL(5,2);
BEGIN
    SELECT c.temperatura_ideal, cam.temperatura_min, cam.temperatura_max
      INTO v_temp_ideal, v_temp_min, v_temp_max
      FROM tb_lote l
      JOIN tb_categoria c ON c.id = l.cod_categoria
      JOIN tb_camara_frigorifica cam ON cam.id = NEW.cod_camara_frigorifica
     WHERE l.id = NEW.cod_lote;

    IF v_temp_ideal IS NULL THEN
        RAISE EXCEPTION 'Lote % ou câmara frigorífica % não encontrado.', NEW.cod_lote, NEW.cod_camara_frigorifica;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tb_lote_camara_frigorifica lr
          JOIN tb_lote lote_existente
            ON lote_existente.id = lr.cod_lote
          JOIN tb_categoria categoria_existente
            ON categoria_existente.id = lote_existente.cod_categoria
         WHERE lr.cod_camara_frigorifica = NEW.cod_camara_frigorifica
           AND lr.data_saida IS NULL
           AND lr.cod_lote <> NEW.cod_lote
           AND lote_existente.status = 'ativo'
           AND categoria_existente.temperatura_ideal IS DISTINCT FROM v_temp_ideal
    ) THEN
        RAISE EXCEPTION 'A câmara frigorífica % já possui lote ativo com temperatura ideal incompatível.', NEW.cod_camara_frigorifica;
    END IF;

    IF v_temp_ideal < v_temp_min OR v_temp_ideal > v_temp_max THEN
        RAISE EXCEPTION 'Temperatura ideal da categoria (%) incompatível com a faixa da câmara frigorífica (% a %).',
            v_temp_ideal, v_temp_min, v_temp_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura_categoria_camara
BEFORE INSERT OR UPDATE OF cod_lote, cod_camara_frigorifica, data_saida
ON tb_lote_camara_frigorifica
FOR EACH ROW EXECUTE FUNCTION fn_validar_temperatura_categoria_camara();


CREATE OR REPLACE FUNCTION fn_gerar_alerta_por_leitura()
RETURNS TRIGGER AS $$
DECLARE
    v_camara INTEGER;
    v_temperatura_min DECIMAL(5,2);
    v_temperatura_max DECIMAL(5,2);
    v_gravidade VARCHAR(20);
    v_vida_util DECIMAL(7,2);
    v_alerta INTEGER;
BEGIN
    SELECT cam.id, cam.temperatura_min, cam.temperatura_max
    INTO v_camara, v_temperatura_min, v_temperatura_max
    FROM tb_camara_frigorifica cam
    WHERE cam.cod_termometro = NEW.cod_termometro;

    IF v_camara IS NULL THEN
        RAISE EXCEPTION 'Termômetro % não está associado a nenhuma câmara frigorífica.', NEW.cod_termometro;
    END IF;

    IF NEW.temperatura < v_temperatura_min OR NEW.temperatura > v_temperatura_max THEN

        v_gravidade := fn_calcular_gravidade_alerta(NEW.id);
        v_vida_util := fn_calcular_vida_util_camara(v_camara);

        INSERT INTO tb_alerta (
            cod_camara_frigorifica,
            vida_util_referencia_horas,
            nivel_atual,
            data_hora,
            nivel_gravidade,
            status
        )
        VALUES (
            v_camara,
            v_vida_util,
            'operador',
            NEW.data_hora,
            v_gravidade,
            'ativo'
        )
        RETURNING id INTO v_alerta;

        UPDATE tb_leitura_temperatura
           SET cod_alerta = v_alerta
         WHERE id = NEW.id;

        CALL sp_notificar_nivel_acesso(v_alerta, 'operador');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_alerta_por_leitura
AFTER INSERT ON tb_leitura_temperatura
FOR EACH ROW EXECUTE FUNCTION fn_gerar_alerta_por_leitura();


CREATE OR REPLACE FUNCTION fn_notificar_novo_alerta()
RETURNS TRIGGER AS $$
DECLARE
    v_horas_prazo DECIMAL(7,2);
BEGIN
    v_horas_prazo := fn_calcular_prazo_escalonamento(NEW.id, 40);

    PERFORM pg_notify(
        'novo_alerta',
        json_build_object(
            'id_alerta', NEW.id,
            'prazo_epoch',
            EXTRACT(EPOCH FROM (
                NEW.data_hora + v_horas_prazo * INTERVAL '1 hour'
            ) AT TIME ZONE 'America/Sao_Paulo')
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_novo_alerta
AFTER INSERT ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_notificar_novo_alerta();


-- ====================================================================
-- DEPLOY: audit.sql
-- ====================================================================

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

-- ====================================================================
-- DEPLOY: catalogo-dados.sql
-- ====================================================================

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
	nivel_acesso_leitura VARCHAR(8) NOT NULL DEFAULT 'operador',
	dado_sensivel BOOLEAN NOT NULL DEFAULT FALSE,

	CONSTRAINT pk_catalogo_dados PRIMARY KEY (id),
	CONSTRAINT uq_catalogo_tabela_coluna UNIQUE (nome_tabela, nome_coluna),
	CONSTRAINT ck_catalogo_chave CHECK (chave IN ('PK', 'FK','NK')),
	CONSTRAINT ck_catalogo_nivel_acesso CHECK (nivel_acesso_leitura IN ('sistema', 'operador', 'gestor', 'admin'))
);


-- ====================================================================
-- CARGA DE DADOS DO CATÁLOGO
-- ====================================================================
INSERT INTO tb_catalogo_dados (nome_tabela, nome_coluna, tipo_dado, obrigatorio, chave, descricao, regra_negocio, nivel_acesso_leitura, dado_sensivel) VALUES
 
-- ==============================================
-- tb_estado
-- ==============================================
('tb_estado', 'estado', 'CHAR(2)', TRUE, 'NK', 'Sigla da unidade federativa', 'Única no sistema; armazenada no padrão de duas letras', 'operador', FALSE),

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
('tb_usuario', 'senha', 'VARCHAR(255)', TRUE, NULL, 'Hash da senha de acesso', 'Nunca armazenada em texto plano; nunca exposta em relatórios ou exports', 'admin', TRUE),
('tb_usuario', 'nivel_acesso', 'VARCHAR(8)', TRUE, NULL, 'Cargo do funcionário no sistema', 'Níveis: operador, gestor, admin e sistema; sistema representa a administração da plataforma', 'gestor', FALSE),
('tb_usuario', 'cod_cd', 'INTEGER', TRUE, 'FK', 'Centro de distribuição ao qual o funcionário pertence', 'Referencia tb_cd(id)', 'operador', FALSE),
 
-- ==============================================
-- tb_categoria
-- ==============================================
('tb_categoria', 'nome', 'VARCHAR(150)', TRUE, 'NK', 'Categoria de armazenamento', 'Única no sistema; concentra os parâmetros comuns aos lotes', 'operador', FALSE),
('tb_categoria', 'temperatura_ideal', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura ideal da categoria', 'Usada para calcular a gravidade dos alertas', 'operador', FALSE),
('tb_categoria', 'vida_util_horas', 'DECIMAL(7,2)', TRUE, NULL, 'Vida útil da categoria em horas', 'Base direta do escalonamento do alerta', 'operador', FALSE),
 
-- ==============================================
-- tb_lote
-- ==============================================
('tb_lote', 'codigo_lote', 'VARCHAR(50)', TRUE, 'NK', 'Identificador operacional do lote', 'Único no sistema', 'operador', FALSE),
('tb_lote', 'cod_categoria', 'INTEGER', TRUE, 'FK', 'Categoria do lote', 'Cada lote pertence a exatamente uma categoria', 'operador', FALSE),
('tb_lote', 'data_fabricacao', 'DATE', TRUE, NULL, 'Data de fabricação do lote', 'Usada para rastreabilidade', 'operador', FALSE),
('tb_lote', 'data_validade', 'DATE', TRUE, NULL, 'Data de validade do lote', 'Deve ser igual ou posterior à fabricação', 'operador', FALSE),

-- ==============================================
-- tb_lote_camara_frigorifica
-- ==============================================
('tb_lote_camara_frigorifica', 'cod_lote', 'INTEGER', TRUE, 'FK', 'Lote movimentado', 'Um lote pode passar por várias câmaras frigoríficas ao longo do tempo', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica do lote', 'Apenas uma localização atual pode ficar aberta por lote', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'data_entrada', 'TIMESTAMP', TRUE, NULL, 'Entrada do lote na câmara frigorífica', 'Início do período de armazenamento', 'operador', FALSE),
('tb_lote_camara_frigorifica', 'data_saida', 'TIMESTAMP', FALSE, NULL, 'Saída do lote da câmara frigorífica', 'NULL indica a localização atual', 'operador', FALSE),
 
-- ==============================================
-- tb_camara_frigorifica
-- ==============================================
('tb_camara_frigorifica', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro instalado na câmara frigorífica', 'Relação 1:1 — cada termômetro pertence a exatamente uma câmara frigorífica (UNIQUE)', 'operador', FALSE),
 
-- ==============================================
-- tb_alerta
-- ==============================================
('tb_alerta', 'nivel_atual', 'VARCHAR(8)', TRUE, NULL, 'Cargo responsável pelo alerta no momento', 'Nasce como operador; muda automaticamente por escalonamento (trigger monitora esse campo)', 'operador', FALSE),
('tb_alerta', 'cod_camara_frigorifica', 'INTEGER', TRUE, 'FK', 'Câmara frigorífica que originou o alerta', 'Todo alerta pertence à câmara que originou a ocorrência', 'operador', FALSE),
('tb_alerta', 'vida_util_referencia_horas', 'DECIMAL(7,2)', FALSE, NULL, 'Menor vida útil entre os lotes ativos no momento do alerta', 'Base dos prazos fixos de escalonamento', 'gestor', FALSE),
('tb_alerta', 'status', 'VARCHAR(100)', TRUE, NULL, 'Fase do atendimento do alerta', 'Não confundir com nivel_atual: status é sobre o atendimento (ativo/reconhecido/resolvido), nivel_atual é sobre o cargo responsável', 'operador', FALSE),
('tb_alerta', 'nivel_gravidade', 'VARCHAR(100)', TRUE, NULL, 'Gravidade do alerta', 'Calculada via fn_calcular_gravidade_alerta: estável, atenção, crítica ou urgente', 'operador', FALSE),
('tb_alerta', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento de criação do alerta', 'Usado como referência para o escalonamento', 'operador', FALSE),
('tb_alerta', 'tipo', 'VARCHAR(100)', TRUE, NULL, 'Tipo da ocorrência', 'Atualmente limitado a temperatura_fora_padrao', 'operador', FALSE),

-- tb_notificacao_alerta
-- ==============================================
('tb_notificacao_alerta', 'cod_alerta', 'INTEGER', TRUE, 'FK', 'Alerta notificado', 'Relaciona a notificação ao alerta correspondente', 'operador', FALSE),
('tb_notificacao_alerta', 'cod_usuario', 'INTEGER', TRUE, 'FK', 'Usuário notificado', 'Usuário do mesmo CD e nível de acesso do escalonamento', 'operador', FALSE),
('tb_notificacao_alerta', 'data_hora_envio', 'TIMESTAMP', TRUE, NULL, 'Momento do registro da notificação', 'Usado para histórico de envio das notificações push', 'operador', FALSE),

-- tb_leitura_temperatura
-- ==============================================
('tb_leitura_temperatura', 'cod_termometro', 'INTEGER', TRUE, 'FK', 'Termômetro de origem da leitura', 'A câmara é identificada pelo termômetro associado', 'operador', FALSE),
('tb_leitura_temperatura', 'cod_alerta', 'INTEGER', FALSE, 'FK', 'Alerta gerado pela leitura', 'Preenchido quando a leitura está fora da faixa da câmara', 'operador', FALSE),
('tb_leitura_temperatura', 'temperatura', 'DECIMAL(5,2)', TRUE, NULL, 'Temperatura medida', 'Comparada com a faixa da câmara e com a temperatura ideal da categoria', 'operador', FALSE),
('tb_leitura_temperatura', 'data_hora', 'TIMESTAMP', TRUE, NULL, 'Momento da medição', 'Preservado no histórico do PostgreSQL após a fila Redis', 'operador', FALSE),
('tb_leitura_temperatura', 'id_evento_redis', 'VARCHAR(100)', FALSE, 'NK', 'Identificador da leitura no Redis', 'Evita duplicidade quando o consumidor reprocessa uma mensagem', 'admin', FALSE),
 
-- ==============================================
-- tb_atendimento
-- ==============================================
('tb_atendimento', 'cod_usuario', 'INTEGER', FALSE, 'FK', 'Funcionário responsável pelo atendimento', 'Aceita NULL: atendimento nasce pendente (via trigger), sem usuário atribuído até alguém reconhecer o alerta', 'operador', FALSE),
('tb_atendimento', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do atendimento', 'pendente -> em_andamento -> resolvido; transições controladas por sp_reconhecer_alerta e trigger de justificativa', 'operador', FALSE),
('tb_atendimento', 'data_hora_reconhecimento', 'TIMESTAMP', FALSE, NULL, 'Momento em que alguém assumiu o alerta', 'Diferente de data_hora_resolucao: reconhecimento é "estou ciente", resolução é "problema resolvido de fato"', 'operador', FALSE),
('tb_atendimento', 'data_hora_resolucao', 'TIMESTAMP', FALSE, NULL, 'Momento em que o atendimento foi finalizado', 'Métrica de HACCP: mede quanto tempo o lote ficou de fato em risco, não só sem monitoramento', 'operador', FALSE),
 
-- ==============================================
-- tb_justificativa
-- ==============================================
('tb_justificativa', 'cod_atendimento', 'INTEGER', TRUE, 'FK', 'Atendimento ao qual a justificativa se refere', 'Ao ser inserida, dispara trigger que valida a temperatura e resolve o atendimento somente se ele estiver em andamento e a câmara estiver normalizada', 'operador', FALSE),
 
-- ==============================================
-- tb_relatorio
-- ==============================================
('tb_relatorio', 'hash_conteudo', 'VARCHAR(64)', TRUE, NULL, 'Hash SHA-256 do conteúdo do relatório', 'Garante integridade: qualquer alteração no conteúdo altera o hash, evidenciando adulteração', 'admin', TRUE),
('tb_relatorio', 'status', 'VARCHAR(50)', TRUE, NULL, 'Situação do relatório', 'gerado -> assinado -> arquivado', 'gestor', FALSE),
('tb_relatorio', 'periodo_inicio', 'DATE', TRUE, NULL, 'Início do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: força quem gera o relatório a informar o período explicitamente', 'gestor', FALSE),
('tb_relatorio', 'periodo_fim', 'DATE', TRUE, NULL, 'Fim do intervalo coberto pelo relatório', 'Sem DEFAULT de propósito: evita relatório de período incorreto por esquecimento', 'gestor', FALSE),
 
-- ==============================================
-- tb_assinatura
-- ==============================================
('tb_assinatura', 'numero_serie', 'VARCHAR(64)', TRUE, NULL, 'Número de série do certificado ICP-Brasil', 'Identifica unicamente o certificado usado para dar validade jurídica ao relatório', 'admin', TRUE),
('tb_assinatura', 'carimbo_tempo', 'TEXT', TRUE, NULL, 'Token de carimbo de tempo (RFC 3161)', 'Emitido por Autoridade de Carimbo do Tempo externa; garante quando a assinatura ocorreu, de forma não manipulável', 'admin', TRUE),
 
-- ==============================================
-- tb_log_auditoria
-- ==============================================
('tb_log_auditoria', 'usuario_bd', 'VARCHAR(100)', TRUE, NULL, 'Login de conexão do Postgres (CURRENT_USER) que executou a ação', 'Diferente de cod_usuario: detecta alterações feitas fora da aplicação', 'admin', FALSE),
('tb_log_auditoria', 'dados_antigos', 'JSONB', FALSE, NULL, 'Estado da linha antes da alteração (OLD)', 'Preenchido apenas em UPDATE/DELETE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
('tb_log_auditoria', 'dados_novos', 'JSONB', FALSE, NULL, 'Estado da linha depois da alteração (NEW)', 'Preenchido apenas em INSERT/UPDATE; pode conter dados sensíveis das tabelas auditadas', 'admin', TRUE),
 
-- ==============================================
-- tb_log_escalonamento
-- ==============================================
('tb_log_escalonamento', 'nivel_anterior', 'VARCHAR(8)', FALSE, NULL, 'Cargo que tinha o alerta antes da escalada', 'NULL na primeira escalada (alerta nasce sem "nível anterior")', 'operador', FALSE),
 
-- ==============================================
-- tb_log_acesso
-- ==============================================
('tb_log_acesso', 'ip_origem', 'INET', TRUE, NULL, 'Endereço IP de onde partiu a tentativa de acesso', 'Considerado dado pessoal pela LGPD (permite identificação indireta do usuário)', 'admin', TRUE);


-- ====================================================================
-- DEPLOY: dataload.sql
-- ====================================================================

-- ====================================================================
-- MASSA DE DADOS PARA TESTE DE VOLUME
-- ====================================================================
BEGIN;


-- =============================================
-- 1. ESTADOS
-- =============================================
INSERT INTO tb_estado (estado) VALUES
('AC'), ('AL'), ('AP'), ('AM'), ('BA'), ('CE'), ('DF'), ('ES'), ('GO'), 
('MA'), ('MT'), ('MS'), ('MG'), ('PA'), ('PB'), ('PR'), ('PE'), ('PI'),
('RJ'), ('RN'), ('RS'), ('RO'), ('RR'), ('SC'), ('SP'), ('SE'), ('TO');


-- =============================================
-- 2. CENTROS DE DISTRIBUIÇÃO
-- =============================================
INSERT INTO tb_cd (nome, cnpj) VALUES
('CD São Paulo', '48372615000194'),
('CD Rio de Janeiro', '71940582000163'),
('CD Minas Gerais', '90218437000128'),
('CD Paraná', '35847126000179'),
('CD Santa Catarina', '62490381000147');


-- =============================================
-- 3. ENDEREÇOS
-- =============================================
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


-- =============================================
-- 4. USUÁRIOS
-- =============================================

-- A trigger de auditoria precisa de um usuário existente para registrar cod_usuario.
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
    (ARRAY[
        'Ana', 'Bruno', 'Camila', 'Daniel', 'Eduarda',
        'Felipe', 'Gabriela', 'Henrique', 'Isabela', 'João',
        'Karina', 'Leonardo', 'Mariana', 'Nicolas', 'Olívia',
        'Paulo', 'Rafaela', 'Samuel', 'Tatiana', 'Vinícius'
    ])[((gs - 1) % 20) + 1]
    || ' ' ||
    (ARRAY[
        'Almeida', 'Barbosa', 'Carvalho', 'Dias', 'Esteves'
    ])[((gs - 1) / 20) + 1],
    (10000000000 + (gs * 7919))::TEXT,
    'colaborador' || LPAD(gs::TEXT, 3, '0') || '@skadi.com.br',
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

-- Define o usuário atual para as próximas auditorias.
SELECT set_config('app.usuario_atual', '1', false);


-- =============================================
-- 5. TERMÔMETROS
-- =============================================
INSERT INTO tb_termometro (modelo)
SELECT
	CASE
		WHEN gs % 3 = 0 THEN 'ThermoTrack T-300'
		WHEN gs % 3 = 1 THEN 'SensorTemp ST-200'
		ELSE 'ColdMonitor CM-100'
	END
	|| '-' || LPAD(gs::TEXT, 3, '0')
FROM generate_series(1, 50) AS gs;


-- =============================================
-- 6. CATEGORIAS
-- =============================================
INSERT INTO tb_categoria
    (nome, temperatura_ideal, vida_util_horas)
VALUES
('Carnes bovinas resfriadas', 4.00, 8.00),
('Carnes suínas resfriadas', 4.00, 7.00),
('Aves resfriadas', 4.00, 6.00),
('Carnes processadas resfriadas', 4.00, 5.00),
('Pescados frescos', 0.00, 4.00),
('Pescados congelados', -18.00, 4.00);


-- =============================================
-- 7. CÂMARAS FRIGORÍFICAS
-- =============================================
INSERT INTO tb_camara_frigorifica
    (modelo, localizacao, temperatura_min, temperatura_max, cod_cd, cod_termometro)
VALUES

-- Câmaras frigoríficas de Carnes e Aves — 4°C
('ColdStorage CS-500', 'Setor Carnes - Câmara 01', 3.00, 4.50, 1, 1),
('ColdStorage CS-500', 'Setor Carnes - Câmara 02', 2.00, 6.00, 1, 2),
('FrioMaster FM-400', 'Setor Carnes - Câmara 03', 2.00, 6.00, 2, 3),
('FrioMaster FM-400', 'Setor Carnes - Câmara 04', 2.00, 6.00, 2, 4),
('RefrigPro RP-300', 'Setor Carnes - Câmara 05', 2.00, 6.00, 3, 5),
('RefrigPro RP-300', 'Setor Carnes - Câmara 06', 2.00, 6.00, 3, 6),

-- Câmaras frigoríficas de Pescados — 0°C
('ColdStorage CS-500', 'Setor Pescados - Câmara 01', -2.00, 2.00, 4, 7),
('FrioMaster FM-400', 'Setor Pescados - Câmara 02', -2.00, 2.00, 4, 8),
('RefrigPro RP-300', 'Setor Pescados - Câmara 03', -2.00, 2.00, 5, 9),

-- Câmaras frigoríficas de Congelados — -18°C
('ColdStorage CS-500', 'Setor Congelados - Câmara 01', -22.00, -16.00, 1, 10),
('FrioMaster FM-400', 'Setor Congelados - Câmara 02', -22.00, -16.00, 2, 11),
('RefrigPro RP-300', 'Setor Congelados - Câmara 03', -22.00, -16.00, 3, 12);


-- =============================================
-- 8. LOTES
-- =============================================
INSERT INTO tb_lote
    (codigo_lote, cod_categoria, data_fabricacao, data_validade)
VALUES
('LOTE-2026-0001', 1, '2026-08-20', '2026-09-08'),
('LOTE-2026-0002', 2, '2026-08-21', '2026-09-09'),
('LOTE-2026-0003', 3, '2026-08-22', '2026-09-07'),
('LOTE-2026-0004', 4, '2026-08-23', '2026-09-06'),
('LOTE-2026-0005', 1, '2026-08-20', '2026-09-08'),
('LOTE-2026-0006', 2, '2026-08-21', '2026-09-09'),
('LOTE-2026-0007', 5, '2026-08-25', '2026-09-05'),
('LOTE-2026-0008', 5, '2026-08-26', '2026-09-06'),
('LOTE-2026-0009', 5, '2026-08-27', '2026-09-07'),
('LOTE-2026-0010', 6, '2026-08-01', '2027-08-01'),
('LOTE-2026-0011', 6, '2026-08-02', '2027-08-02'),
('LOTE-2026-0012', 6, '2026-08-03', '2027-08-03');

INSERT INTO tb_lote_camara_frigorifica (cod_lote, cod_camara_frigorifica)
VALUES
    (1, 1),
    (2, 2),
    (3, 1),
    (4, 1),
    (5, 3),
    (6, 4),
    (7, 7),
    (8, 8),
    (9, 9),
    (10, 10),
    (11, 11),
    (12, 12);


-- =============================================
-- 9. LEITURAS DE TEMPERATURA
-- =============================================

-- 9.1 Leituras normais (dentro da faixa, não geram alerta)
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Câmara frigorífica 1 - faixa: 3°C a 4,5°C
(1, 4.00, '2026-08-30 08:00:00'),
(1, 4.50, '2026-08-30 20:00:00'),
(1, 3.80, '2026-08-31 08:00:00'),
(1, 4.20, '2026-08-31 20:00:00'),
(1, 4.10, '2026-09-01 08:00:00'),
(1, 3.90, '2026-09-01 20:00:00'),

-- Câmara frigorífica 2 - faixa: 2°C a 6°C
(2, 3.50, '2026-08-30 08:00:00'),
(2, 4.00, '2026-08-30 20:00:00'),
(2, 4.30, '2026-08-31 08:00:00'),
(2, 3.70, '2026-08-31 20:00:00'),
(2, 4.20, '2026-09-01 08:00:00'),
(2, 3.80, '2026-09-01 20:00:00'),

-- Câmara frigorífica 3 - faixa: 2°C a 6°C
(3, 4.20, '2026-08-30 08:00:00'),
(3, 3.80, '2026-08-30 20:00:00'),
(3, 4.50, '2026-08-31 08:00:00'),
(3, 4.00, '2026-08-31 20:00:00'),
(3, 3.60, '2026-09-01 08:00:00'),
(3, 4.40, '2026-09-01 20:00:00'),

-- Câmara frigorífica 4 - faixa: 2°C a 6°C
(4, 3.90, '2026-08-30 08:00:00'),
(4, 4.10, '2026-08-30 20:00:00'),
(4, 4.40, '2026-08-31 08:00:00'),
(4, 3.60, '2026-08-31 20:00:00'),
(4, 4.00, '2026-09-01 08:00:00'),
(4, 4.30, '2026-09-01 20:00:00'),

-- Câmara frigorífica 5 - faixa: 2°C a 6°C
(5, 4.00, '2026-08-30 08:00:00'),
(5, 4.30, '2026-08-30 20:00:00'),
(5, 3.70, '2026-08-31 08:00:00'),
(5, 4.20, '2026-08-31 20:00:00'),
(5, 3.90, '2026-09-01 08:00:00'),
(5, 4.10, '2026-09-01 20:00:00'),

-- Câmara frigorífica 6 - faixa: 2°C a 6°C
(6, 3.80, '2026-08-30 08:00:00'),
(6, 4.10, '2026-08-30 20:00:00'),
(6, 4.50, '2026-08-31 08:00:00'),
(6, 3.90, '2026-08-31 20:00:00'),
(6, 4.20, '2026-09-01 08:00:00'),
(6, 3.70, '2026-09-01 20:00:00'),

-- Câmara frigorífica 7 - faixa: -2°C a 2°C
(7, 0.00, '2026-08-30 08:00:00'),
(7, -0.50, '2026-08-30 20:00:00'),
(7, 0.50, '2026-08-31 08:00:00'),
(7, -1.00, '2026-08-31 20:00:00'),
(7, 0.20, '2026-09-01 08:00:00'),
(7, -0.30, '2026-09-01 20:00:00'),

-- Câmara frigorífica 8 - faixa: -2°C a 2°C
(8, 0.50, '2026-08-30 08:00:00'),
(8, -0.20, '2026-08-30 20:00:00'),
(8, 0.80, '2026-08-31 08:00:00'),
(8, -0.70, '2026-08-31 20:00:00'),
(8, 0.30, '2026-09-01 08:00:00'),
(8, -0.40, '2026-09-01 20:00:00'),

-- Câmara frigorífica 9 - faixa: -2°C a 2°C
(9, -0.50, '2026-08-30 08:00:00'),
(9, 0.00, '2026-08-30 20:00:00'),
(9, 0.70, '2026-08-31 08:00:00'),
(9, -0.30, '2026-08-31 20:00:00'),
(9, 0.40, '2026-09-01 08:00:00'),
(9, -0.80, '2026-09-01 20:00:00'),

-- Câmara frigorífica 10 - faixa: -22°C a -16°C
(10, -18.00, '2026-08-30 08:00:00'),
(10, -19.00, '2026-08-30 20:00:00'),
(10, -17.50, '2026-08-31 08:00:00'),
(10, -18.50, '2026-08-31 20:00:00'),
(10, -20.00, '2026-09-01 08:00:00'),
(10, -17.00, '2026-09-01 20:00:00'),

-- Câmara frigorífica 11 - faixa: -22°C a -16°C
(11, -18.50, '2026-08-30 08:00:00'),
(11, -19.50, '2026-08-30 20:00:00'),
(11, -17.00, '2026-08-31 08:00:00'),
(11, -18.00, '2026-08-31 20:00:00'),
(11, -20.50, '2026-09-01 08:00:00'),
(11, -17.50, '2026-09-01 20:00:00'),

-- Câmara frigorífica 12 - faixa: -22°C a -16°C
(12, -19.00, '2026-08-30 08:00:00'),
(12, -18.00, '2026-08-30 20:00:00'),
(12, -17.50, '2026-08-31 08:00:00'),
(12, -20.00, '2026-08-31 20:00:00'),
(12, -18.50, '2026-09-01 08:00:00'),
(12, -17.00, '2026-09-01 20:00:00');

-- 9.2 Leituras fora da faixa (geram alerta via trigger, um exemplo por gravidade)
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
-- Câmara frigorífica 1 | Ideal: 4°C | Diferença: 0,80°C | Gravidade Estável
(1, 4.80, '2026-09-02 08:00:00'),

-- Câmara frigorífica 2 | Ideal: 4°C | Diferença: 2,80°C | Gravidade Atenção
(2, 6.80, '2026-09-02 08:30:00'),

-- Câmara frigorífica 7 | Ideal: 0°C | Diferença: 5°C | Gravidade Crítica
(7, 5.00, '2026-09-02 09:00:00'),

-- Câmara frigorífica 10 | Ideal: -18°C | Diferença: 10°C | Gravidade Urgente
(10, -8.00, '2026-09-02 09:30:00');

-- 9.3 Histórico adicional (mais dias de leituras normais, dentro da faixa de cada câmara frigorífica)
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
FROM tb_camara_frigorifica r,
     generate_series(0, 29) AS gs;


-- =============================================
-- 10. FLUXO DE ATENDIMENTO (exemplo sobre os alertas gerados na seção 9.2)
-- =============================================

-- Leitura normal após o alerta da câmara frigorífica 1.
-- Permite que a justificativa seguinte encerre o atendimento e o alerta.
INSERT INTO tb_leitura_temperatura
    (cod_termometro, temperatura, data_hora)
VALUES
(1, 4.20, '2026-09-02 09:00:00');
 
-- Reconhece e resolve o alerta de gravidade "estável" (câmara frigorífica 1)
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_camara_frigorifica = 1
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_reconhecer_alerta(v_cod_alerta, 62);
END $$;
 
INSERT INTO tb_justificativa (
    cod_atendimento, motivo, descricao
)
VALUES (
    (SELECT a.id
     FROM tb_atendimento a
     JOIN tb_alerta al ON al.id = a.cod_alerta
     WHERE al.cod_camara_frigorifica = 1
     ORDER BY a.id DESC LIMIT 1),
    'Porta aberta para reposição',
    'Alerta gerado durante reposição manual de estoque; temperatura normalizada após fechamento da câmara.'
);
 
-- Reconhece o alerta crítico do câmara frigorífica 10, sem resolver
DO $$
DECLARE
    v_cod_alerta INTEGER;
BEGIN
    SELECT id
    INTO v_cod_alerta
    FROM tb_alerta
    WHERE cod_camara_frigorifica = 10
    ORDER BY id DESC
    LIMIT 1;

    CALL sp_reconhecer_alerta(v_cod_alerta, 42);
END $$;


-- =============================================
-- 11. RELATÓRIOS
-- =============================================
INSERT INTO tb_relatorio (
    cod_usuario_gerador, hash_conteudo, periodo_inicio, periodo_fim, status
)
VALUES
(2, 'a1b2c3d4e5f67890123456789012345678901234567890123456789012345678', '2026-08-01', '2026-08-31', 'gerado'),
(3, 'b2c3d4e5f678901234567890123456789012345678901234567890123456789', '2026-08-01', '2026-08-31', 'assinado'),
(4, 'c3d4e5f6789012345678901234567890123456789012345678901234567890', '2026-07-01', '2026-07-31', 'arquivado');


-- =============================================
-- 12. ASSINATURAS
-- =============================================
INSERT INTO tb_assinatura (
    cod_relatorio, certificado_titular, numero_serie, 
    autoridade_certificadora, algoritmo_assinatura,
    assinatura, carimbo_tempo
)
VALUES
(2, 'Sistema ColdChain', 'CERT-2026-0001', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_2', '2026-09-02 10:00:00'),
(3, 'Sistema ColdChain', 'CERT-2026-0002', 'ICP-Brasil', 'SHA256withRSA', 'assinatura_simulada_relatorio_3', '2026-09-02 10:05:00');


-- =============================================
-- 13. LOG DE ACESSO A RELATÓRIOS
-- =============================================
INSERT INTO tb_log_acesso_relatorio (
    cod_relatorio, cod_usuario, acao
)
VALUES
    (1, 32, 'visualizou'),
    (1, 33, 'baixou'),
    (2, 33, 'visualizou'),
    (3, 52, 'baixou');


-- Simulando escalonamento para gerar um log em tb_log_escalonamento
UPDATE tb_alerta
SET nivel_atual = 'gestor'
WHERE id = (
    SELECT id
    FROM tb_alerta
    WHERE nivel_gravidade = 'urgente'
    ORDER BY id DESC
    LIMIT 1
);


-- =============================================
-- 14. LOG DE SENSORES
-- =============================================
INSERT INTO tb_log_sensor (
    cod_termometro, tipo_evento, detalhes
)
VALUES
(1, 'manutencao', 'Sensor calibrado'),
(2, 'falha', 'Leitura fora do comportamento esperado'),
(7, 'manutencao', 'Sensor verificado'),
(10, 'bateria', 'Bateria do sensor substituída');


-- =============================================
-- 15. LOG DE ACESSO
-- =============================================
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
